#include <flutter/runtime_effect.glsl>

// Uniforms - float uniforms
uniform vec2 uSize;          // Widget size in pixels
uniform vec2 uCurlPos;       // Current curl axis position (normalized 0-1)
uniform vec2 uCurlDir;       // Curl direction vector (normalized)
uniform float uRadius;       // Cylinder radius (normalized, default ~0.08)
uniform float uShadowWidth;  // Shadow width multiplier (default 0.15)
uniform float uBackOpacity;  // Back page darkening factor (0-1, 0=no darkening)
uniform float uReverse;      // 1.0 = reverse (previous page), 0.0 = forward (next page)

// Texture samplers
uniform sampler2D uCurrentPage;  // Current page texture
uniform sampler2D uNextPage;     // Next page texture (or previous when reverse)

out vec4 fragColor;

const float M_PI = 3.14159265359;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;

    // Flip UV.x when in reverse mode so the math works symmetrically
    if (uReverse > 0.5) {
        uv.x = 1.0 - uv.x;
    }

    // Direction from curl axis
    vec2 dir = normalize(uCurlDir);
    // Mirror direction along X in reverse mode (matching UV and curlPos mirroring)
    if (uReverse > 0.5) {
        dir.x = -dir.x;
    }

    // Compute curl axis position along the direction vector
    // origin = intersection of direction ray from curlPos with the left edge
    vec2 curlPos = uCurlPos;
    if (uReverse > 0.5) {
        curlPos.x = 1.0 - curlPos.x;
    }

    vec2 origin;
    if (abs(dir.x) > 0.001) {
        origin = curlPos - dir * (curlPos.x / dir.x);
    } else {
        origin = vec2(0.0, curlPos.y);
    }
    origin = clamp(origin, 0.0, 1.0);

    // Distance of fragment from curl axis
    vec2 fragVec = uv - origin;
    float fragDist = dot(fragVec, dir);

    // Distance of curl axis from origin
    vec2 curlVec = curlPos - origin;
    float curlDist = dot(curlVec, dir);

    // d = distance of fragment from the curl axis
    float d = fragDist - curlDist;
    float r = uRadius;

    // Point on curl axis line perpendicular to fragment
    vec2 linePoint = uv - d * dir;

    vec4 color;
    float shadowFactor = 1.0;

    if (d > r) {
        // ============================================
        // Scenario 1: Fragment is ahead of curl, beyond radius
        // Show the NEXT page (no deformation)
        // ============================================
        vec2 sampleUV = uv;
        if (uReverse > 0.5) {
            sampleUV.x = 1.0 - sampleUV.x;
        }
        color = texture(uNextPage, sampleUV);

        // Shadow near the curl edge
        float shadowDist = d - r;
        if (shadowDist < uShadowWidth * r * 4.0) {
            shadowFactor = mix(0.7, 1.0, clamp(shadowDist / (uShadowWidth * r * 4.0), 0.0, 1.0));
        }
    } else if (d > 0.0 && r > 0.0) {
        // ============================================
        // Scenario 2: Fragment is on the curl cylinder
        // ============================================
        float theta = asin(clamp(d / r, -1.0, 1.0));

        // p1 = front of current page (arc distance from curl axis)
        float d1 = theta * r;
        vec2 p1 = linePoint + dir * d1;

        // p2 = back of current page (wrapping around cylinder)
        float d2 = (M_PI - theta) * r;
        vec2 p2 = linePoint + dir * d2;

        // Un-reverse for texture sampling
        vec2 p1Sample = p1;
        vec2 p2Sample = p2;
        if (uReverse > 0.5) {
            p1Sample.x = 1.0 - p1Sample.x;
            p2Sample.x = 1.0 - p2Sample.x;
        }

        // Check if p2 (back side) is within page bounds
        if (p2.x >= 0.0 && p2.x <= 1.0 && p2.y >= 0.0 && p2.y <= 1.0) {
            // Show back of current page
            color = texture(uCurrentPage, p2Sample);
            // Darken back side + apply greying effect
            float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            color.rgb = mix(color.rgb, vec3(grey), uBackOpacity * 0.3);
            color.rgb *= mix(0.6, 0.85, uBackOpacity);

            // Shadow on cylinder surface
            shadowFactor = mix(0.75, 1.0, clamp(theta / (M_PI * 0.5), 0.0, 1.0));
        } else if (p1.x >= 0.0 && p1.x <= 1.0 && p1.y >= 0.0 && p1.y <= 1.0) {
            // Show front of current page
            color = texture(uCurrentPage, p1Sample);

            // Highlight on convex cylinder surface
            shadowFactor = mix(0.9, 1.0, clamp(theta / (M_PI * 0.5), 0.0, 1.0));
        } else {
            // Neither p1 nor p2 in bounds → show next page
            vec2 sampleUV = uv;
            if (uReverse > 0.5) {
                sampleUV.x = 1.0 - sampleUV.x;
            }
            color = texture(uNextPage, sampleUV);
            float shadowDist = r - d;
            shadowFactor = mix(0.7, 1.0, clamp(shadowDist / (uShadowWidth * r * 4.0), 0.0, 1.0));
        }
    } else {
        // ============================================
        // Scenario 3: Fragment is behind the curl axis
        // Could be back of curled page overlapping, or flat current page
        // ============================================

        if (r > 0.0) {
            // Unroll: distance along the circumference from curl axis
            float unrollDist = M_PI * r - d; // d is negative here, so this > pi*r
            vec2 p = linePoint + dir * unrollDist;

            vec2 pSample = p;
            if (uReverse > 0.5) {
                pSample.x = 1.0 - pSample.x;
            }

            if (p.x >= 0.0 && p.x <= 1.0 && p.y >= 0.0 && p.y <= 1.0) {
                // Back of page visible behind curl axis
                color = texture(uCurrentPage, pSample);
                float grey = dot(color.rgb, vec3(0.299, 0.587, 0.114));
                color.rgb = mix(color.rgb, vec3(grey), uBackOpacity * 0.3);
                color.rgb *= mix(0.6, 0.85, uBackOpacity);

                // Shadow fades from curl axis
                shadowFactor = mix(0.65, 1.0, clamp(-d / (r * 2.0), 0.0, 1.0));
            } else {
                // Show current page flat
                vec2 sampleUV = uv;
                if (uReverse > 0.5) {
                    sampleUV.x = 1.0 - sampleUV.x;
                }
                color = texture(uCurrentPage, sampleUV);
            }
        } else {
            // No radius, just show current page
            vec2 sampleUV = uv;
            if (uReverse > 0.5) {
                sampleUV.x = 1.0 - sampleUV.x;
            }
            color = texture(uCurrentPage, sampleUV);
        }
    }

    // Apply shadow
    color.rgb *= shadowFactor;

    fragColor = color;
}
