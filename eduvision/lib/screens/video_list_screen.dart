import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lecture_video.dart';
import '../services/video_service.dart';
import '../widgets/video_card.dart';
import '../widgets/subject_filter.dart';
import '../widgets/eduvision_header.dart';
import 'content_generation_screen.dart';
import 'video_result_screen.dart';
import 'content_viewer_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({Key? key}) : super(key: key);

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final VideoService _videoService = VideoService();
  List<LectureVideo> _videos = [];
  List<LectureVideo> _filteredVideos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedSubject;
  final TextEditingController _searchController = TextEditingController();
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _searchController.addListener(_filterVideos);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterVideos);
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final videos = _videoService.getAllVideos();
    
    if (mounted) {
      setState(() {
        _videos = videos;
        _filteredVideos = videos;
        _subjects = videos.map((v) => v.subject).toSet().toList();
        _isLoading = false;
      });
    }
  }
  
  void _filterVideos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      _filteredVideos = _videos.where((video) {
        final matchesQuery = query.isEmpty ||
            video.title.toLowerCase().contains(query) ||
            video.subject.toLowerCase().contains(query) ||
            video.topic.toLowerCase().contains(query);
        
        final matchesSubject = _selectedSubject == null ||
            video.subject == _selectedSubject;
        
        return matchesQuery && matchesSubject;
      }).toList();
    });
  }
  
  void _onSubjectSelected(String? subject) {
    setState(() {
      _selectedSubject = subject;
    });
    _filterVideos();
  }
  
  Future<void> _refreshVideos() async {
    await _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Video bài giảng',
          style: TextStyle(fontFamily: '.SF Pro Display'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const ContentGenerationScreen(initialMode: 'video'),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemGrey6,
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey4,
                    width: 0.5,
                  ),
                ),
              ),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Tìm kiếm video...',
                style: const TextStyle(fontFamily: '.SF Pro Text'),
              ),
            ),
            
            // Subject filter
            if (_subjects.isNotEmpty)
              SubjectFilterBar(
                subjects: _subjects,
                selectedSubject: _selectedSubject,
                onSubjectSelected: _onSubjectSelected,
              ),
            
            // Video list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(radius: 20),
                    )
                  : _filteredVideos.isEmpty
                      ? _buildEmptyState()
                      : CustomScrollView(
                          slivers: [
                            CupertinoSliverRefreshControl(
                              onRefresh: _refreshVideos,
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final video = _filteredVideos[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: VideoCard(
                                        video: video,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                              builder: (context) => VideoResultScreen(
                                                videoId: video.id,
                                              ),
                                            ),
                                          );
                                        },
                                        animate: true,
                                        index: index,
                                      ),
                                    );
                                  },
                                  childCount: _filteredVideos.length,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.videocam,
                size: 50,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedSubject != null
                  ? 'Không tìm thấy video phù hợp'
                  : 'Chưa có video nào',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
                fontFamily: '.SF Pro Display',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedSubject != null
                  ? 'Thử tìm kiếm với từ khóa khác'
                  : 'Tạo video đầu tiên của bạn ngay bây giờ',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey2,
                fontFamily: '.SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _selectedSubject == null) ...[
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const ContentGenerationScreen(initialMode: 'video'),
                    ),
                  );
                },
                child: const Text(
                  'Tạo video mới',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

