import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class EducationService {
  // Singleton pattern
  static final EducationService _instance = EducationService._internal();

  factory EducationService() => _instance;

  EducationService._internal();

  // Auth service for getting token
  final AuthService _authService = AuthService();

  // Cache keys
  static const String _subjectsCacheKey = 'subjects_cache';
  static const String _chaptersCacheKeyPrefix = 'chapters_cache_';

  // Cache expiration in hours
  static const int _cacheExpirationHours = 24;

  // Get all available subjects with caching
  Future<List<String>> getSubjects() async {
    try {
      // Check if we have cached subjects first
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_subjectsCacheKey);

      if (cachedData != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cachedData);
        final int timestamp = cacheMap['timestamp'] ?? 0;
        final List<dynamic> subjects = cacheMap['data'] ?? [];

        // Check if cache is still valid (less than 24 hours old)
        final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp,
        );
        final DateTime now = DateTime.now();
        if (now.difference(cacheTime).inHours < _cacheExpirationHours) {
          return subjects.map((subject) => subject.toString()).toList();
        }
      }

      // Get authentication token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception(
          'Không thể lấy token xác thực. Vui lòng đăng nhập lại.',
        );
      }

      // Make API call
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Education/subjects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> subjects = data
            .map((item) => item.toString())
            .toList();

        // Cache the result
        await prefs.setString(
          _subjectsCacheKey,
          jsonEncode({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': subjects,
          }),
        );

        return subjects;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception(
          'Lỗi khi lấy danh sách môn học: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getSubjects: $e');
      throw Exception('Không thể lấy danh sách môn học: $e');
    }
  }

  // Get chapters for a subject and grade with caching
  Future<List<String>> getChapters({
    required String subject,
    required int grade,
  }) async {
    try {
      // Create cache key based on subject and grade
      final String cacheKey = '${_chaptersCacheKeyPrefix}${subject}_$grade';

      // Check if we have cached chapters first
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final Map<String, dynamic> cacheMap = jsonDecode(cachedData);
        final int timestamp = cacheMap['timestamp'] ?? 0;
        final List<dynamic> chapters = cacheMap['data'] ?? [];

        // Check if cache is still valid (less than 24 hours old)
        final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(
          timestamp,
        );
        final DateTime now = DateTime.now();
        if (now.difference(cacheTime).inHours < _cacheExpirationHours) {
          return chapters.map((chapter) => chapter.toString()).toList();
        }
      }

      // Get authentication token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception(
          'Không thể lấy token xác thực. Vui lòng đăng nhập lại.',
        );
      }

      // Make API call
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/Education/chapters?subject=$subject&grade=$grade',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> chapters = data
            .map((item) => item.toString())
            .toList();

        // Cache the result
        await prefs.setString(
          cacheKey,
          jsonEncode({
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': chapters,
          }),
        );

        return chapters;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception(
          'Lỗi khi lấy danh sách bài học: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getChapters: $e');
      throw Exception('Không thể lấy danh sách bài học: $e');
    }
  }

  // Generate educational content
  Future<Map<String, dynamic>> generateContent({
    required String subject,
    required String chapter,
    required int grade,
    required String imageCategory,
    required int template,
    required String mode,
  }) async {
    try {
      // Get authentication token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception(
          'Không thể lấy token xác thực. Vui lòng đăng nhập lại.',
        );
      }

      final requestBody = {
        'subject': subject,
        'chapter': chapter,
        'grade': grade, // Send as number, not string
        'imageCategory': imageCategory,
        'template': template,
        'mode': mode,
      };

      print('Generating content with request: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/education/videos'),
        headers: {
          'accept': 'text/plain', // Match backend expectation
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 202) {
        // Backend returns 202 Accepted for async processing
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 200) {
        // Fallback for immediate response
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception(
          'Lỗi khi tạo nội dung: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in generateContent: $e');
      throw Exception('Không thể tạo nội dung: $e');
    }
  }

  // Generate slides content
  Future<Map<String, dynamic>> generateSlides({
    required String subject,
    required String chapter, // "Bài 1", "Bài 2", "Bài 3"
    required int grade,
    required String imageCategory,
    required int template,
    String mode = 'slides',
  }) async {
    try {
      // Get authentication token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception(
          'Không thể lấy token xác thực. Vui lòng đăng nhập lại.',
        );
      }

      final requestBody = {
        'subject': subject,
        'chapter':
            chapter, // Send exactly as provided: "Bài 1", "Bài 2", "Bài 3"
        'grade': grade, // Send as number, not string
        'imageCategory': imageCategory,
        'template': template,
        'mode': mode,
      };

      print('Generating slides with request: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/education/slides'),
        headers: {
          'accept': 'text/plain', // Match backend expectation
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 202) {
        // Backend returns 202 Accepted for async processing
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 200) {
        // Fallback for immediate response
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception(
          'Lỗi khi tạo slides: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in generateSlides: $e');
      throw Exception('Không thể tạo slides: $e');
    }
  }

  // Get user's slides
  Future<List<Map<String, dynamic>>> getMySlides() async {
    try {
      // Get authentication token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Make HTTP request
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/education/slides'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my slides response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Handle both response formats: new format with "result" and old format with "data"
        if (responseData['code'] == 200 || responseData['isSuccess'] == true) {
          final List<dynamic> slidesData =
              responseData['result'] ?? responseData['data'] ?? [];
          return slidesData
              .map((slide) => Map<String, dynamic>.from(slide))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get slides');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error getting slides: $e');
      rethrow;
    }
  }

  // Get user's videos
  Future<List<Map<String, dynamic>>> getMyVideos() async {
    try {
      // Get authentication token
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Make HTTP request
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/education/videos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get my videos response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Handle both response formats: new format with "result" and old format with "data"
        if (responseData['code'] == 200 || responseData['isSuccess'] == true) {
          final List<dynamic> videosData =
              responseData['result'] ?? responseData['data'] ?? [];
          return videosData
              .map((video) => Map<String, dynamic>.from(video))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get videos');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error getting videos: $e');
      rethrow;
    }
  }

  /// Get all slides created by the authenticated user
  Future<List<Map<String, dynamic>>> getUserSlides() async {
    try {
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/education/slides'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['result'] != null) {
          final List<dynamic> slidesData = responseData['result'];
          return slidesData
              .map((slide) => Map<String, dynamic>.from(slide))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get slides');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error getting user slides: $e');
      rethrow;
    }
  }

  /// Get all videos created by the authenticated user
  Future<List<Map<String, dynamic>>> getUserVideos() async {
    try {
      final token = _authService.token;
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/education/videos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['code'] == 200 && responseData['result'] != null) {
          final List<dynamic> videosData = responseData['result'];
          return videosData
              .map((video) => Map<String, dynamic>.from(video))
              .toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to get videos');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error getting user videos: $e');
      rethrow;
    }
  }

  /// Get both slides and videos for content history
  Future<Map<String, dynamic>> getUserContent() async {
    try {
      final slides = await getUserSlides();
      final videos = await getUserVideos();

      return {'slides': slides, 'videos': videos};
    } catch (e) {
      print('Error getting user content: $e');
      throw Exception('Error fetching user content: $e');
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove subjects cache
      await prefs.remove(_subjectsCacheKey);

      // Remove all chapters cache (we need to iterate through all keys)
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_chaptersCacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
