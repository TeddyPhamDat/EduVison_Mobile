import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';

/// Special implementation of EducationService for GDCD subject
/// This implementation focuses on optimizing the app for the GDCD subject
/// and grade 12, which is the primary use case as demonstrated in the API example.
class GDCDEducationService {
  // Singleton pattern
  static final GDCDEducationService _instance = GDCDEducationService._internal();
  
  factory GDCDEducationService() => _instance;
  
  GDCDEducationService._internal();

  // API base URL
  static const String _baseUrl = 'https://eduvision-api-accscqa6f5d6dha5.southeastasia-01.azurewebsites.net/api/Education';

  // Auth service for getting token
  final AuthService _authService = AuthService();
  
  // Cache keys
  static const String _subjectsCacheKey = 'gdcd_subjects_cache';
  static const String _chaptersCacheKeyPrefix = 'gdcd_chapters_cache_';
  
  // Cache expiration in hours
  static const int _cacheExpirationHours = 24;
  
  // Get GDCD subject
  Future<List<String>> getSubjects() async {
    try {
      // For the example, we're going to hard-code GDCD as the only subject
      return ['GDCD'];
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
  
  // Get chapters for GDCD and grade 12
  Future<List<String>> getChapters({required String subject, required int grade}) async {
    try {
      // Check if subject is GDCD and grade is 12
      if (subject != 'GDCD' || grade != 12) {
        return [];
      }
      
      // Check if we have cached chapters first
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = '${_chaptersCacheKeyPrefix}${subject}_${grade}';
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
      
      // For GDCD grade 12, we know the chapters (based on your example)
      final List<String> chapters = ['Bài 1', 'Bài 2', 'Bài 3'];
      
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

      // Make the API call to generate content
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
          'mode': mode.toLowerCase()
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

      // The API response contains both slideUrl and videoUrl regardless of the mode
      // This is based on the example response you provided
      return authResponse.result as Map<String, dynamic>;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
