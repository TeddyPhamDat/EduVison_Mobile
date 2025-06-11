import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/generated_content.dart';
import '../services/content_storage_service.dart';
import '../widgets/eduvision_header.dart';
import 'content_viewer_screen.dart';

class ContentHistoryScreen extends StatefulWidget {
  const ContentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ContentHistoryScreen> createState() => _ContentHistoryScreenState();
}

class _ContentHistoryScreenState extends State<ContentHistoryScreen> {
  final ContentStorageService _contentStorageService = ContentStorageService();
  List<GeneratedContent> _contentHistory = [];
  List<GeneratedContent> _favoriteContent = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0 for History, 1 for Favorites

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
      final history = await _contentStorageService.getContentHistory();
      final favorites = await _contentStorageService.getFavoriteContent();

      setState(() {
        _contentHistory = history;
        _favoriteContent = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String contentId) async {
    try {
      await _contentStorageService.toggleFavorite(contentId);
      await _loadContent(); // Refresh content after toggling
    } catch (e) {
      // Show error message
      _showErrorMessage(e.toString());
    }
  }

  Future<void> _deleteContent(String contentId) async {
    try {
      await _contentStorageService.deleteContent(contentId);
      await _loadContent(); // Refresh content after deleting
    } catch (e) {
      // Show error message
      _showErrorMessage(e.toString());
    }
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

  void _confirmDelete(GeneratedContent content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${content.title}" khỏi lịch sử?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Xóa'),
            onPressed: () {
              Navigator.pop(context);
              _deleteContent(content.id);
            },
          ),
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const EduVisionHeader(
        title: 'Nội dung đã tạo',
        showBackButton: true,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tab Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? const Color(0xFF6C5CE7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Lịch sử',
                          style: TextStyle(
                            color: _selectedTab == 0
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? const Color(0xFF6C5CE7)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Yêu thích',
                          style: TextStyle(
                            color: _selectedTab == 1
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content List
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
    final List<GeneratedContent> contentToShow = 
        _selectedTab == 0 ? _contentHistory : _favoriteContent;
    
    if (contentToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.doc_text_search,
              size: 70,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 0
                  ? 'Không có nội dung nào trong lịch sử'
                  : 'Không có nội dung nào được đánh dấu yêu thích',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
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

  Widget _buildContentCard(GeneratedContent content) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final String formattedDate = dateFormat.format(content.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Favorite icon
                Row(
                  children: [
                    // Content type icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        content.contentType == 'slides'
                            ? CupertinoIcons.doc_text
                            : CupertinoIcons.play_rectangle,
                        color: const Color(0xFF6C5CE7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Favorite button
                    GestureDetector(
                      onTap: () => _toggleFavorite(content.id),
                      child: Icon(
                        content.isFavorite
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: content.isFavorite
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF9CA3AF),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Subject and grade
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        content.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lớp ${content.grade}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Chapter
                Text(
                  content.chapter,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Actions section
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // View button
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          CupertinoIcons.eye,
                          size: 18,
                          color: Color(0xFF6C5CE7),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xem',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => ContentViewerScreen(
                            url: content.url,
                            title: content.title,
                            contentType: content.contentType == 'slides' ? 'Slides' : 'Video',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Vertical divider
                Container(
                  height: 30,
                  width: 1,
                  color: const Color(0xFFE5E7EB),
                ),
                
                // Delete button
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          CupertinoIcons.delete,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xóa',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      _confirmDelete(content);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
