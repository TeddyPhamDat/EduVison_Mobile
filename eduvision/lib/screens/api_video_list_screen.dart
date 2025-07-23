import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/api_video_service.dart';
import '../widgets/eduvision_header.dart';
import 'content_viewer_screen.dart';

class ApiVideoListScreen extends StatefulWidget {
  const ApiVideoListScreen({Key? key}) : super(key: key);

  @override
  State<ApiVideoListScreen> createState() => _ApiVideoListScreenState();
}

class _ApiVideoListScreenState extends State<ApiVideoListScreen> {
  final ApiVideoService _apiVideoService = ApiVideoService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<ApiVideo> _videos = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  
  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _apiVideoService.fetchVideos(
        page: _currentPage,
        pageSize: 10,
      );
      
      setState(() {
        _videos = result['videos'] as List<ApiVideo>;
        _currentPage = result['page'] as int;
        _totalPages = result['totalPages'] as int;
        _hasNextPage = result['hasNextPage'] as bool;
        _hasPreviousPage = result['hasPreviousPage'] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _navigateToVideoViewer(ApiVideo video) {
    if (video.videoUrl != null) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ContentViewerScreen(
            title: video.promptContent,
            url: video.videoUrl!,
            contentType: 'video',
          ),
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Video chưa sẵn sàng'),
          content: const Text('Video này chưa được tạo hoặc đang trong quá trình xử lý.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildVideoItem(ApiVideo video) {
    return GestureDetector(
      onTap: video.videoUrl != null ? () => _navigateToVideoViewer(video) : null,
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
                color: video.status == 'Completed' ? Colors.green : 
                       video.status == 'Failed' ? Colors.red : Colors.orange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              width: double.infinity,
              child: Text(
                video.status == 'Completed' ? '✅ Hoàn thành' : 
                video.status == 'Failed' ? '❌ Thất bại' : '⏳ Đang xử lý',
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
                    video.promptContent,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Date
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ngày tạo: ${_formatDate(video.createdAt)}',
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
                              video.videoUrl != null ? 'Xem video' : 'Chưa sẵn sàng',
                              style: TextStyle(
                                fontSize: 14,
                                color: video.videoUrl != null ? null : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.arrow_right,
                              size: 16,
                              color: video.videoUrl != null ? null : Colors.grey,
                            ),
                          ],
                        ),
                        onPressed: video.videoUrl != null ? () => _navigateToVideoViewer(video) : null,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
                    _loadVideos();
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
                    _loadVideos();
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
        title: 'Danh sách Videos',
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
                            onPressed: _loadVideos,
                          ),
                        ],
                      ),
                    ),
                  )
                : _videos.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.video_camera,
                                size: 48,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Không tìm thấy video nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hãy tạo video mới từ màn hình Tạo nội dung',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              CupertinoButton.filled(
                                child: const Text('Làm mới'),
                                onPressed: _loadVideos,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Refresh button
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: const [
                                      Icon(CupertinoIcons.refresh),
                                      SizedBox(width: 4),
                                      Text('Làm mới'),
                                    ],
                                  ),
                                  onPressed: _loadVideos,
                                ),
                              ],
                            ),
                          ),
                          
                          // Videos list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _videos.length,
                              itemBuilder: (context, index) {
                                return _buildVideoItem(_videos[index]);
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
