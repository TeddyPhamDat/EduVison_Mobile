// Generated content model to store information about created educational content
class GeneratedContent {
  final String id;
  final String title;
  final String subject;
  final String chapter;
  final int grade;
  final String contentType; // 'slides' or 'video'
  final String url;
  final DateTime createdAt;
  final bool isFavorite;

  GeneratedContent({
    required this.id,
    required this.title,
    required this.subject,
    required this.chapter,
    required this.grade,
    required this.contentType,
    required this.url,
    required this.createdAt,
    this.isFavorite = false,
  });

  // Convert to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'chapter': chapter,
      'grade': grade,
      'contentType': contentType,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  // Create from a map (for retrieving from storage)
  factory GeneratedContent.fromJson(Map<String, dynamic> json) {
    return GeneratedContent(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      chapter: json['chapter'],
      grade: json['grade'],
      contentType: json['contentType'],
      url: json['url'],
      createdAt: DateTime.parse(json['createdAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Create a copy with some fields updated
  GeneratedContent copyWith({
    String? id,
    String? title,
    String? subject,
    String? chapter,
    int? grade,
    String? contentType,
    String? url,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return GeneratedContent(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      grade: grade ?? this.grade,
      contentType: contentType ?? this.contentType,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
