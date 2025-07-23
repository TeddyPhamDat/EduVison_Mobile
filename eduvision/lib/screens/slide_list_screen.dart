import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/eduvision_header.dart';
import '../models/slide.dart';
import '../config/api_config.dart';
import 'content_viewer_screen.dart';
import 'content_history_screen.dart';

class SlideListScreen extends StatefulWidget {
  const SlideListScreen({Key? key}) : super(key: key);

  @override
  State<SlideListScreen> createState() => _SlideListScreenState();
}

class _SlideListScreenState extends State<SlideListScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Slide> _slides = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  
  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bạn cần đăng nhập để xem danh sách slide';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.slidesBaseUrl}?page=$_currentPage&pageSize=10'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200 && data['result'] != null) {
          final result = data['result'];
          final List<dynamic> slidesData = result['data'];
          
          setState(() {
            _slides = slidesData.map((slideData) => Slide.fromJson(slideData)).toList();
            _currentPage = result['page'];
            _totalPages = result['totalPages'];
            _hasNextPage = result['hasNextPage'];
            _hasPreviousPage = result['hasPreviousPage'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Không thể tải danh sách slide';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  void _navigateToSlideViewer(Slide slide) {
    if (slide.url == null) {
      // Show dialog if the URL is null
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Slide không có sẵn'),
          content: const Text('Slide này không thể hiển thị do quá trình tạo thất bại.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ContentViewerScreen(
          title: slide.promptContent ?? 'Slide Presentation',
          url: slide.url!, // Safe to use ! here because we've checked for null above
          contentType: 'slide',
        ),
      ),
    );
  }

  Widget _buildSlideItem(Slide slide) {
    return GestureDetector(
      onTap: slide.url != null ? () => _navigateToSlideViewer(slide) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Container(
              decoration: BoxDecoration(
                color: slide.status == 'Completed' ? Colors.green : 
                       slide.status == 'Failed' ? Colors.red : Colors.orange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              width: double.infinity,
              child: Text(
                slide.status == 'Completed' ? '✅ Hoàn thành' : 
                slide.status == 'Failed' ? '❌ Thất bại' : '⏳ Đang xử lý',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    slide.promptContent ?? 'Slide Presentation',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Type
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Môn học: ${slide.type}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // View button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Text(
                              slide.url != null ? 'Xem slide' : 'Không có sẵn',
                              style: TextStyle(
                                fontSize: 14,
                                color: slide.url != null ? null : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.arrow_right,
                              size: 16,
                              color: slide.url != null ? null : Colors.grey,
                            ),
                          ],
                        ),
                        onPressed: slide.url != null ? () => _navigateToSlideViewer(slide) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: !_hasPreviousPage
                ? null
                : () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadSlides();
                  },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.chevron_left,
                  color: !_hasPreviousPage ? Colors.grey : null,
                ),
                Text(
                  'Trước',
                  style: TextStyle(
                    color: !_hasPreviousPage ? Colors.grey : null,
                  ),
                ),
              ],
            ),
          ),
          
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Trang $_currentPage / $_totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Next page button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: !_hasNextPage
                ? null
                : () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadSlides();
                  },
            child: Row(
              children: [
                Text(
                  'Sau',
                  style: TextStyle(
                    color: !_hasNextPage ? Colors.grey : null,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: !_hasNextPage ? Colors.grey : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const EduVisionHeader(
        title: 'Danh sách Slides',
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            size: 48,
                            color: CupertinoColors.systemRed,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton.filled(
                            child: const Text('Thử lại'),
                            onPressed: _loadSlides,
                          ),
                        ],
                      ),
                    ),
                  )
                : _slides.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.doc_text,
                                size: 48,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Không tìm thấy slide nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hãy tạo slide mới từ màn hình Tạo nội dung',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              CupertinoButton.filled(
                                child: const Text('Làm mới'),
                                onPressed: _loadSlides,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Buttons row
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // View all content button
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: const [
                                      Icon(CupertinoIcons.list_bullet),
                                      SizedBox(width: 4),
                                      Text('Xem tất cả nội dung'),
                                    ],
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
                                
                                // Refresh button
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: const [
                                      Icon(CupertinoIcons.refresh),
                                      SizedBox(width: 4),
                                      Text('Làm mới'),
                                    ],
                                  ),
                                  onPressed: _loadSlides,
                                ),
                              ],
                            ),
                          ),
                          
                          // Slides list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _slides.length,
                              itemBuilder: (context, index) {
                                return _buildSlideItem(_slides[index]);
                              },
                            ),
                          ),
                          
                          // Pagination
                          if (_totalPages > 1) _buildPagination(),
                        ],
                      ),
      ),
    );
  }
}
