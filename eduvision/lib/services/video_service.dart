import '../models/lecture_video.dart';
import '../models/slide.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VideoService {
  // Singleton pattern
  static final VideoService _instance = VideoService._internal();
  
  factory VideoService() => _instance;
  
  VideoService._internal() {
    // Tải dữ liệu video từ local storage khi khởi tạo
    _loadVideosFromLocal();
  }

  // Danh sách video bài giảng mẫu
  final List<LectureVideo> _videos = [];
  
  // Key để lưu trữ trong SharedPreferences
  static const String _videosStorageKey = 'lecture_videos';
  // Lấy danh sách tất cả video
  List<LectureVideo> getAllVideos() {
    return List.unmodifiable(_videos);
  }

  // Tải video từ local storage
  Future<void> _loadVideosFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getString(_videosStorageKey);
      
      if (videosJson != null) {
        final List<dynamic> decodedList = jsonDecode(videosJson);
        final videos = decodedList.map((item) => LectureVideo.fromJson(item)).toList();
        
        _videos.clear();
        _videos.addAll(videos);
      }
    } catch (e) {
      // Error handled gracefully
    }
  }

  // Lưu video vào local storage
  Future<void> _saveVideosToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = jsonEncode(_videos.map((video) => video.toJson()).toList());
      await prefs.setString(_videosStorageKey, videosJson);
    } catch (e) {
      // Error handled silently
    }
  }  // Tạo video bài giảng mới
  Future<LectureVideo> createVideo({
    required String subject,
    required String chapter,
    required String topic,
    String? grade,
    String? imageCategory,
    String? template,
    String? mode,
  }) async {
    // Giả lập độ trễ khi tạo video
    await Future.delayed(const Duration(seconds: 2));

    // Tạo ID ngẫu nhiên
    final id = 'vid_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    
    // Tạo video mới
    final newVideo = LectureVideo(
      id: id,
      title: '$subject - $topic',
      subject: subject,
      chapter: chapter,
      topic: topic,
      grade: grade,
      imageCategory: imageCategory,
      template: template,
      mode: mode,
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    // Thêm vào danh sách
    _videos.add(newVideo);
    
    // Lưu vào local storage
    await _saveVideosToLocal();

    return newVideo;
  }  // Giả lập quá trình tạo video
  Future<LectureVideo> processVideo(String videoId) async {
    // Tìm video cần xử lý
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index == -1) {
      throw Exception('Không tìm thấy video');
    }

    // Giả lập thời gian xử lý
    await Future.delayed(const Duration(seconds: 3));

    // Tạo danh sách các slide giả định
    final slides = List.generate(
      5,
      (i) => Slide(
        id: 'slide_${_videos[index].id}_$i',
        title: 'Slide ${i + 1}',
        content: 'Nội dung cho slide ${i + 1} của ${_videos[index].topic}',
        imageUrl: 'https://example.com/images/slide_$i.jpg',
        slideNumber: i + 1,
        // Add API format fields with null values for compatibility
        slideId: null,
        promptId: null,
        type: _videos[index].subject,
        url: null,
        status: "Completed",
        promptContent: 'Slide ${i + 1} của ${_videos[index].topic}',
      ),
    );

    // Cập nhật trạng thái video
    final updatedVideo = LectureVideo(
      id: _videos[index].id,
      title: _videos[index].title,
      subject: _videos[index].subject,
      chapter: _videos[index].chapter,
      topic: _videos[index].topic,
      videoUrl: 'https://example.com/videos/${_videos[index].id}.mp4', // URL giả lập video
      slideUrl: 'https://example.com/slides/${_videos[index].id}.pdf', // URL giả lập slide
      slides: slides,
      grade: _videos[index].grade,
      imageCategory: _videos[index].imageCategory,
      template: _videos[index].template,
      mode: _videos[index].mode,
      createdAt: _videos[index].createdAt,
      isCompleted: true,
    );

    // Cập nhật vào danh sách
    _videos[index] = updatedVideo;
    
    // Lưu vào local storage
    await _saveVideosToLocal();

    return updatedVideo;
  }
  // Xóa video
  Future<void> deleteVideo(String videoId) async {
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index != -1) {
      _videos.removeAt(index);
      // Lưu thay đổi vào local storage
      await _saveVideosToLocal();
    }
  }
  
  // Thêm video mẫu để demo
  Future<void> addDemoVideos() async {
    if (_videos.isEmpty) {
      // Thêm một số video mẫu nếu danh sách trống
      await createVideo(
        subject: 'Toán học',
        chapter: 'Đại số',
        topic: 'Phương trình bậc 2',
      );
      
      await createVideo(
        subject: 'Vật lý',
        chapter: 'Cơ học',
        topic: 'Chuyển động thẳng đều',
      );
      
      await createVideo(
        subject: 'Hóa học',
        chapter: 'Hóa hữu cơ',
        topic: 'Ankan và đồng đẳng',
      );
    }
  }
  // Tìm kiếm video theo từ khóa
  List<LectureVideo> searchVideos(String keyword) {
    if (keyword.isEmpty) {
      return getAllVideos();
    }
    
    final lowercaseKeyword = keyword.toLowerCase();
    return _videos.where((video) {
      return video.title.toLowerCase().contains(lowercaseKeyword) ||
             video.subject.toLowerCase().contains(lowercaseKeyword) ||
             video.chapter.toLowerCase().contains(lowercaseKeyword) ||
             video.topic.toLowerCase().contains(lowercaseKeyword);
    }).toList();
  }
  
  // Lọc video theo chủ đề
  List<LectureVideo> filterBySubject(String subject) {
    if (subject.isEmpty) {
      return getAllVideos();
    }
    
    return _videos.where((video) => 
      video.subject.toLowerCase() == subject.toLowerCase()
    ).toList();
  }
  
  // Lấy danh sách tất cả các chủ đề
  List<String> getAllSubjects() {
    final subjects = <String>{};
    for (var video in _videos) {
      subjects.add(video.subject);
    }
    return subjects.toList();
  }
}

