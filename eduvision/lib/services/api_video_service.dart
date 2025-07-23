import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiVideo {
  final int generateVideoId;
  final String status;
  final DateTime createdAt;
  final String? videoUrl;
  final String promptContent;

  ApiVideo({
    required this.generateVideoId,
    required this.status,
    required this.createdAt,
    this.videoUrl,
    required this.promptContent,
  });

  factory ApiVideo.fromJson(Map<String, dynamic> json) {
    return ApiVideo(
      generateVideoId: json['generateVideoId'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      videoUrl: json['videoUrl'] as String?,
      promptContent: json['promptContent'] as String,
    );
  }
}

class ApiVideoService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>> fetchVideos({int page = 1, int pageSize = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Bạn cần đăng nhập để xem danh sách video');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/videos?page=$page&pageSize=$pageSize'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['code'] == 200 && data['result'] != null) {
        final result = data['result'];
        final List<dynamic> videosData = result['data'];
        
        return {
          'videos': videosData.map((videoData) => ApiVideo.fromJson(videoData)).toList(),
          'page': result['page'],
          'totalPages': result['totalPages'],
          'hasNextPage': result['hasNextPage'],
          'hasPreviousPage': result['hasPreviousPage'],
        };
      } else {
        throw Exception(data['message'] ?? 'Không thể tải danh sách video');
      }
    } else {
      throw Exception('Lỗi ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createVideo({
    required String subject,
    required String chapter,
    required int grade,
    required String imageCategory,
    required int template,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final fcmToken = prefs.getString('fcm_token');

    if (token == null) {
      throw Exception('Bạn cần đăng nhập để tạo video');
    }
    
    // Video generation request prepared

    final response = await http.post(
      Uri.parse('$baseUrl/api/videos'),
      headers: {
        'accept': 'text/plain',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'X-FCM-Token': fcmToken ?? '', // Add FCM token to header
      },
      body: jsonEncode({
        'subject': subject,
        'chapter': chapter,
        'grade': grade,
        'imageCategory': imageCategory,
        'template': template,
        'fcmToken': fcmToken, // Also include in body for compatibility
      }),
    );

    // Process response - support both 200 and 202 status codes
    if (response.statusCode == 200 || response.statusCode == 202) {
      final data = jsonDecode(response.body);
      
      // Check if we have a successful response code (either 200 or 202)
      if ((data['code'] == 200 || data['code'] == 202) && data['result'] != null) {
        // Video request successful
        // Convert the result to a Map<String, dynamic> if it's not already
        if (data['result'] is int) {
          // If result is just an ID, wrap it in a map
          return {'generateVideoId': data['result']};
        } else {
          return data['result'];
        }
      } else {
        throw Exception(data['message'] ?? 'Không thể tạo video');
      }
    } else {
      throw Exception('Lỗi ${response.statusCode}: ${response.body}');
    }
  }
}
