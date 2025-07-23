import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:convert';
import '../services/gdcd_education_service.dart';
import '../services/education_service.dart';
import '../services/auth_service.dart';
import '../services/content_storage_service.dart';
import '../services/fcm_service.dart';
import '../services/api_video_service.dart';
import 'login_screen.dart';
import '../widgets/eduvision_header.dart';

import 'content_viewer_screen.dart';
import 'content_history_screen.dart';
import 'slide_list_screen.dart';
import 'api_video_list_screen.dart';

class ContentGenerationScreen extends StatefulWidget {
  final String? initialMode; // Có thể là 'video' hoặc 'slides'
  
  const ContentGenerationScreen({
    super.key,
    this.initialMode,
  });

  @override
  State<ContentGenerationScreen> createState() =>
      _ContentGenerationScreenState();
}

class _ContentGenerationScreenState extends State<ContentGenerationScreen> {
  final GDCDEducationService _educationService = GDCDEducationService();
  final EducationService _generalEducationService = EducationService();
  final AuthService _authService = AuthService();
  final ContentStorageService _contentStorageService = ContentStorageService();
  final FCMService _fcmService = FCMService();
  final ApiVideoService _apiVideoService = ApiVideoService();

  bool _isLoadingSubjects = true;
  bool _isLoadingChapters = false;
  bool _isGenerating = false;
  bool _slideCompleted = false; // Để track slide đã hoàn thành chưa
  bool _timeoutTriggered = false; // Internal state tracking
  
  Timer? _generationTimer; // Timer để tự động hiển thị thành công nếu không nhận FCM

  String? _errorMessage;
  String? _generationResult;
  // User selections
  String? _selectedSubject;
  String? _selectedChapter;
  int _selectedGrade = 12; // Default to grade 12
  String _selectedImageCategory = 'GDCD'; // Default to GDCD
  int _selectedTemplate = 1; // Default to template 1
  String _selectedMode =
      'video'; // Default to video since it gives both video and slides
  // Available options
  List<String> _availableSubjects = [];
  List<String> _availableChapters = [];

  final List<String> _availableGrades = [
    '12',
  ]; // Only grade 12 is available based on API
  final List<String> _availableTemplates = ['Mẫu 1', 'Mẫu 2', 'Mẫu 3', 'Mẫu 4'];

  @override
  void initState() {
    super.initState();
    
    // Set initial mode if provided
    if (widget.initialMode != null) {
      _selectedMode = widget.initialMode!;
    }
    
    _setupFCMHandlers();
    _setupAuthListener();
    _checkAuthAndLoadData();
  }

  @override
  void dispose() {
    // Cancel timer if it's active to prevent memory leaks
    if (_generationTimer != null) {
      _generationTimer!.cancel();
    }
    super.dispose();
  }

