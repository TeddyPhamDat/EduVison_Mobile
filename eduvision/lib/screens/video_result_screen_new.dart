// video_result_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/lecture_video.dart';
import '../services/video_service.dart';
import '../services/fcm_service.dart';
import '../services/api_video_service.dart';
import '../utils/video_notification_helper.dart';

class VideoResultScreen extends StatefulWidget {
  final String videoId;
  final int? remoteId; // ID for remote video from API

  const VideoResultScreen({
    Key? key, 
    required this.videoId, 
    this.remoteId,
  }) : super(key: key);

  @override
  State<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends State<VideoResultScreen>
    with SingleTickerProviderStateMixin {
  final VideoService _videoService = VideoService();
  final FCMService _fcmService = FCMService();
  final ApiVideoService _apiVideoService = ApiVideoService();
  
  late Future<LectureVideo> _videoFuture;
  late AnimationController _animationController;
  
  // Video data from notifications
  String? _remoteVideoUrl;
  bool _checkingForNotifications = true;
  
  // Lists for dropdown options
  final List<String> _subjects = [
    'Toán học', 'Vật lý', 'Hóa học', 'Sinh học', 
    'Ngữ văn', 'Lịch sử', 'Địa lý', 'Tiếng Anh', 'GDCD', 'Tin học',
  ];
  
  // Danh sách chương theo môn học
  final Map<String, List<String>> _chaptersBySubject = {
    'Toán học': ['Đại số', 'Hình học', 'Giải tích', 'Số học', 'Xác suất thống kê'],
    'Vật lý': ['Cơ học', 'Nhiệt học', 'Điện học', 'Quang học', 'Vật lý nguyên tử'],
    'Hóa học': ['Hóa vô cơ', 'Hóa hữu cơ', 'Hóa phân tích', 'Hóa đại cương'],
    'Sinh học': ['Sinh học tế bào', 'Di truyền học', 'Sinh thái học', 'Sinh lý học'],
    'GDCD': ['Pháp luật', 'Đạo đức', 'Quyền công dân', 'Xã hội'],
    'Lịch sử': ['Lịch sử Việt Nam', 'Lịch sử thế giới', 'Cách mạng', 'Văn minh'],
  };
  
  final List<String> _grades = [
    'Lớp 1', 'Lớp 2', 'Lớp 3', 'Lớp 4', 'Lớp 5',
    'Lớp 6', 'Lớp 7', 'Lớp 8', 'Lớp 9',
    'Lớp 10', 'Lớp 11', 'Lớp 12'
  ];
  
  final List<String> _imageCategories = [
    'Chân dung', 'Phong cảnh', 'Khoa học', 'Trừu tượng', 'Giáo dục'
  ];
  
  final List<String> _templates = [
    'Mẫu 1', 'Mẫu 2', 'Mẫu 3'
  ];
  
  // Video creation form controllers
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();
  
  // Selected values for dropdowns
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedGrade;
  String? _selectedImageCategory;
  String? _selectedTemplate;
  
  // Form visibility
  bool _showVideoRequestForm = false;
  
  @override
  void initState() {
    super.initState();
    _videoFuture = _processVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.repeat(reverse: true);
    
    // Setup FCM for remote video
    if (widget.remoteId != null) {
      _checkingForNotifications = true;
      
      // Setup video notification helper
      VideoNotificationHelper.setupVideoResultScreen(
        context: context,
        fcmService: _fcmService,
        onVideoReady: (videoUrl) {
          setState(() {
            _remoteVideoUrl = videoUrl;
            _checkingForNotifications = false;
          });
        },
      );
    } else {
      _checkingForNotifications = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fcmService.onVideoGenerated = null;
    // Dispose the text controllers
    _subjectController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  Future<LectureVideo> _processVideo() async {
    return await _videoService.processVideo(widget.videoId);
  }
  
  // Gets the available chapters based on selected subject
  List<String> get _availableChapters {
    if (_selectedSubject == null) return [];
    return _chaptersBySubject[_selectedSubject] ?? [];
  }
  
  // Toggle request form visibility
  void _toggleVideoRequestForm() {
    setState(() {
      _showVideoRequestForm = !_showVideoRequestForm;
    });
  }
  
  // Create a new video request
  Future<void> _createVideoRequest() async {
    if (_validateForm()) {
      try {
        // Show loading indicator
        setState(() {
          _checkingForNotifications = true;
        });
        
        // Parse grade number (remove "Lớp " prefix)
        final int grade = int.tryParse(_selectedGrade?.replaceAll('Lớp ', '') ?? '12') ?? 12;
        
        // Parse template number
        final int template = int.tryParse(_selectedTemplate?.replaceAll('Mẫu ', '') ?? '1') ?? 1;
        
        // Make the API call
        final result = await _apiVideoService.createVideo(
          subject: _selectedSubject!,
          chapter: _selectedChapter!,
          grade: grade,
          imageCategory: _selectedImageCategory ?? 'Giáo dục',
          template: template,
        );
        
        // Get the generateVideoId from the API response
        final int? generatedVideoId = result['generateVideoId'] as int?;
        
        if (generatedVideoId != null) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yêu cầu tạo video đã được gửi. ID: $generatedVideoId'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Setup FCM to receive the notification
          VideoNotificationHelper.setupVideoResultScreen(
            context: context,
            fcmService: _fcmService,
            onVideoReady: (videoUrl) {
              setState(() {
                _remoteVideoUrl = videoUrl;
                _checkingForNotifications = false;
              });
            },
          );
          
          // Hide the form
          setState(() {
            _showVideoRequestForm = false;
          });
        }
      } catch (e) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _checkingForNotifications = false;
        });
      }
    }
  }
  
  // Validate form fields
  bool _validateForm() {
    if (_selectedSubject == null) {
      _showError('Vui lòng chọn môn học');
      return false;
    }
    
    if (_selectedChapter == null) {
      _showError('Vui lòng chọn chương');
      return false;
    }
    
    return true;
  }
  
  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Kết quả video",
          style: TextStyle(
            fontFamily: ".SF Pro Display",
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: _remoteVideoUrl != null
            ? Icon(
                CupertinoIcons.cloud_download,
                color: CupertinoColors.activeBlue,
              )
            : _checkingForNotifications
                ? CupertinoActivityIndicator()
                : null,
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
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
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
                        const CupertinoActivityIndicator(radius: 20),
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
    // Check if we have a remote URL from FCM notifications
    final hasRemoteUrl = _remoteVideoUrl != null;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification status indicator if waiting for remote video
            if (_checkingForNotifications)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đang chờ thông báo từ máy chủ...',
                        style: TextStyle(
                          color: CupertinoColors.systemBlue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Video preview container with animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutQuart,
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
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Main content
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Show remote or local video icon
                                if (hasRemoteUrl || video.videoUrl != null)
                                  Icon(
                                    hasRemoteUrl 
                                        ? CupertinoIcons.cloud_download
                                        : CupertinoIcons.play_circle_fill,
                                    size: 64,
                                    color: CupertinoColors.activeBlue.withOpacity(value),
                                  ),
                                if ((hasRemoteUrl || video.videoUrl != null) && video.slideUrl != null)
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
                          
                          // Remote video badge
                          if (hasRemoteUrl)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.cloud, color: CupertinoColors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Trực tuyến',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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

            // Create new video request button and form
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _toggleVideoRequestForm,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_showVideoRequestForm ? CupertinoIcons.xmark : CupertinoIcons.add),
                        SizedBox(width: 6),
                        Text(
                          _showVideoRequestForm ? "Hủy" : "Tạo video mới",
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
            
            // Video request form
            if (_showVideoRequestForm) _buildVideoRequestForm(),

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

            // Display slides if available - will be implemented later
            // if (video.slides != null && video.slides!.isNotEmpty)
            //   SlidesPreviewSection(video: video),
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
            child: Text(text, style: style),
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
            child: _buildInfoRow(title: title, value: value, icon: icon),
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
          Icon(icon, size: 20, color: CupertinoColors.activeBlue),
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
  
  // Build the video request form
  Widget _buildVideoRequestForm() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form title
          Text(
            'Tạo video mới',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: ".SF Pro Display",
            ),
          ),
          SizedBox(height: 16),
          
          // Subject dropdown
          Text(
            'Môn học',
            style: TextStyle(
              fontFamily: ".SF Pro Text",
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text('Chọn môn học'),
              items: _subjects.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSubject = newValue;
                  _selectedChapter = null; // Reset chapter when subject changes
                });
              },
            ),
          ),
          SizedBox(height: 16),
          
          // Chapter dropdown
          Text(
            'Chương',
            style: TextStyle(
              fontFamily: ".SF Pro Text",
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: DropdownButton<String>(
              value: _selectedChapter,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text(_selectedSubject == null ? 'Chọn môn học trước' : 'Chọn chương'),
              items: _availableChapters.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: _selectedSubject == null ? null : (newValue) {
                setState(() {
                  _selectedChapter = newValue;
                });
              },
            ),
          ),
          SizedBox(height: 16),
          

          
          // Grade dropdown
          Text(
            'Lớp',
            style: TextStyle(
              fontFamily: ".SF Pro Text",
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: DropdownButton<String>(
              value: _selectedGrade,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text('Chọn lớp'),
              items: _grades.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedGrade = newValue;
                });
              },
            ),
          ),
          SizedBox(height: 16),
          
          // Image category dropdown
          Text(
            'Thể loại hình ảnh',
            style: TextStyle(
              fontFamily: ".SF Pro Text",
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: DropdownButton<String>(
              value: _selectedImageCategory,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text('Chọn thể loại hình ảnh'),
              items: _imageCategories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedImageCategory = newValue;
                });
              },
            ),
          ),
          SizedBox(height: 16),
          
          // Template dropdown
          Text(
            'Mẫu thiết kế',
            style: TextStyle(
              fontFamily: ".SF Pro Text",
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            child: DropdownButton<String>(
              value: _selectedTemplate,
              isExpanded: true,
              underline: SizedBox(),
              hint: Text('Chọn mẫu thiết kế'),
              items: _templates.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTemplate = newValue;
                });
              },
            ),
          ),
          SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.activeBlue,
              onPressed: _createVideoRequest,
              child: Text(
                'Gửi yêu cầu tạo video',
                style: TextStyle(
                  fontFamily: ".SF Pro Text",
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
