import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/generated_content.dart';

class ContentStorageService {
  // Singleton pattern
  static final ContentStorageService _instance = ContentStorageService._internal();
  
  factory ContentStorageService() => _instance;
  
  ContentStorageService._internal();
  
  // Storage keys
  static const String _contentHistoryKey = 'content_history';
  static const String _favoriteContentKey = 'favorite_content';
  
  // UUID generator for content IDs
  final Uuid _uuid = const Uuid();

  // Save generated content to history
  Future<GeneratedContent> saveContent({
    required String subject,
    required String chapter,
    required int grade,
    required String contentType,
    required String url,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create a new content object
    final content = GeneratedContent(
      id: _uuid.v4(),
      title: '$subject - $chapter',
      subject: subject,
      chapter: chapter,
      grade: grade,
      contentType: contentType,
      url: url,
      createdAt: DateTime.now(),
    );
    
    // Get existing content history
    final List<GeneratedContent> history = await getContentHistory();
    
    // Add new content to the beginning of the list
    history.insert(0, content);
    
    // Save updated history
    await prefs.setString(_contentHistoryKey, 
      jsonEncode(history.map((content) => content.toJson()).toList())
    );
    
    return content;
  }
  
  // Get content history
  Future<List<GeneratedContent>> getContentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_contentHistoryKey);
    
    if (historyJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> historyData = jsonDecode(historyJson);
      return historyData
        .map((item) => GeneratedContent.fromJson(item))
        .toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }
  
  // Toggle favorite status for a content
  Future<GeneratedContent> toggleFavorite(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing content history
    final List<GeneratedContent> history = await getContentHistory();
    
    // Find the content by ID
    final int index = history.indexWhere((content) => content.id == contentId);
    if (index == -1) {
      throw Exception('Content not found');
    }
    
    // Toggle favorite status
    final updatedContent = history[index].copyWith(
      isFavorite: !history[index].isFavorite,
    );
    
    // Update the history
    history[index] = updatedContent;
    
    // Save updated history
    await prefs.setString(_contentHistoryKey, 
      jsonEncode(history.map((content) => content.toJson()).toList())
    );
    
    // Update favorites list
    await _updateFavoritesList();
    
    return updatedContent;
  }
  
  // Get favorite content
  Future<List<GeneratedContent>> getFavoriteContent() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_favoriteContentKey);
    
    if (favoritesJson == null) {
      return [];
    }
    
    try {
      final List<dynamic> favoritesData = jsonDecode(favoritesJson);
      return favoritesData
        .map((item) => GeneratedContent.fromJson(item))
        .toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }
  
  // Update the favorites list based on content history
  Future<void> _updateFavoritesList() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all content
    final List<GeneratedContent> history = await getContentHistory();
    
    // Filter to get only favorites
    final List<GeneratedContent> favorites = history
      .where((content) => content.isFavorite)
      .toList();
    
    // Save favorites list
    await prefs.setString(_favoriteContentKey, 
      jsonEncode(favorites.map((content) => content.toJson()).toList())
    );
  }
  
  // Delete content from history
  Future<void> deleteContent(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing content history
    final List<GeneratedContent> history = await getContentHistory();
    
    // Remove the content with the given ID
    history.removeWhere((content) => content.id == contentId);
    
    // Save updated history
    await prefs.setString(_contentHistoryKey, 
      jsonEncode(history.map((content) => content.toJson()).toList())
    );
    
    // Update favorites list
    await _updateFavoritesList();
  }
  
  // Clear all content history
  Future<void> clearContentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contentHistoryKey);
    await prefs.remove(_favoriteContentKey);
  }
}
