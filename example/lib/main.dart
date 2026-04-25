import 'package:flutter/material.dart';
import 'package:flutter_page_curl/flutter_page_curl.dart';

void main() {
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Page Curl Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const BookScreen(),
    );
  }
}

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _controller = PageCurlController();

  // Book content — The Little Prince (excerpt, Vietnamese)
  static const _bookTitle = 'Hoàng Tử Bé';
  static const _bookAuthor = 'Antoine de Saint-Exupéry';

  static const _chapters = [
    // Page 0: Cover
    null,
    // Page 1
    _ChapterContent(
      chapter: 'Chương I',
      text:
          'Ngày xưa, ở một hành tinh rất nhỏ, có một hoàng tử bé sống một mình. '
          'Hành tinh của cậu chỉ lớn hơn một ngôi nhà một chút, với ba ngọn núi lửa '
          'và một bông hoa hồng kiêu kỳ.\n\n'
          'Mỗi sáng, cậu dậy sớm để chăm sóc hành tinh của mình — nhổ những cây '
          'baobab nhỏ trước khi chúng kịp lớn, và tưới nước cho bông hồng yêu quý.\n\n'
          'Nhưng bông hồng thì luôn đòi hỏi và hay hờn dỗi. "Tôi cần một tấm bình phong '
          'che gió," cô ấy nói. "Và một chiếc lồng kính cho ban đêm."',
    ),
    // Page 2
    _ChapterContent(
      chapter: 'Chương II',
      text:
          'Một ngày nọ, hoàng tử bé quyết định rời hành tinh để khám phá vũ trụ. '
          'Cậu đi qua bảy hành tinh nhỏ, mỗi nơi có một người lớn kỳ lạ.\n\n'
          'Hành tinh đầu tiên có một vị vua ngồi trên ngai vàng, cai trị một vương quốc '
          'trống rỗng. "Ta cai trị mọi thứ," nhà vua tuyên bố trang trọng.\n\n'
          '"Cả các vì sao nữa ạ?" hoàng tử bé hỏi.\n\n'
          '"Cả các vì sao nữa," nhà vua đáp. "Nhưng ta ra lệnh cho chúng '
          'theo đúng lịch trình của chúng. Đó là sự khôn ngoan."',
    ),
    // Page 3
    _ChapterContent(
      chapter: 'Chương III',
      text:
          'Cuối cùng hoàng tử bé đến Trái Đất — hành tinh thứ bảy. Cậu hạ cánh '
          'giữa sa mạc Sahara mênh mông, nơi cát vàng trải dài đến tận chân trời.\n\n'
          '"Kỳ lạ thật," cậu tự nhủ. "Không có ai ở đây cả."\n\n'
          'Rồi một con rắn vàng xuất hiện. "Đây là sa mạc," con rắn nói. '
          '"Trong sa mạc thì không có người. Trái Đất rộng lắm."\n\n'
          'Hoàng tử bé ngồi trên một tảng đá và ngước nhìn bầu trời đầy sao, '
          'tự hỏi liệu bông hồng của cậu có đang nhớ cậu không.',
    ),
    // Page 4
    _ChapterContent(
      chapter: 'Chương IV',
      text: 'Trong chuyến phiêu lưu, hoàng tử bé gặp một con cáo trên đồng cỏ. '
          'Con cáo dạy cậu bài học quan trọng nhất.\n\n'
          '"Mình không thể chơi với bạn được," con cáo nói. "Mình chưa được '
          'thuần hóa."\n\n'
          '"Thuần hóa nghĩa là gì?"\n\n'
          '"Nghĩa là tạo ra những sợi dây ràng buộc. Hiện tại, bạn chỉ là một '
          'cậu bé giống như trăm nghìn cậu bé khác. Nhưng nếu bạn thuần hóa '
          'mình, chúng ta sẽ cần nhau. Bạn sẽ là duy nhất trên đời đối với mình."',
    ),
    // Page 5
    _ChapterContent(
      chapter: 'Chương V',
      text: 'Khi đến lúc chia tay, con cáo nói với hoàng tử bé một bí mật:\n\n'
          '"Đây là bí mật của mình: người ta chỉ nhìn rõ bằng trái tim. '
          'Điều cốt yếu thì vô hình trước mắt thường."\n\n'
          'Hoàng tử bé nhắc lại để ghi nhớ: "Điều cốt yếu thì vô hình '
          'trước mắt thường..."\n\n'
          '"Chính thời gian mà bạn đã dành cho bông hồng khiến bông hồng '
          'trở nên quan trọng."\n\n'
          '"Chính thời gian mà mình đã dành..." hoàng tử bé nhắc lại '
          'để không bao giờ quên.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723),
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(4, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: PageCurlView(
                  controller: _controller,
                  radius: 0.06,
                  shadowWidth: 0.12,
                  backOpacity: 0.6,
                  edgeZoneWidth: 0.3,
                  onPageChanged: (page) => setState(() {}),
                  children: [
                    _buildCover(),
                    ..._chapters
                        .skip(1)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => _buildBookPage(
                              e.value!,
                              pageNumber: e.key + 1,
                              totalPages: _chapters.length - 1,
                            )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Book cover
  Widget _buildCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B3A4B), Color(0xFF0D1B2A)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative stars
          ...List.generate(20, (i) {
            final x = (i * 37 % 100) / 100.0;
            final y = (i * 53 % 100) / 100.0;
            final size = 1.0 + (i % 3);
            return Positioned(
              left: x * 300,
              top: y * 400,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          // Title
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Ornamental line
                  Container(
                    width: 60,
                    height: 2,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    _bookTitle,
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 40,
                    height: 1,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _bookAuthor,
                    style: TextStyle(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Instruction
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swipe_left_rounded,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vuốt để lật trang',
                          style: TextStyle(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.4),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Book page with text content
  Widget _buildBookPage(
    _ChapterContent content, {
    required int pageNumber,
    required int totalPages,
  }) {
    return Container(
      color: const Color(0xFFFAF0E6), // Antique paper
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  content.chapter,
                  style: const TextStyle(
                    color: Color(0xFF4E342E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 30,
                  height: 1,
                  color: const Color(0xFF5D4037).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Body text
          Expanded(
            child: Text(
              content.text,
              style: const TextStyle(
                color: Color(0xFF2E1A0E),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.8,
                letterSpacing: 0.2,
              ),
            ),
          ),

          // Page number
          Center(
            child: Text(
              '— $pageNumber —',
              style: TextStyle(
                color: const Color(0xFF5D4037).withValues(alpha: 0.5),
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterContent {
  const _ChapterContent({
    required this.chapter,
    required this.text,
  });

  final String chapter;
  final String text;
}
