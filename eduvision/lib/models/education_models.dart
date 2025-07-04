/// Models for Education API responses and requests
/// Maps to backend DTO models in EduVision.Models.DTO

class EducationRequest {
  final String subject;
  final String chapter;
  final int? grade;
  final String imageCategory;
  final int template; // 1=default, 2=dark, 3=modern
  final String mode; // "slides" or "video"

  EducationRequest({
    required this.subject,
    required this.chapter,
    this.grade,
    this.imageCategory = '',
    this.template = 1,
    this.mode = 'slides',
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'chapter': chapter,
      'grade': grade,
      'imageCategory': imageCategory,
      'template': template,
      'mode': mode,
    };
  }

  factory EducationRequest.fromJson(Map<String, dynamic> json) {
    return EducationRequest(
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
      grade: json['grade'],
      imageCategory: json['imageCategory'] ?? '',
      template: json['template'] ?? 1,
      mode: json['mode'] ?? 'slides',
    );
  }

  @override
  String toString() {
    return 'EducationRequest(subject: $subject, chapter: $chapter, grade: $grade, imageCategory: $imageCategory, template: $template, mode: $mode)';
  }
}

class SlideResponse {
  final int slideId;
  final int? promptId;
  final String type;
  final String url;
  final String status;
  final String? promptContent;

  SlideResponse({
    required this.slideId,
    this.promptId,
    required this.type,
    required this.url,
    required this.status,
    this.promptContent,
  });

  factory SlideResponse.fromJson(Map<String, dynamic> json) {
    return SlideResponse(
      slideId: json['slideId'] ?? 0,
      promptId: json['promptId'],
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      status: json['status'] ?? '',
      promptContent: json['promptContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slideId': slideId,
      'promptId': promptId,
      'type': type,
      'url': url,
      'status': status,
      'promptContent': promptContent,
    };
  }

  @override
  String toString() {
    return 'SlideResponse(slideId: $slideId, promptId: $promptId, type: $type, url: $url, status: $status, promptContent: $promptContent)';
  }
}

class VideoResponse {
  final int generateVideoId;
  final String status;
  final DateTime? createdAt;
  final String? videoUrl;
  final String? promptContent;

  VideoResponse({
    required this.generateVideoId,
    required this.status,
    this.createdAt,
    this.videoUrl,
    this.promptContent,
  });

  factory VideoResponse.fromJson(Map<String, dynamic> json) {
    return VideoResponse(
      generateVideoId: json['generateVideoId'] ?? 0,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      videoUrl: json['videoUrl'],
      promptContent: json['promptContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generateVideoId': generateVideoId,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'videoUrl': videoUrl,
      'promptContent': promptContent,
    };
  }

  @override
  String toString() {
    return 'VideoResponse(generateVideoId: $generateVideoId, status: $status, createdAt: $createdAt, videoUrl: $videoUrl, promptContent: $promptContent)';
  }
}

class StatusResponse {
  final String status;
  final String? url;

  StatusResponse({required this.status, this.url});

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(status: json['status'] ?? '', url: json['url']);
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'url': url};
  }

  @override
  String toString() {
    return 'StatusResponse(status: $status, url: $url)';
  }
}

/// Templates available for education content generation
enum EducationTemplate {
  defaultTemplate(1, 'Default'),
  dark(2, 'Dark'),
  modern(3, 'Modern');

  const EducationTemplate(this.value, this.label);

  final int value;
  final String label;

  static EducationTemplate fromValue(int value) {
    return EducationTemplate.values.firstWhere(
      (template) => template.value == value,
      orElse: () => EducationTemplate.defaultTemplate,
    );
  }
}

/// Modes available for education content generation
enum EducationMode {
  slides('slides', 'Slides Only'),
  video('video', 'Video Lesson');

  const EducationMode(this.value, this.label);

  final String value;
  final String label;

  static EducationMode fromValue(String value) {
    return EducationMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => EducationMode.slides,
    );
  }
}

/// Content generation status
enum ContentStatus {
  processing('Processing'),
  completed('Completed'),
  failed('Failed'),
  pending('Pending');

  const ContentStatus(this.value);

  final String value;

  static ContentStatus fromValue(String value) {
    return ContentStatus.values.firstWhere(
      (status) => status.value.toLowerCase() == value.toLowerCase(),
      orElse: () => ContentStatus.processing,
    );
  }

  bool get isCompleted => this == ContentStatus.completed;
  bool get isProcessing => this == ContentStatus.processing;
  bool get isFailed => this == ContentStatus.failed;
  bool get isPending => this == ContentStatus.pending;
}
