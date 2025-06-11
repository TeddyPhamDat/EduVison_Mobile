import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EducationService {
  // Singleton pattern
  static final EducationService _instance = EducationService._internal();
  
  factory EducationService() => _instance;
  
  EducationService._internal();

  // API base URL
  static const String _baseUrl = 'https://eduvision-api-accscqa6f5d6dha5.southeastasia-01.azurewebsites.net/api/Education';

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
        final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final DateTime now = DateTime.now();
        if (now.difference(cacheTime).inHours < _cacheExpirationHours) {
          return subjects.map((subject) => subject.toString()).toList();
        }
      }
      
      // Get authentication token
      final token = await _authService.getCurrentToken();
      if (token == null || token.isEmpty) {
        throw Exception('Không thể lấy token xác thực. Vui lòng đăng nhập lại.');
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$_baseUrl/subjects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> subjects = data.map((item) => item.toString()).toList();
        
        // Cache the result
        await prefs.setString(_subjectsCacheKey, jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': subjects,
        }));
        
        return subjects;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi khi lấy danh sách môn học: ${response.statusCode}');
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
        final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final DateTime now = DateTime.now();
        if (now.difference(cacheTime).inHours < _cacheExpirationHours) {
          return chapters.map((chapter) => chapter.toString()).toList();
        }
      }
      
      // Get authentication token
      final token = await _authService.getCurrentToken();
      if (token == null || token.isEmpty) {
        throw Exception('Không thể lấy token xác thực. Vui lòng đăng nhập lại.');
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$_baseUrl/chapters?subject=$subject&grade=$grade'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> chapters = data.map((item) => item.toString()).toList();
        
        // Cache the result
        await prefs.setString(cacheKey, jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': chapters,
        }));
        
        return chapters;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi khi lấy danh sách bài học: ${response.statusCode}');
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
      final token = await _authService.getCurrentToken();
      if (token == null || token.isEmpty) {
        throw Exception('Không thể lấy token xác thực. Vui lòng đăng nhập lại.');
      }

      final requestBody = {
        'subject': subject,
        'chapter': chapter,
        'grade': grade.toString(),
        'imageCategory': imageCategory,
        'template': template,
        'mode': mode,
      };

      print('Generating content with request: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi khi tạo nội dung: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in generateContent: $e');
      throw Exception('Không thể tạo nội dung: $e');
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
