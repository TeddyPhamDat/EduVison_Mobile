class Slide {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final int slideNumber;

  Slide({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.slideNumber,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      slideNumber: json['slideNumber'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'slideNumber': slideNumber,
    };
  }
}
