// filepath: d:\2025\EduVision-MO\eduvision\lib\screens\video_result_screen.dart
import 'package:flutter/cupertino.dart';
import '../models/lecture_video.dart';
import '../services/video_service.dart';
import '../widgets/slides_preview_section.dart';

class VideoResultScreen extends StatefulWidget {
  final String videoId;
  
  const VideoResultScreen({
    Key? key, 
    required this.videoId,
  }) : super(key: key);

  @override
  State<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends State<VideoResultScreen> with SingleTickerProviderStateMixin {
  final VideoService _videoService = VideoService();
  late Future<LectureVideo> _videoFuture;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _videoFuture = _processVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<LectureVideo> _processVideo() async {
    return await _videoService.processVideo(widget.videoId);
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          "Kết quả video",
          style: TextStyle(
            fontFamily: ".SF Pro Display",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<LectureVideo>(
          future: _videoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (snapshot.hasData) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildSuccessState(snapshot.data!),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
              );
            } else {
              return _buildErrorState("Không có dữ liệu");
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // iOS-style animated loading indicator
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, double value, child) {
              return Column(
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // iOS-style loading indicator
                        const CupertinoActivityIndicator(
                          radius: 20,
                        ),
                        // iOS-style icon
                        Icon(
                          CupertinoIcons.videocam_fill,
                          size: 40,
                          color: CupertinoColors.activeBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            onEnd: () {
              // Restart the animation when it completes
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          const Text(
            "Đang xử lý video...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
              fontFamily: ".SF Pro Text",
            ),
          ),
          const SizedBox(height: 8),
          // iOS-style animated dots for "Processing" text
          TweenAnimationBuilder(
            tween: Tween<int>(begin: 0, end: 3),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, int value, child) {
              return Text(
                "Vui lòng đợi trong giây lát${"." * (value % 4)}",
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                  fontFamily: ".SF Pro Text",
                ),
              );
            },
            onEnd: () {
              // Restart the animation when it completes
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: CupertinoColors.systemRed,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            "Có lỗi xảy ra",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: ".SF Pro Display",
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: ".SF Pro Text",
              color: CupertinoColors.systemRed,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () {
              setState(() {
                _videoFuture = _processVideo();
              });
            },
            child: const Text(
              "Thử lại",
              style: TextStyle(
                fontFamily: ".SF Pro Text",
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(LectureVideo video) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video preview container with animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutQuart, // iOS-style animation curve
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.08 * value),
                            blurRadius: 10 * value,
                            offset: Offset(0, 4 * value),
                          )
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (video.videoUrl != null)
                              Icon(
                                CupertinoIcons.play_circle_fill,
                                size: 64,
                                color: CupertinoColors.activeBlue.withOpacity(value),
                              ),
                            if (video.videoUrl != null && video.slideUrl != null)
                              const SizedBox(width: 32),
                            if (video.slideUrl != null)
                              Icon(
                                CupertinoIcons.rectangle_fill_on_rectangle_fill,
                                size: 64,
                                color: CupertinoColors.systemBlue.withOpacity(value),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Video details with sequential animations - iOS style
            _buildAnimatedText(
              text: video.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: ".SF Pro Display",
                color: CupertinoColors.black,
              ),
              delay: 300,
            ),
            const SizedBox(height: 16),
            
            // Video metadata with staggered animations
            _buildAnimatedInfoRow(
              title: "Khóa học:",
              value: video.subject,
              icon: CupertinoIcons.book_fill,
              delay: 500,
            ),
            
            _buildAnimatedInfoRow(
              title: "Chương:",
              value: video.chapter,
              icon: CupertinoIcons.bookmark_fill,
              delay: 700,
            ),
            
            _buildAnimatedInfoRow(
              title: "Kiến thức:",
              value: video.topic,
              icon: CupertinoIcons.lightbulb_fill,
              delay: 900,
            ),
            
            if (video.grade != null)
              _buildAnimatedInfoRow(
                title: "Lớp học:",
                value: video.grade!,
                icon: CupertinoIcons.building_2_fill,
                delay: 1100,
              ),
              
            if (video.imageCategory != null)
              _buildAnimatedInfoRow(
                title: "Thể loại hình ảnh:",
                value: video.imageCategory!,
                icon: CupertinoIcons.photo_fill,
                delay: 1300,
              ),
              
            if (video.template != null)
              _buildAnimatedInfoRow(
                title: "Mẫu:",
                value: video.template!,
                icon: CupertinoIcons.square_grid_2x2_fill,
                delay: 1500,
              ),
              
            if (video.mode != null)
              _buildAnimatedInfoRow(
                title: "Chế độ:",
                value: video.mode!,
                icon: CupertinoIcons.settings_solid,
                delay: 1700,
              ),
            
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 20),
              color: CupertinoColors.systemGrey5,
            ),
            
            // Action buttons with animation - iOS style
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Row(
                children: [
                  if (video.videoUrl != null)
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          // Tải xuống video
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.arrow_down_circle),
                            SizedBox(width: 6),
                            Text(
                              "Tải video",
                              style: TextStyle(
                                fontFamily: ".SF Pro Text",
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (video.videoUrl != null && video.slideUrl != null)
                    const SizedBox(width: 16),
                  if (video.slideUrl != null)
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          // Tải xuống slide
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(CupertinoIcons.arrow_down_circle),
                            SizedBox(width: 6),
                            Text(
                              "Tải slide",
                              style: TextStyle(
                                fontFamily: ".SF Pro Text",
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: () {
                      // Tạo video mới
                      Navigator.pop(context);
                    },
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(CupertinoIcons.add),
                        SizedBox(width: 6),
                        Text(
                          "Tạo mới",
                          style: TextStyle(
                            fontFamily: ".SF Pro Text",
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: () {
                    // Chia sẻ video
                  },
                  color: CupertinoColors.systemGrey6,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(CupertinoIcons.share),
                      SizedBox(width: 6),
                      Text(
                        "Chia sẻ",
                        style: TextStyle(
                          fontFamily: ".SF Pro Text",
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Display slides if available
            if (video.slides != null && video.slides!.isNotEmpty)
              SlidesPreviewSection(video: video),
          ],
        ),
      ),
    );
  }

  // Helper method for text with iOS-style animation
  Widget _buildAnimatedText({
    required String text,
    required TextStyle style,
    required int delay,
  }) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            offset: snapshot.connectionState == ConnectionState.done 
                ? Offset.zero
                : const Offset(0.03, 0),
            child: Text(
              text,
              style: style,
            ),
          ),
        );
      },
    );
  }

  // Helper method for info row with iOS-style animation
  Widget _buildAnimatedInfoRow({
    required String title,
    required String value,
    required IconData icon,
    required int delay,
  }) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            offset: snapshot.connectionState == ConnectionState.done 
                ? Offset.zero
                : const Offset(0.05, 0),
            child: _buildInfoRow(
              title: title,
              value: value,
              icon: icon,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w600,
              fontFamily: ".SF Pro Text",
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.black,
                fontFamily: ".SF Pro Text",
              ),
            ),
          ),
        ],
      ),
    );
  }
}
