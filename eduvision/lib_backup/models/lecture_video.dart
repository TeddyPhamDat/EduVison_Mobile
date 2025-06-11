import 'slide.dart';

class LectureVideo {
  final String id;
  final String title;
  final String subject;
  final String chapter;
  final String topic;
  final String? videoUrl;
  final String? slideUrl;
  final List<Slide>? slides;
  final DateTime createdAt;
  final bool isCompleted;
  final String? grade;
  final String? imageCategory;
  final String? template;
  final String? mode;

  LectureVideo({
    required this.id,
    required this.title,
    required this.subject,
    required this.chapter,
    required this.topic,
    this.videoUrl,
    this.slideUrl,
    this.slides,
    required this.createdAt,
    this.isCompleted = false,
    this.grade,
    this.imageCategory,
    this.template,
    this.mode,
  });

  factory LectureVideo.fromJson(Map<String, dynamic> json) {
    List<Slide>? slidesList;
    if (json['slides'] != null) {
      slidesList = (json['slides'] as List)
          .map((slideJson) => Slide.fromJson(slideJson as Map<String, dynamic>))
          .toList();
    }

    return LectureVideo(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      chapter: json['chapter'] as String,
      topic: json['topic'] as String,
      videoUrl: json['videoUrl'] as String?,
      slideUrl: json['slideUrl'] as String?,
      slides: slidesList,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      grade: json['grade'] as String?,
      imageCategory: json['imageCategory'] as String?,
      template: json['template'] as String?,
      mode: json['mode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'videoUrl': videoUrl,
      'slideUrl': slideUrl,
      'slides': slides?.map((slide) => slide.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'grade': grade,
      'imageCategory': imageCategory,
      'template': template,
      'mode': mode,
    };
  }
}
