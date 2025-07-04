import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/api_models.dart';
import '../models/education_models.dart';
import 'auth_service.dart';

/// Service for managing education content - slides and videos generation
/// Maps to backend EducationController endpoints
class EducationService {
  // Singleton pattern
  static final EducationService _instance = EducationService._internal();

  factory EducationService() => _instance;

  EducationService._internal();

  // Auth service for getting token
  final AuthService _authService = AuthService();

  // Cache keys
  static const String _subjectsCacheKey = 'education_subjects_cache';
  static const String _chaptersCacheKeyPrefix = 'education_chapters_cache_';
  static const String _slidesCacheKey = 'education_slides_cache';
  static const String _videosCacheKey = 'education_videos_cache';

  // Cache expiration in hours
  static const int _cacheExpirationHours = 24;
  static const int _contentCacheHours = 1; // Shorter cache for user content

  /// Get all available subjects
  /// Maps to: GET /api/education/subjects
  Future<ApiResponse<List<String>>> getSubjects() async {
    try {
      dev.log(
        '📚 Getting subjects from education API',
        name: 'EducationService',
      );

      // Check cache first
      final cachedSubjects = await _getCachedSubjects();
      if (cachedSubjects != null) {
        dev.log('✅ Returning cached subjects', name: 'EducationService');
        return ApiResponse.success(cachedSubjects);
      }

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      // Make API call
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/education/subjects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log(
        '📡 Subjects API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response follows ApiResponse pattern
        if (responseData is Map && responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'] ?? [];
          final List<String> subjects = data
              .map((item) => item.toString())
              .toList();

          // Cache the result
          await _cacheSubjects(subjects);

          dev.log(
            '✅ Successfully fetched ${subjects.length} subjects',
            name: 'EducationService',
          );
          return ApiResponse.success(subjects);
        } else {
          // Fallback for direct array response
          final List<dynamic> data = responseData as List;
          final List<String> subjects = data
              .map((item) => item.toString())
              .toList();

          await _cacheSubjects(subjects);
          return ApiResponse.success(subjects);
        }
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to fetch subjects: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log('❌ Exception in getSubjects: $e', name: 'EducationService');
      return ApiResponse.fail('Failed to fetch subjects: $e', 500);
    }
  }

  /// Get chapters for a specific subject and grade
  /// Maps to: GET /api/education/chapters?subject={subject}&grade={grade}
  Future<ApiResponse<List<String>>> getChapters({
    required String subject,
    int? grade,
  }) async {
    try {
      dev.log(
        '📖 Getting chapters for subject: $subject, grade: $grade',
        name: 'EducationService',
      );

      // Check cache first
      final cachedChapters = await _getCachedChapters(subject, grade);
      if (cachedChapters != null) {
        dev.log('✅ Returning cached chapters', name: 'EducationService');
        return ApiResponse.success(cachedChapters);
      }

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      // Build URL with query parameters
      final uri = Uri.parse('${ApiConfig.baseUrl}/education/chapters').replace(
        queryParameters: {
          'subject': subject,
          if (grade != null) 'grade': grade,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log(
        '📡 Chapters API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if response follows ApiResponse pattern
        if (responseData is Map && responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'] ?? [];
          final List<String> chapters = data
              .map((item) => item.toString())
              .toList();

          // Cache the result
          await _cacheChapters(subject, grade, chapters);

          dev.log(
            '✅ Successfully fetched ${chapters.length} chapters',
            name: 'EducationService',
          );
          return ApiResponse.success(chapters);
        } else {
          // Fallback for direct array response
          final List<dynamic> data = responseData as List;
          final List<String> chapters = data
              .map((item) => item.toString())
              .toList();

          await _cacheChapters(subject, grade, chapters);
          return ApiResponse.success(chapters);
        }
      } else if (response.statusCode == 400) {
        dev.log(
          '❌ Bad request - missing subject parameter',
          name: 'EducationService',
        );
        return ApiResponse.fail('Subject parameter is required', 400);
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to fetch chapters: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log('❌ Exception in getChapters: $e', name: 'EducationService');
      return ApiResponse.fail('Failed to fetch chapters: $e', 500);
    }
  }

  /// Generate slides for education content
  /// Maps to: POST /api/education/slides
  /// Returns promptId for tracking generation status
  Future<ApiResponse<int>> generateSlides(EducationRequest request) async {
    try {
      dev.log(
        '🎨 Generating slides for: ${request.subject} - ${request.chapter}',
        name: 'EducationService',
      );

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/education/slides'),
        headers: {
          'accept': 'text/plain',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      dev.log(
        '📡 Slides generation API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 202) {
        // Accepted
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final int promptId = responseData['data'] ?? 0;
          dev.log(
            '✅ Slides generation started, promptId: $promptId',
            name: 'EducationService',
          );

          // Clear slides cache to force refresh
          await _clearSlidesCache();

          return ApiResponse.success(
            promptId,
            'Slide generation request accepted and is being processed.',
          );
        } else {
          return ApiResponse.fail('Invalid response format', 500);
        }
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'Bad request';
        dev.log('❌ Bad request: $message', name: 'EducationService');
        return ApiResponse.fail(message, 400);
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to generate slides: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log('❌ Exception in generateSlides: $e', name: 'EducationService');
      return ApiResponse.fail('Failed to generate slides: $e', 500);
    }
  }

  /// Generate video lesson for education content
  /// Maps to: POST /api/education/videos
  /// Returns promptId for tracking generation status
  Future<ApiResponse<int>> generateVideo(EducationRequest request) async {
    try {
      dev.log(
        '🎬 Generating video for: ${request.subject} - ${request.chapter}',
        name: 'EducationService',
      );

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/education/videos'),
        headers: {
          'accept': 'text/plain',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      dev.log(
        '📡 Video generation API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 202) {
        // Accepted
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final int promptId = responseData['data'] ?? 0;
          dev.log(
            '✅ Video generation started, promptId: $promptId',
            name: 'EducationService',
          );

          // Clear videos cache to force refresh
          await _clearVideosCache();

          return ApiResponse.success(
            promptId,
            'Video generation request accepted and is being processed.',
          );
        } else {
          return ApiResponse.fail('Invalid response format', 500);
        }
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? 'Bad request';
        dev.log('❌ Bad request: $message', name: 'EducationService');
        return ApiResponse.fail(message, 400);
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to generate video: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log('❌ Exception in generateVideo: $e', name: 'EducationService');
      return ApiResponse.fail('Failed to generate video: $e', 500);
    }
  }

  /// Get all slides created by the current user
  /// Maps to: GET /api/education/slides
  Future<ApiResponse<List<SlideResponse>>> getMySlides() async {
    try {
      dev.log('🎨 Getting user slides', name: 'EducationService');

      // Check cache first
      final cachedSlides = await _getCachedSlides();
      if (cachedSlides != null) {
        dev.log('✅ Returning cached slides', name: 'EducationService');
        return ApiResponse.success(cachedSlides);
      }

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/education/slides'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log(
        '📡 My slides API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'] ?? [];
          final List<SlideResponse> slides = data
              .map((item) => SlideResponse.fromJson(item))
              .toList();

          // Cache the result
          await _cacheSlides(slides);

          dev.log(
            '✅ Successfully fetched ${slides.length} slides',
            name: 'EducationService',
          );
          return ApiResponse.success(slides);
        } else {
          return ApiResponse.fail('Invalid response format', 500);
        }
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to fetch slides: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log('❌ Exception in getMySlides: $e', name: 'EducationService');
      return ApiResponse.fail('Failed to fetch slides: $e', 500);
    }
  }

  /// Get all videos created by the current user
  /// Maps to: GET /api/education/videos
  Future<ApiResponse<List<VideoResponse>>> getMyVideos() async {
    try {
      dev.log('🎬 Getting user videos', name: 'EducationService');

      // Check cache first
      final cachedVideos = await _getCachedVideos();
      if (cachedVideos != null) {
        dev.log('✅ Returning cached videos', name: 'EducationService');
        return ApiResponse.success(cachedVideos);
      }

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/education/videos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log(
        '📡 My videos API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'] ?? [];
          final List<VideoResponse> videos = data
              .map((item) => VideoResponse.fromJson(item))
              .toList();

          // Cache the result
          await _cacheVideos(videos);

          dev.log(
            '✅ Successfully fetched ${videos.length} videos',
            name: 'EducationService',
          );
          return ApiResponse.success(videos);
        } else {
          return ApiResponse.fail('Invalid response format', 500);
        }
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to fetch videos: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log('❌ Exception in getMyVideos: $e', name: 'EducationService');
      return ApiResponse.fail('Failed to fetch videos: $e', 500);
    }
  }

  /// Get latest slide status for current user
  /// Maps to: GET /api/education/slide-status/{userId}
  Future<ApiResponse<StatusResponse>> getLatestSlideStatus() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        dev.log('❌ No user available', name: 'EducationService');
        return ApiResponse.fail('No user available. Please login.', 401);
      }

      dev.log(
        '🔍 Getting latest slide status for user: ${user.id}',
        name: 'EducationService',
      );

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/education/slide-status/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log(
        '📡 Slide status API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final statusData = responseData['data'];
          final status = StatusResponse.fromJson(statusData);

          dev.log('✅ Slide status: ${status.status}', name: 'EducationService');
          return ApiResponse.success(status);
        } else {
          return ApiResponse.fail('Invalid response format', 500);
        }
      } else if (response.statusCode == 404) {
        dev.log('ℹ️ No prompts found for user', name: 'EducationService');
        return ApiResponse.fail('No prompt found for this user', 404);
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to fetch slide status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log(
        '❌ Exception in getLatestSlideStatus: $e',
        name: 'EducationService',
      );
      return ApiResponse.fail('Failed to fetch slide status: $e', 500);
    }
  }

