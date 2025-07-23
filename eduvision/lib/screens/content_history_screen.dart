import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import '../services/education_service.dart';
import 'content_viewer_screen.dart';

class ContentHistoryScreen extends StatefulWidget {
  const ContentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ContentHistoryScreen> createState() => _ContentHistoryScreenState();
}

class _ContentHistoryScreenState extends State<ContentHistoryScreen> {
  final EducationService _educationService = EducationService();
  List<Map<String, dynamic>> _slides = [];
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0 for Slides, 1 for Videos

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await _educationService.getUserContent();

      setState(() {
        _slides = content['slides'] ?? [];
        _videos = content['videos'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Không thể tải nội dung: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      developer.log(
        'Attempting to open URL: $url',
        name: 'ContentHistoryScreen',
      );

      // Xử lý URL từ Azure Blob Storage (vấn đề bạn đang gặp)
      String processedUrl = url;
      String title = 'Nội dung';

      // Nếu URL đến từ Azure Blob Storage và là file HTML
      if (url.contains('blob.core.windows.net') && url.endsWith('.html')) {
        developer.log(
          'Processing Azure Blob Storage URL for HTML file',
          name: 'ContentHistoryScreen',
        );
        // Thêm một query parameter để đảm bảo trình duyệt hiểu đó là trang HTML
        if (!url.contains('?')) {
          processedUrl = '$url?view=html';
        }
        title = 'Slides';
      } else if (url.contains('video')) {
        title = 'Video';
      }

      final uri = Uri.parse(processedUrl);
      developer.log('Parsed URI: $uri', name: 'ContentHistoryScreen');

      // Thử phương pháp 1: Mở WebView trong ứng dụng (phương pháp đáng tin cậy nhất)
      _openInBuiltInWebView(processedUrl, title);

      /* 
      // Phương pháp 2: Sử dụng URL Launcher (có thể không hoạt động với Azure Blob Storage)
      if (await canLaunchUrl(uri)) {
        developer.log('Can launch URL, attempting to open...', name: 'ContentHistoryScreen');
        
        // Thử mở trong trình duyệt bên trong ứng dụng trước
        bool launched = false;
        try {
          launched = await launchUrl(
            uri, 
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
              enableDomStorage: true,
            ),
          );
          developer.log('InAppWebView launch result: $launched', name: 'ContentHistoryScreen');
        } catch (webViewError) {
          developer.log('InAppWebView error: $webViewError', name: 'ContentHistoryScreen');
          launched = false;
        }
        
        if (!launched) {
          // Nếu không mở được bằng InAppWebView, thử dùng trình duyệt mặc định
          developer.log('Falling back to external browser', name: 'ContentHistoryScreen');
          launched = await launchUrl(
            uri, 
            mode: LaunchMode.externalApplication,
          );
          
          if (!launched) {
            // Nếu vẫn không được, thử mở bằng chế độ platformDefault
            developer.log('Falling back to platform default', name: 'ContentHistoryScreen');
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        }
        
        if (!launched) {
          // Nếu tất cả các phương pháp đều thất bại, mở WebView tùy chỉnh
          _openInBuiltInWebView(processedUrl, title);
        }
      } else {
        developer.log('Cannot launch URL: $url', name: 'ContentHistoryScreen');
        // Thử dùng WebView tùy chỉnh
        _openInBuiltInWebView(processedUrl, title);
      }
      */
    } catch (e) {
      developer.log(
        'Exception when opening URL: $e',
        name: 'ContentHistoryScreen',
      );
      _showErrorMessage('Lỗi khi mở URL: $e');
    }
  }

  void _openInBuiltInWebView(String url, String title) {
    developer.log(
      'Opening in built-in WebView: $url',
      name: 'ContentHistoryScreen',
    );
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ContentViewerScreen(
          url: url, 
          title: title,
          contentType: _selectedTab == 0 ? 'slide' : 'video',
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
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

  String _getStatusColor(String? status) {
    if (status == null) return 'info';
    
    switch (status.toLowerCase()) {
      case 'completed':
        return 'success';
      case 'failed':
        return 'error';
      case 'processing':
      case 'in progress':
      case 'pending':
        return 'warning';
      default:
        return 'info';
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Không xác định';
    
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Hoàn thành';
      case 'failed':
        return 'Thất bại';
      case 'processing':
      case 'in progress':
      case 'pending':
        return 'Đang xử lý';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Nội dung đã tạo',
          style: TextStyle(fontFamily: '.SF Pro Display'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tab bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                children: const {0: Text('Slides'), 1: Text('Videos')},
                onValueChanged: (value) {
                  setState(() {
                    _selectedTab = value ?? 0;
                  });
                },
                groupValue: _selectedTab,
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildContentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList() {
    final List<Map<String, dynamic>> contentToShow = _selectedTab == 0
        ? _slides
        : _videos;

    if (contentToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 0
                  ? CupertinoIcons.doc_text
                  : CupertinoIcons.play_rectangle,
              size: 64,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 0 ? 'Chưa có slides nào' : 'Chưa có videos nào',
              style: const TextStyle(
                fontSize: 18,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy tạo nội dung mới để xem ở đây',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contentToShow.length,
      itemBuilder: (context, index) {
        final content = contentToShow[index];
        return _buildContentCard(content);
      },
    );
  }

  Widget _buildContentCard(Map<String, dynamic> content) {
    final String status = content['status'] ?? 'Unknown';
    final String statusText = _getStatusText(status);
    final String title = content['promptContent'] ?? 'Untitled';
    final String type = content['type'] ?? '';
    final String url = content['url'] ?? content['videoUrl'] ?? '';
    final int id =
        content['slideId'] ??
        content['generateVideoId'] ??
        content['videoId'] ??
        0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
      ),
      child: CupertinoListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _selectedTab == 0
                ? CupertinoColors.activeBlue.withOpacity(0.1)
                : CupertinoColors.systemPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _selectedTab == 0
                ? CupertinoIcons.doc_text_fill
                : CupertinoIcons.play_rectangle_fill,
            color: _selectedTab == 0
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemPurple,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type.isNotEmpty)
              Text(
                'Môn: $type',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status) == 'success'
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : _getStatusColor(status) == 'error'
                        ? CupertinoColors.systemRed.withOpacity(0.1)
                        : CupertinoColors.systemOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status) == 'success'
                          ? CupertinoColors.systemGreen
                          : _getStatusColor(status) == 'error'
                          ? CupertinoColors.systemRed
                          : CupertinoColors.systemOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: $id',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey2,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: status.toLowerCase() == 'completed' && url.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openUrl(url),
                child: const Icon(
                  CupertinoIcons.square_arrow_up_on_square,
                  color: CupertinoColors.activeBlue,
                ),
              )
            : const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.systemGrey3,
              ),
        onTap: status.toLowerCase() == 'completed' && url.isNotEmpty
            ? () => _openUrl(url)
            : null,
      ),
    );
  }
}
