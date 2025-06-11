import 'package:flutter/material.dart';
import '../models/lecture_video.dart';
import '../services/video_service.dart';
import '../widgets/custom_header.dart';
import '../widgets/video_card.dart';
import '../widgets/subject_filter.dart';
import 'create_video_screen.dart';
import 'video_result_screen.dart';

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
    
    // Giả lập độ trễ tải dữ liệu
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Lấy danh sách video từ service
    final videos = _videoService.getAllVideos();
    
    if (mounted) {
      setState(() {
        _videos = videos;
        _subjects = _videoService.getAllSubjects();
        _filterVideos(); // Lọc lại dữ liệu dựa trên từ khóa hiện tại
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadDemoVideos() async {
    setState(() {
      _isLoading = true;
    });
    
    // Thêm các video demo
    await _videoService.addDemoVideos();
    
    // Tải lại danh sách
    await _loadVideos();
  }

  void _filterVideos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      
      // Đầu tiên lọc theo chủ đề (nếu có)
      List<LectureVideo> results = _selectedSubject != null 
          ? _videoService.filterBySubject(_selectedSubject!)
          : _videos;
      
      // Sau đó lọc theo từ khóa tìm kiếm (nếu có)
      if (query.isNotEmpty) {
        results = results.where((video) {
          return video.title.toLowerCase().contains(query) ||
                 video.subject.toLowerCase().contains(query) ||
                 video.chapter.toLowerCase().contains(query) ||
                 video.topic.toLowerCase().contains(query);
        }).toList();
      }
      
      _filteredVideos = results;
    });
  }
  
  void _onSubjectSelected(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _filterVideos();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        title: 'Video Của Bạn',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateVideoScreen()),
          ).then((_) => _loadVideos());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm video...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          
          // Thanh lọc theo chủ đề
          if (_subjects.isNotEmpty)
            SubjectFilterBar(
              subjects: _subjects,
              selectedSubject: _selectedSubject,
              onSubjectSelected: _onSubjectSelected,
            ),
          
          // Nội dung chính
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVideos.isEmpty
                    ? _buildEmptyState()
                    : _buildVideoList(),
          ),
        ],      
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có video nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy nhấn nút + để tạo video bài giảng đầu tiên',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateVideoScreen()),
              ).then((_) => _loadVideos());
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo video bài giảng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadDemoVideos,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Tải video demo'),
          ),
        ],      ),
    );
  }
  
  Widget _buildVideoList() {
    return ListView.builder(
      itemCount: _filteredVideos.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final video = _filteredVideos[index];
        return VideoCard(
          video: video,
          index: index,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoResultScreen(videoId: video.id),
              ),
            ).then((_) => _loadVideos());          },
        );
      },
    );
  }
}
