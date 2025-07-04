import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/education_service.dart';

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
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorMessage('Không thể mở URL: $url');
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi mở URL: $e');
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

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'success';
      case 'failed':
        return 'error';
      case 'processing':
        return 'warning';
      default:
        return 'info';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Hoàn thành';
      case 'failed':
        return 'Thất bại';
      case 'processing':
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
    final String url = content['url'] ?? '';
    final int id = content['slideId'] ?? content['videoId'] ?? 0;

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
