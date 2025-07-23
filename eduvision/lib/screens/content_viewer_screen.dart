import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/eduvision_header.dart';

class ContentViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final String contentType;

  const ContentViewerScreen({
    Key? key,
    required this.url,
    required this.title,
    required this.contentType,
  }) : super(key: key);

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  bool _isLoading = true;
  late final WebViewController _webViewController;
  bool _webViewLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize WebView controller
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // WebView error handling
          },
        ),
      );
      
    // Simulate loading delay for UI
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Load URL into WebView
  void _loadUrl() {
    setState(() {
      _webViewLoaded = true;
    });
    _webViewController.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: EduVisionHeader(
        title: widget.title,
        showBackButton: true,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // URL
                  Row(
                    children: [
                      Icon(
                        widget.contentType == 'Video'
                            ? CupertinoIcons.video_camera_solid
                            : CupertinoIcons.doc_richtext,
                        size: 16,
                        color: const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.url,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(radius: 16),
                          SizedBox(height: 16),
                          Text(
                            'Đang tải nội dung...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // WebView when content is loaded
                        if (_webViewLoaded)
                          WebViewWidget(controller: _webViewController),
                        
                        // Button overlay for loading the content
                        if (!_webViewLoaded)
                          Container(
                            color: const Color(0xFFF9FAFB),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0E7FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      widget.contentType == 'Video'
                                          ? CupertinoIcons.play_circle_fill
                                          : CupertinoIcons.doc_richtext,
                                      size: 40,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nội dung ${widget.contentType} đã sẵn sàng',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Nhấn nút bên dưới để xem nội dung',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  CupertinoButton.filled(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    borderRadius: BorderRadius.circular(8),
                                    onPressed: _loadUrl,
                                    child: const Text(
                                      'Xem nội dung',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
