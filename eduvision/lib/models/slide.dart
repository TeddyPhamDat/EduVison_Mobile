class Slide {
  // New API format fields
  final int? slideId;
  final int? promptId;
  final String? type;
  final String? url;
  final String? status;
  final String? promptContent;
  
  // Old format fields
  final String? id;
  final String? title;
  final String? content;
  final String? imageUrl;
  final int? slideNumber;

  Slide({
    this.slideId,
    this.promptId,
    this.type,
    this.url,
    this.status,
    this.promptContent,
    // Old format parameters
    this.id,
    this.title,
    this.content,
    this.imageUrl,
    this.slideNumber,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    // Check if it's the new API format
    if (json.containsKey('slideId')) {
      return Slide(
        slideId: json['slideId'] as int?,
        promptId: json['promptId'] as int?,
        type: json['type'] as String?,
        url: json['url'] as String?,
        status: json['status'] as String?,
        promptContent: json['promptContent'] as String?,
      );
    } else {
      // Old format
      return Slide(
        id: json['id'] as String?,
        title: json['title'] as String?,
        content: json['content'] as String?,
        imageUrl: json['imageUrl'] as String?,
        slideNumber: json['slideNumber'] as int?,
      );
    }
  }

  Map<String, dynamic> toJson() {
    if (slideId != null) {
      // API model format
      return {
        'slideId': slideId,
        'promptId': promptId,
        'type': type,
        'url': url,
        'status': status,
        'promptContent': promptContent,
      };
    } else {
      // Local model format
      return {
        'id': id,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'slideNumber': slideNumber,
      };
    }
  }
}