  /// Get latest video status for current user
  /// Maps to: GET /api/education/video-status/{userId}
  Future<ApiResponse<StatusResponse>> getLatestVideoStatus() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        dev.log('❌ No user available', name: 'EducationService');
        return ApiResponse.fail('No user available. Please login.', 401);
      }

      dev.log(
        '🔍 Getting latest video status for user: ${user.id}',
        name: 'EducationService',
      );

      // Get token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        dev.log('❌ No auth token available', name: 'EducationService');
        return ApiResponse.fail(
          'No authentication token available. Please login.',
          401,
        );
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/education/video-status/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log(
        '📡 Video status API response: ${response.statusCode}',
        name: 'EducationService',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final statusData = responseData['data'];
          final status = StatusResponse.fromJson(statusData);

          dev.log('✅ Video status: ${status.status}', name: 'EducationService');
          return ApiResponse.success(status);
        } else {
          return ApiResponse.fail('Invalid response format', 500);
        }
      } else if (response.statusCode == 404) {
        dev.log('ℹ️ No prompts found for user', name: 'EducationService');
        return ApiResponse.fail('No prompt found for this user', 404);
      } else if (response.statusCode == 401) {
        dev.log('❌ Unauthorized - token expired', name: 'EducationService');
        return ApiResponse.fail(
          'Authentication token expired. Please login again.',
          401,
        );
      } else {
        dev.log(
          '❌ API error: ${response.statusCode} - ${response.body}',
          name: 'EducationService',
        );
        return ApiResponse.fail(
          'Failed to fetch video status: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      dev.log(
        '❌ Exception in getLatestVideoStatus: $e',
        name: 'EducationService',
      );
      return ApiResponse.fail('Failed to fetch video status: $e', 500);
    }
  }

  // Cache management methods

  Future<List<String>?> _getCachedSubjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_subjectsCacheKey);

      if (cachedData != null) {
        final cacheMap = jsonDecode(cachedData);
        final timestamp = cacheMap['timestamp'] ?? 0;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (DateTime.now().difference(cacheTime).inHours <
            _cacheExpirationHours) {
          final List<dynamic> subjects = cacheMap['data'] ?? [];
          return subjects.map((s) => s.toString()).toList();
        }
      }
    } catch (e) {
      dev.log('Error reading subjects cache: $e', name: 'EducationService');
    }
    return null;
  }

  Future<void> _cacheSubjects(List<String> subjects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _subjectsCacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': subjects,
        }),
      );
    } catch (e) {
      dev.log('Error caching subjects: $e', name: 'EducationService');
    }
  }

  Future<List<String>?> _getCachedChapters(String subject, int? grade) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          '${_chaptersCacheKeyPrefix}${subject}_${grade ?? 'null'}';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final cacheMap = jsonDecode(cachedData);
        final timestamp = cacheMap['timestamp'] ?? 0;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (DateTime.now().difference(cacheTime).inHours <
            _cacheExpirationHours) {
          final List<dynamic> chapters = cacheMap['data'] ?? [];
          return chapters.map((c) => c.toString()).toList();
        }
      }
    } catch (e) {
      dev.log('Error reading chapters cache: $e', name: 'EducationService');
    }
    return null;
  }

  Future<void> _cacheChapters(
    String subject,
    int? grade,
    List<String> chapters,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          '${_chaptersCacheKeyPrefix}${subject}_${grade ?? 'null'}';
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': chapters,
        }),
      );
    } catch (e) {
      dev.log('Error caching chapters: $e', name: 'EducationService');
    }
  }

  Future<List<SlideResponse>?> _getCachedSlides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_slidesCacheKey);

      if (cachedData != null) {
        final cacheMap = jsonDecode(cachedData);
        final timestamp = cacheMap['timestamp'] ?? 0;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (DateTime.now().difference(cacheTime).inHours < _contentCacheHours) {
          final List<dynamic> slides = cacheMap['data'] ?? [];
          return slides.map((s) => SlideResponse.fromJson(s)).toList();
        }
      }
    } catch (e) {
      dev.log('Error reading slides cache: $e', name: 'EducationService');
    }
    return null;
  }

  Future<void> _cacheSlides(List<SlideResponse> slides) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _slidesCacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': slides.map((s) => s.toJson()).toList(),
        }),
      );
    } catch (e) {
      dev.log('Error caching slides: $e', name: 'EducationService');
    }
  }

  Future<List<VideoResponse>?> _getCachedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_videosCacheKey);

      if (cachedData != null) {
        final cacheMap = jsonDecode(cachedData);
        final timestamp = cacheMap['timestamp'] ?? 0;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        if (DateTime.now().difference(cacheTime).inHours < _contentCacheHours) {
          final List<dynamic> videos = cacheMap['data'] ?? [];
          return videos.map((v) => VideoResponse.fromJson(v)).toList();
        }
      }
    } catch (e) {
      dev.log('Error reading videos cache: $e', name: 'EducationService');
    }
    return null;
  }

  Future<void> _cacheVideos(List<VideoResponse> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _videosCacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': videos.map((v) => v.toJson()).toList(),
        }),
      );
    } catch (e) {
      dev.log('Error caching videos: $e', name: 'EducationService');
    }
  }

  Future<void> _clearSlidesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_slidesCacheKey);
    } catch (e) {
      dev.log('Error clearing slides cache: $e', name: 'EducationService');
    }
  }

  Future<void> _clearVideosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_videosCacheKey);
    } catch (e) {
      dev.log('Error clearing videos cache: $e', name: 'EducationService');
    }
  }

  /// Clear all education cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove subjects cache
      await prefs.remove(_subjectsCacheKey);

      // Remove slides and videos cache
      await prefs.remove(_slidesCacheKey);
      await prefs.remove(_videosCacheKey);

      // Remove all chapters cache
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_chaptersCacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }

      dev.log('✅ All education cache cleared', name: 'EducationService');
    } catch (e) {
      dev.log('❌ Error clearing education cache: $e', name: 'EducationService');
    }
  }

  /// Refresh user content (slides and videos) by clearing cache
  Future<void> refreshUserContent() async {
    await _clearSlidesCache();
    await _clearVideosCache();
    dev.log('✅ User content cache refreshed', name: 'EducationService');
  }
}