  void _setupAuthListener() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          // Refresh auth state when user changes
        });

        // If user just signed in, reload data
        if (user != null && _availableSubjects.isEmpty) {
          _checkAuthAndLoadData();
        }
      }
    });
  }

  void _setupFCMHandlers() {
    // Setup FCM handlers for this screen
    _fcmService.onMessageReceived = (message) {
      final data = message.data;
      final type = data['type'];

      if (type != null && type.startsWith('generation')) {
        // Handle generation-related notifications
        _handleGenerationNotification(data);
      }
    };

    // Setup FCM callbacks for browser notifications
    _fcmService.onSlideGenerated = (data) {
      // Cancel the timeout timer since we received an FCM
      _generationTimer?.cancel();
      
      if (mounted) {
        // Get slide URL if available
        String? slideUrl;
        if (data.containsKey('slideUrl') && data['slideUrl'] != null) {
          slideUrl = data['slideUrl'].toString();
          
          // Save to history if we have all required data
          if (_selectedSubject != null && _selectedChapter != null) {
            _contentStorageService.saveContent(
              subject: _selectedSubject!,
              chapter: _selectedChapter!,
              grade: _selectedGrade,
              contentType: 'slides',
              url: slideUrl,
            );
          }
        }
        
        // Show notification to user
        _showInfoMessage('📊 Slide đã được tạo thành công!');

        // Check if we're in video or slides mode
        final String? generatingMode = _selectedMode;
        if (generatingMode == 'slides') {
          // SLIDE-ONLY MODE: Stop loading and redirect
          setState(() {
            _isGenerating = false;
            _slideCompleted = false;
            _timeoutTriggered = false;
          });
          
          // Redirect to content history
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ContentHistoryScreen(),
                ),
              );
            }
          });
        } else {
          // VIDEO MODE: Keep loading, but mark slide as completed
          setState(() {
            _slideCompleted = true;
          });
        }
      }
    };

    _fcmService.onVideoGenerated = (data) {
      // Cancel the timeout timer since we received an FCM
      _generationTimer?.cancel();
      
      if (mounted) {
        // Get the video URL if available
        String? videoUrl;
        if (data.containsKey('videoUrl') && data['videoUrl'] != null) {
          videoUrl = data['videoUrl'].toString();
        }
        
        // Save to history if URL is available
        if (videoUrl != null && _selectedSubject != null && _selectedChapter != null) {
          _contentStorageService.saveContent(
            subject: _selectedSubject!,
            chapter: _selectedChapter!,
            grade: _selectedGrade,
            contentType: 'video',
            url: videoUrl,
          );
        }
        
        _showInfoMessage('🎥 Video đã được tạo thành công!');

        // VIDEO HOÀN THÀNH: Tắt loading và redirect
        setState(() {
          _isGenerating = false;
          _slideCompleted = false; // Reset state
          _timeoutTriggered = false; // Reset timeout flag
        });
        
        // Redirect to content history after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ContentHistoryScreen(),
              ),
            );
          }
        });
      }
    };

    _fcmService.onSlideAndVideoGenerated = (data) {
      // Cancel the timeout timer since we received an FCM
      _generationTimer?.cancel();
      
      if (mounted) {
        // Save both URLs to history if available
        if (_selectedSubject != null && _selectedChapter != null) {
          // Save slide URL
          if (data.containsKey('slideUrl') && data['slideUrl'] != null) {
            _contentStorageService.saveContent(
              subject: _selectedSubject!,
              chapter: _selectedChapter!,
              grade: _selectedGrade,
              contentType: 'slides',
              url: data['slideUrl'].toString(),
            );
          }
          
          // Save video URL
          if (data.containsKey('videoUrl') && data['videoUrl'] != null) {
            _contentStorageService.saveContent(
              subject: _selectedSubject!,
              chapter: _selectedChapter!,
              grade: _selectedGrade,
              contentType: 'video',
              url: data['videoUrl'].toString(),
            );
          }
        }
        
        // Show success message
        _showInfoMessage('🎉 Cả slide và video đã được tạo thành công!');

        // Complete the process and reset state
        setState(() {
          _isGenerating = false;
          _slideCompleted = false; 
          _timeoutTriggered = false;
        });
        
        // Redirect to content history
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ContentHistoryScreen(),
              ),
            );
          }
        });
      }
    };

    _fcmService.onGenerationFailed = (error, details) {
      // Cancel the timeout timer since we received an FCM
      _generationTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _timeoutTriggered = false;
        });
        _showInfoMessage('❌ Tạo nội dung thất bại: $error');
      }
    };

    _fcmService.onShowUINotification =
        (title, message, {bool isSuccess = true}) {
          if (mounted) {
            _showInfoMessage('$title: $message');
          }
        };
  }

  void _handleGenerationNotification(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'generation_started':
        // Could show a progress indicator or update UI
        if (mounted) {
          // Show a small feedback that generation started
          _showInfoMessage('Đang xử lý yêu cầu tạo nội dung...');
        }
        break;

      case 'slide_generated':
      case 'video_generated':
      case 'slide_and_video_generated':
        // Content generation completed
        if (mounted) {
          _showInfoMessage('Nội dung đã được tạo thành công!');
          // Could refresh the current state or show generated content
        }
        break;

      case 'generation_failed':
        // Generation failed
        if (mounted) {
          final error = data['error'] ?? 'Không xác định';
          _showInfoMessage('Tạo nội dung thất bại: $error');
        }
        break;
    }
  }

  void _showInfoMessage(String message, {bool showSlideListOption = false}) {
    // Show a brief message to user
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Thông báo'),
          content: Text(message),
          actions: [
            if (showSlideListOption)
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const SlideListScreen(),
                    ),
                  );
                },
                child: const Text('Xem danh sách slide'),
              ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkAuthAndLoadData() async {
    if (!_isUserAuthenticated()) {

      // Handle not signed in case
      setState(() {
        _isLoadingSubjects = false;
        _errorMessage = 'Bạn cần đăng nhập để sử dụng tính năng này.';
      });
      return;
    }
    
    // User is authenticated, load data
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoadingSubjects = true;
        _errorMessage = null;
      });

      final subjects = await _educationService.getSubjects();
      setState(() {
        _availableSubjects = subjects;
        if (subjects.isNotEmpty) {
          _selectedSubject = subjects[0]; // Select first subject by default
          _loadChapters(); // Load chapters for the selected subject
        }
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _loadChapters() async {
    if (_selectedSubject == null) return;

    try {
      setState(() {
        _isLoadingChapters = true;
        _errorMessage = null;
        _availableChapters = [];
      });

      final chapters = await _educationService.getChapters(
        subject: _selectedSubject!,
        grade: _selectedGrade,
      );

      setState(() {
        _availableChapters = chapters;
        if (chapters.isNotEmpty) {
          _selectedChapter = chapters[0]; // Select first chapter by default
        } else {
          _selectedChapter = null;
        }
        _isLoadingChapters = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingChapters = false;
      });
    }
  }

  Future<void> _generateContent() async {
    if (_selectedSubject == null || _selectedChapter == null) {
      _showErrorDialog('Vui lòng chọn môn học và bài học');
      return;
    }

    try {
      // Set initial state
      setState(() {
        _isGenerating = true;
        _slideCompleted = false; // Reset state khi bắt đầu
        _timeoutTriggered = false; // Reset timeout flag
        _errorMessage = null;
        _generationResult = null;
      });
      
      // Cancel any existing timer
      _generationTimer?.cancel();
      
      // Set a timer for 30 seconds as fallback in case FCM doesn't arrive
      _generationTimer = Timer(const Duration(seconds: 30), () {
        _handleGenerationTimeout();
      });

      // Send notification that content generation has started
      await _sendNotificationStarted();

      Map<String, dynamic> result;

      // Call appropriate API based on selected mode
      if (_selectedMode.toLowerCase() == 'slides') {
        // Call slides API endpoint
        result = await _generalEducationService.generateSlides(
          subject: _selectedSubject!,
          chapter: _selectedChapter!,
          grade: _selectedGrade,
          imageCategory: _selectedImageCategory,
          template: _selectedTemplate,
          mode: 'slides',
        );
      } else {
        // Call videos API endpoint using ApiVideoService instead
        result = await _apiVideoService.createVideo(
          subject: _selectedSubject!,
          chapter: _selectedChapter!,
          grade: _selectedGrade,
          imageCategory: _selectedImageCategory,
          template: _selectedTemplate,
        );
      }

      // ⚠️ KHÔNG TỰ ĐỘNG TẮT LOADING Ở ĐÂY!
      // Loading sẽ được tắt khi nhận FCM notification hoặc sau 30 giây

      setState(() {
        // Chỉ cập nhật result, không tắt _isGenerating
        // _isGenerating sẽ được tắt trong FCM callbacks

        if (_selectedMode.toLowerCase() == 'video') {
          // ApiVideoService trả về generateVideoId thay vì videoUrl trực tiếp
          if (_selectedMode.toLowerCase() == 'video' && result.containsKey('generateVideoId')) {
            final int generateVideoId = result['generateVideoId'];
            _generationResult = "Video đang được tạo (ID: $generateVideoId)";
            
            // Không lưu vào history ngay lập tức vì chưa có URL
            // URL sẽ được FCM callback cung cấp sau
            
            // Send notification about pending video
            _sendNotificationSuccess('video_pending', {
              'generateVideoId': generateVideoId,
              'message': 'Video đang được tạo, chờ thông báo khi hoàn thành'
            });
            
            // Show a dialog to let the user know about pending video
            _showInfoMessage(
              'Yêu cầu tạo video đã được gửi (ID: $generateVideoId).\n\nBạn sẽ nhận được thông báo khi video đã sẵn sàng.',
              showSlideListOption: false
            );
          }
        } else if (result.containsKey('slideUrl')) {
          _generationResult = result['slideUrl'];

          // Save to history
          _contentStorageService.saveContent(
            subject: _selectedSubject!,
            chapter: _selectedChapter!,
            grade: _selectedGrade,
            contentType: 'slides',
            url: _generationResult!,
          );

          // Send success notification for slide
          _sendNotificationSuccess('slide', result);
          _showSuccessDialog('Slides', _generationResult!);
        }

        // Store both URLs if they exist for future reference
        if (result.containsKey('slideUrl') && result.containsKey('videoUrl')) {
          // Also save the alternate version to history if it was generated
          final String contentType = _selectedMode.toLowerCase() == 'video'
              ? 'slides'
              : 'video';
          final String url = _selectedMode.toLowerCase() == 'video'
              ? result['slideUrl']
              : result['videoUrl'];

          _contentStorageService.saveContent(
            subject: _selectedSubject!,
            chapter: _selectedChapter!,
            grade: _selectedGrade,
            contentType: contentType,
            url: url,
          );

          // Send notification for both content types
          _sendNotificationSuccess('both', result);
        }
      });
    } catch (e) {
      // Error handling with better 202 handling
      String errorMsg = e.toString();
      
      if (errorMsg.contains('202') && _selectedMode.toLowerCase() == 'video') {
        // This is a 202 Accepted response, which is expected for video creation
        
        try {
          // Try to parse the response if it contains JSON
          Map<String, dynamic>? data;
          int? generateVideoId;
          
          // Try several possible formats
          if (errorMsg.contains('{') && errorMsg.contains('}')) {
            // Extract JSON from the error message
            final jsonStart = errorMsg.indexOf('{');
            final jsonEnd = errorMsg.lastIndexOf('}') + 1;
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonStr = errorMsg.substring(jsonStart, jsonEnd);
              data = jsonDecode(jsonStr);
              
              // Try to extract generateVideoId
              if (data != null && data.containsKey('result')) {
                if (data['result'] is int) {
                  generateVideoId = data['result'];
                } else if (data['result'] is String && int.tryParse(data['result']) != null) {
                  generateVideoId = int.parse(data['result']);
                } else if (data['result'] is Map && data['result'].containsKey('generateVideoId')) {
                  generateVideoId = data['result']['generateVideoId'];
                }
              }
            }
          }
          
          if (generateVideoId != null) {
            // Successfully parsed ID
            setState(() {
              _isGenerating = true; // Keep loading active
              _generationResult = "Video đang được tạo (ID: $generateVideoId)";
            });
            
            // Send notification about pending video
            _sendNotificationSuccess('video_pending', {
              'generateVideoId': generateVideoId,
              'message': data?['message'] ?? 'Video đang được tạo, chờ thông báo khi hoàn thành'
            });
            
            // Show overlay already active, no need for additional dialog
            return; // Exit the catch block successfully
          } else {
            // Couldn't parse ID but still handling as success
            return; // Exit without showing error
          }
        } catch (parseError) {
          // Continue with video generation even if parsing failed
          return; // Exit without showing error
        }
      }
      
      // Handle as a real error
      setState(() {
        _errorMessage = errorMsg.replaceAll('Exception: ', '');
        _isGenerating = false;
      });

      // Send failure notification
      await _sendNotificationFailed(_errorMessage!);
      _showErrorDialog(_errorMessage!);
    }
  }
  
  // Handle timeout in case FCM notifications aren't received
  void _handleGenerationTimeout() {
    if (!mounted) return;
    
    // Don't do anything if generation process is no longer active
    if (!_isGenerating) return;
    
    // Mark timeout as triggered
    _timeoutTriggered = true;
    
    // For slides-only mode, we can auto-complete
    if (_selectedMode.toLowerCase() == 'slides') {
      setState(() {
        _isGenerating = false;
        _slideCompleted = true;
      });
      
      _showInfoMessage('Tạo slide có vẻ đã hoàn tất! Bạn có thể xem trong danh sách nội dung đã tạo.');
      
      // Redirect to content history screen
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const ContentHistoryScreen(),
            ),
          );
        }
      });
    } 
    // For video mode, just update the UI to show progress but KEEP spinner
    else if (_selectedMode.toLowerCase() == 'video') {
      // If slide is already complete, don't change anything
      if (!_slideCompleted) {
        setState(() {
          // Mark slide as complete to update UI, but KEEP loading state active
          _slideCompleted = true;
        });
      }
      
      // Just show info, don't redirect or stop loading
      _showInfoMessage(
        'Quá trình tạo video mất nhiều thời gian.\n\nBạn sẽ nhận được thông báo khi video hoàn tất.',
        showSlideListOption: true
      );
    }
  }

  // Send notification when content generation starts
  Future<void> _sendNotificationStarted() async {
    try {
      await _fcmService.showLocalNotification(
        title: 'Đang tạo nội dung...',
        body:
            'EduVision đang tạo ${_selectedMode == 'video' ? 'video' : 'slide'} cho $_selectedSubject - $_selectedChapter',
        data: {
          'type': 'generation_started',
          'subject': _selectedSubject!,
          'chapter': _selectedChapter!,
          'mode': _selectedMode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Error handling silently
    }
  }

  // Send notification when content generation succeeds
  Future<void> _sendNotificationSuccess(
    String contentType,
    Map<String, dynamic> result,
  ) async {
    try {
      String title = '';
      String body = '';
      String notificationType = '';
      Map<String, dynamic> notificationData = {
        'subjectId': _selectedSubject!,
        'chapterId': _selectedChapter!,
        'subject': _selectedSubject!,
        'chapter': _selectedChapter!,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (contentType == 'video') {
        title = 'Video đã sẵn sàng! 🎥';
        body =
            'Video cho $_selectedSubject - $_selectedChapter đã được tạo thành công';
        notificationType = 'video_generated';
        if (result.containsKey('videoUrl')) {
          notificationData['videoUrl'] = result['videoUrl'];
        }
      } else if (contentType == 'video_pending') {
        title = 'Đang tạo video... 🎬';
        body =
            'Yêu cầu tạo video cho $_selectedSubject - $_selectedChapter đã được gửi';
        notificationType = 'video_pending';
        if (result.containsKey('generateVideoId')) {
          notificationData['generateVideoId'] = result['generateVideoId'];
        }
        if (result.containsKey('message')) {
          notificationData['message'] = result['message'];
        }
      } else if (contentType == 'slide') {
        title = 'Slide đã sẵn sàng! 📊';
        body =
            'Slide cho $_selectedSubject - $_selectedChapter đã được tạo thành công';
        notificationType = 'slide_generated';
        if (result.containsKey('slideUrl')) {
          notificationData['slideUrl'] = result['slideUrl'];
        }
      } else if (contentType == 'both') {
        title = 'Nội dung đã hoàn tất! 🎉';
        body =
            'Cả slide và video cho $_selectedSubject - $_selectedChapter đã sẵn sàng';
        notificationType = 'slide_and_video_generated';
        if (result.containsKey('slideUrl')) {
          notificationData['slideUrl'] = result['slideUrl'];
        }
        if (result.containsKey('videoUrl')) {
          notificationData['videoUrl'] = result['videoUrl'];
        }
      }

      notificationData['type'] = notificationType;

      await _fcmService.showLocalNotification(
        title: title,
        body: body,
        data: notificationData,
      );
    } catch (e) {
      // Error handling silently
    }
  }

  // Send notification when content generation fails
  Future<void> _sendNotificationFailed(String error) async {
    try {
      await _fcmService.showLocalNotification(
        title: 'Tạo nội dung thất bại ❌',
        body:
            'Không thể tạo nội dung cho $_selectedSubject - $_selectedChapter',
        data: {
          'type': 'generation_failed',
          'subjectId': _selectedSubject ?? '',
          'chapterId': _selectedChapter ?? '',
          'subject': _selectedSubject ?? '',
          'chapter': _selectedChapter ?? '',
          'error': error,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Error handling silently
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String contentType, String url) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('$contentType đã được tạo thành công'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFF10B981),
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn có thể xem $contentType tại đường dẫn bên dưới:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                url,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Mở liên kết'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ContentViewerScreen(
                    url: url,
                    title:
                        '$contentType ${_selectedSubject ?? ""} - ${_selectedChapter ?? ""}',
                    contentType: contentType,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Manual refresh method
  Future<void> _refreshContent() async {

    setState(() {
      _isLoadingSubjects = true;
      _errorMessage = null;
      _availableSubjects.clear();
      _availableChapters.clear();
      _selectedSubject = null;
      _selectedChapter = null;
    });

    // Force re-check auth and reload data
    await _checkAuthAndLoadData();
  }

  /// Check if user is properly authenticated
  /// This method ensures consistency with the auth checks in _checkAuthAndLoadData
  bool _isUserAuthenticated() {
    final isSignedIn = _authService.isSignedIn;
    final currentUser = _authService.currentUser;
    final token = _authService.token;

    return isSignedIn &&
        currentUser != null &&
        token != null &&
        token.isNotEmpty;
  }

  /// Build loading overlay khi đang tạo nội dung
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading animation
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer progress indicator
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _slideCompleted ? Colors.green : Colors.purple[600]!,
                      ),
                      strokeWidth: 4,
                    ),
                    // Inner icon
                    Icon(
                      _selectedMode == 'video'
                          ? (_slideCompleted ? Icons.videocam : Icons.pending)
                          : Icons.slideshow,
                      size: 32,
                      color: _slideCompleted ? Colors.green : Colors.purple[600],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title with dynamic status
              Text(
                _selectedMode == 'video'
                    ? (_slideCompleted
                          ? 'Đang tạo video... 🎬'
                          : 'Đang tạo slide + video... 📊🎬')
                    : 'Đang tạo slide... 📊',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subject and chapter info
              Text(
                '$_selectedSubject - $_selectedChapter',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Status text with progress indicators
              Column(
                children: [
                  // Slide progress
                  Row(
                    children: [
                      Icon(
                        _slideCompleted ? Icons.check_circle : Icons.pending,
                        color: _slideCompleted ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _slideCompleted 
                              ? 'Slide đã hoàn thành'
                              : 'Đang tạo slide...',
                          style: TextStyle(
                            fontSize: 14,
                            color: _slideCompleted ? Colors.green : Colors.grey[800],
                            fontWeight: _slideCompleted ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Only show video progress if in video mode
                  if (_selectedMode == 'video') 
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          Icon(
                            _slideCompleted ? Icons.pending : Icons.hourglass_empty,
                            color: _slideCompleted ? Colors.orange : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _slideCompleted 
                                  ? 'Đang xử lý video...'
                                  : 'Chờ hoàn thành slide...',
                              style: TextStyle(
                                fontSize: 14,
                                color: _slideCompleted ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Additional information or hint text
              Text(
                'Quá trình này có thể mất một vài phút.\nBạn sẽ nhận thông báo khi hoàn tất.',
                style: TextStyle(
                  fontSize: 13, 
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is properly authenticated
    if (!_isUserAuthenticated()) {
      return _buildLoginPrompt();
    }

    return Stack(
      children: [
        CupertinoPageScaffold(
          navigationBar: EduVisionHeader(
            title: 'Tạo nội dung học tập',
            showBackButton: true,
            actions: [
              // View slides button
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.list_bullet,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const SlideListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // View videos button
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.video_camera,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const ApiVideoListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // History button
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.time,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const ContentHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          child: SafeArea(
            child: _isLoadingSubjects
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header illustration
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.sparkles,
                              size: 50,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Tạo nội dung học tập thông minh',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Hãy chọn môn học và bài học bạn muốn tạo nội dung',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Content Type Selector
                        _buildSegmentedControl(),
                        const SizedBox(height: 24),

                        // Basic Settings Card
                        _buildCard(
                          title: 'Thông tin cơ bản',
                          children: [
                            // Subject Picker
                            _buildCupertinoPicker(
                              label: 'Môn học',
                              value: _selectedSubject,
                              items: _availableSubjects,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedSubject = value;
                                  _selectedChapter = null;
                                  _loadChapters();
                                });
                              },
                              icon: CupertinoIcons.book_fill,
                            ),
                            const SizedBox(height: 16),

                            // Grade Picker
                            _buildCupertinoPicker(
                              label: 'Lớp',
                              value: _selectedGrade.toString(),
                              items: _availableGrades,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedGrade = int.parse(value);
                                    _loadChapters();
                                  });
                                }
                              },
                              icon: CupertinoIcons.person_2_fill,
                            ),
                            const SizedBox(height: 16),

                            // Chapter Picker
                            _isLoadingChapters
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  )
                                : _buildCupertinoPicker(
                                    label: 'Bài học',
                                    value: _selectedChapter,
                                    items: _availableChapters,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedChapter = value;
                                      });
                                    },
                                    icon: CupertinoIcons.doc_text_fill,
                                  ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Advanced Settings Card
                        _buildCard(
                          title: 'Tùy chọn nâng cao',
                          children: [
                            // Template Picker
                            _buildCupertinoPicker(
                              label: 'Mẫu thiết kế',
                              value: 'Mẫu $_selectedTemplate',
                              items: _availableTemplates,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTemplate = int.parse(
                                      value.replaceAll('Mẫu ', ''),
                                    );
                                  });
                                }
                              },
                              icon: CupertinoIcons.square_grid_2x2_fill,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Generate Button
                        SizedBox(
                          height: 56,
                          child: CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(12),
                            padding: EdgeInsets.zero,
                            onPressed: _isGenerating ? null : _generateContent,
                            child: _isGenerating
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Đang tạo ${_selectedMode == 'video' ? 'video' : 'slide'}...',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Tạo nội dung',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ),
        // Loading overlay
        if (_isGenerating) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return CupertinoPageScaffold(
      navigationBar: const EduVisionHeader(
        title: 'Tạo nội dung học tập',
        showBackButton: true,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image or Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.lock_fill,
                  size: 60,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 32),

              // Title and description
              const Text(
                'Đăng nhập để sử dụng tính năng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng đăng nhập để sử dụng tính năng tạo nội dung học tập',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: () async {
                      // Navigate to login page
                      await Navigator.push(
                        context, 
                        CupertinoPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      
                      // Refresh data after return
                      _checkAuthAndLoadData();
                    },
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Refresh button for troubleshooting
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onPressed: _refreshContent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.refresh,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Làm mới trang',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
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
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _selectedMode,
        children: const {
          'slides': Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Slides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          'video': Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              'Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedMode = value;
            });
          }
        },
        thumbColor: CupertinoColors.white,
        backgroundColor: const Color(0xFFF3F4F6),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCupertinoPicker({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCupertinoPicker(items, value, onChanged),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Chọn một giá trị',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCupertinoPicker(
    List<String> items,
    String? currentValue,
    Function(String?) onChanged,
  ) {
    int selectedIndex = items.indexOf(currentValue ?? '');
    if (selectedIndex == -1) selectedIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Xong'),
                    onPressed: () {
                      Navigator.pop(context);
                      if (selectedIndex >= 0 && selectedIndex < items.length) {
                        onChanged(items[selectedIndex]);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: items
                    .map(
                      (item) => Center(
                        child: Text(item, style: const TextStyle(fontSize: 16)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
