import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';

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
  static const int _cacheExpirationHours = 24;  // Get all available subjects with caching
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
      
      // For faster development, hard-code the response when we know what subject we want
      // This can be replaced with the API call in production
      final defaultSubjects = ['GDCD']; // Default to GDCD
      
      // Cache the result
      await prefs.setString(_subjectsCacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': defaultSubjects,
      }));
      
      return defaultSubjects;
      
      /* API Call implementation:
      // Cache is invalid or doesn't exist, make API call
      final token = _authService.token;
      if (token == null) {
        throw Exception('Bạn cần đăng nhập để truy cập tính năng này');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/subjects'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token'
        },
      );

      final responseData = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.code != 200) {
        throw Exception(authResponse.message);
      }

      if (authResponse.result == null) {
        return [];
      }

      // Convert result to List<String>
      final List<dynamic> subjectsData = authResponse.result as List<dynamic>;
      final List<String> subjects = subjectsData.map((subject) => subject.toString()).toList();
      
      // Cache the result
      await prefs.setString(_subjectsCacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': subjects,
      }));
      
      return subjects;
      */
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
  // Get chapters for a specific subject and grade with caching
  Future<List<String>> getChapters({required String subject, required int grade}) async {
    try {
      // Generate a unique cache key for this subject+grade combination
      final String cacheKey = '${_chaptersCacheKeyPrefix}${subject}_${grade}';
      
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
      
      // Cache is invalid or doesn't exist, make API call
      final token = _authService.token;
      if (token == null) {
        throw Exception('Bạn cần đăng nhập để truy cập tính năng này');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chapters?subject=$subject&grade=$grade'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token'
        },
      );

      final responseData = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.code != 200) {
        throw Exception(authResponse.message);
      }

      if (authResponse.result == null) {
        return [];
      }

      // Convert result to List<String>
      final List<dynamic> chaptersData = authResponse.result as List<dynamic>;
      final List<String> chapters = chaptersData.map((chapter) => chapter.toString()).toList();
      
      // Cache the result
      await prefs.setString(cacheKey, jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': chapters,
      }));
      
      return chapters;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Generate educational content (slides or video)
  Future<Map<String, dynamic>> generateContent({
    required String subject,
    required String chapter,
    required int grade,
    required String imageCategory,
    required int template,
    required String mode,
  }) async {
    try {
      final token = _authService.token;
      if (token == null) {
        throw Exception('Bạn cần đăng nhập để truy cập tính năng này');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {
          'accept': 'text/plain',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subject': subject,
          'chapter': chapter,
          'grade': grade,
          'imageCategory': imageCategory,
          'template': template,
          'mode': mode
        }),
      );

      final responseData = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.code != 200) {
        throw Exception(authResponse.message);
      }

      if (authResponse.result == null) {
        throw Exception('Không có dữ liệu trả về từ máy chủ');
      }

      return authResponse.result as Map<String, dynamic>;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
