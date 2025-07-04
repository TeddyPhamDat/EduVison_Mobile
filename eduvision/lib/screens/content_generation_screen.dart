import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:developer' as developer;
import '../services/gdcd_education_service.dart';
import '../services/education_service.dart';
import '../services/auth_service.dart';
import '../services/content_storage_service.dart';
import '../services/fcm_service.dart';
import '../widgets/eduvision_header.dart';
import 'login_screen.dart';
import 'content_viewer_screen.dart';
import 'content_history_screen.dart';

class ContentGenerationScreen extends StatefulWidget {
  const ContentGenerationScreen({super.key});

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

  bool _isLoadingSubjects = true;
  bool _isLoadingChapters = false;
  bool _isGenerating = false;

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
  final List<String> _availableTemplates = ['Mẫu 1', 'Mẫu 2', 'Mẫu 3'];

  @override
  void initState() {
    super.initState();
    _setupFCMHandlers();
    _setupAuthListener();
    _checkAuthAndLoadData();
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
      print('🎯 SLIDE GENERATED CALLBACK TRIGGERED!');
      print('📊 Callback Data: $data');
      if (mounted) {
        _showInfoMessage('📊 Slide đã được tạo thành công!');

        // Chỉ redirect nếu đây là slide-only (không phải part của video generation)
        // Kiểm tra xem có đang generate video không
        final String? generatingMode = _selectedMode;
        if (generatingMode == 'slides') {
          // Redirect đến MyContentScreen cho slide-only
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContentHistoryScreen(),
                ),
              );
            }
          });
        }
        // Nếu đang generate video, chỉ show message, không redirect
      }
    };

    _fcmService.onVideoGenerated = (data) {
      print('🎯 VIDEO GENERATED CALLBACK TRIGGERED!');
      print('🎥 Callback Data: $data');
      if (mounted) {
        _showInfoMessage('🎥 Video đã được tạo thành công!');

        // Đây là notification cuối cùng cho video generation, redirect ngay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContentHistoryScreen(),
              ),
            );
          }
        });
      }
    };

    _fcmService.onSlideAndVideoGenerated = (data) {
      print('🎯 SLIDE & VIDEO GENERATED CALLBACK TRIGGERED!');
      print('🎉 Callback Data: $data');
      if (mounted) {
        _showInfoMessage('🎉 Cả slide và video đã được tạo thành công!');

        // Redirect đến ContentHistoryScreen
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContentHistoryScreen(),
              ),
            );
          }
        });
      }
    };

    _fcmService.onGenerationFailed = (error, details) {
      print('❌ GENERATION FAILED CALLBACK TRIGGERED!');
      print('💥 Error: $error');
      print('📝 Details: $details');
      if (mounted) {
        _showInfoMessage('❌ Tạo nội dung thất bại: $error');
      }
    };

    _fcmService.onShowUINotification =
        (title, message, {bool isSuccess = true}) {
          print('🔔 UI Notification: [$title] $message (Success: $isSuccess)');
          if (mounted) {
            _showInfoMessage('🔔 $title: $message');
          }
        };

    print('✅ FCM Callbacks setup complete for ContentGenerationScreen');
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

  void _showInfoMessage(String message) {
    // Show a brief message to user
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Thông báo'),
          content: Text(message),
          actions: [
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
    developer.log('🔐 Checking auth state:', name: 'ContentGeneration');

    if (!_isUserAuthenticated()) {
      final isSignedIn = _authService.isSignedIn;
      final currentUser = _authService.currentUser;
      final token = _authService.token;

      developer.log('  - isSignedIn: $isSignedIn', name: 'ContentGeneration');
      developer.log(
        '  - currentUser: ${currentUser?.email}',
        name: 'ContentGeneration',
      );
      developer.log(
        '  - token available: ${token != null}',
        name: 'ContentGeneration',
      );
      developer.log('❌ Authentication failed', name: 'ContentGeneration');

      // Handle not signed in case
      setState(() {
        _isLoadingSubjects = false;
        _errorMessage = 'Bạn cần đăng nhập để sử dụng tính năng này.';
      });
      return;
    }

    developer.log(
      '✅ User authenticated successfully',
      name: 'ContentGeneration',
    );
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
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
        _generationResult = null;
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
        // Call videos API endpoint
        result = await _generalEducationService.generateContent(
          subject: _selectedSubject!,
          chapter: _selectedChapter!,
          grade: _selectedGrade,
          imageCategory: _selectedImageCategory,
          template: _selectedTemplate,
          mode: 'videos',
        );
      }

      setState(() {
        _isGenerating = false;

        // The API returns both slideUrl and videoUrl, choose based on the selected mode
        if (_selectedMode.toLowerCase() == 'video' &&
            result.containsKey('videoUrl')) {
          _generationResult = result['videoUrl'];

          // Save to history
          _contentStorageService.saveContent(
            subject: _selectedSubject!,
            chapter: _selectedChapter!,
            grade: _selectedGrade,
            contentType: 'video',
            url: _generationResult!,
          );

          // Send success notification for video
          _sendNotificationSuccess('video', result);
          _showSuccessDialog('Video', _generationResult!);
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
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isGenerating = false;
      });

      // Send failure notification
      await _sendNotificationFailed(_errorMessage!);
      _showErrorDialog(_errorMessage!);
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
      print('Error sending start notification: $e');
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
      print('Error sending success notification: $e');
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
      print('Error sending failure notification: $e');
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
    developer.log('🔄 Manual refresh triggered', name: 'ContentGeneration');

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

  @override
  Widget build(BuildContext context) {
    // Check if user is properly authenticated
    if (!_isUserAuthenticated()) {
      return _buildLoginPrompt();
    }

    return CupertinoPageScaffold(
      navigationBar: EduVisionHeader(
        title: 'Tạo nội dung học tập',
        showBackButton: true,
        actions: [
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
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
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
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
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
                      final result = await Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );

                      if (result == true) {
                        // User signed in, refresh data
                        _checkAuthAndLoadData();
                      }
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
