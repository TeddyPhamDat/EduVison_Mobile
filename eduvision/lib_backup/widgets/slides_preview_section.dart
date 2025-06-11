import 'package:flutter/material.dart';
import '../models/lecture_video.dart';
import '../models/slide.dart';

class SlidesPreviewSection extends StatefulWidget {
  final LectureVideo video;
  
  const SlidesPreviewSection({
    Key? key,
    required this.video,
  }) : super(key: key);

  @override
  State<SlidesPreviewSection> createState() => _SlidesPreviewSectionState();
}

class _SlidesPreviewSectionState extends State<SlidesPreviewSection> {
  int _currentSlideIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    if (widget.video.slides == null || widget.video.slides!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        
        Text(
          'Slides bài giảng',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _buildSlideViewer(),
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentSlideIndex > 0
                ? () {
                    setState(() {
                      _currentSlideIndex--;
                    });
                  }
                : null,
            ),
            Text(
              'Slide ${_currentSlideIndex + 1} / ${widget.video.slides!.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentSlideIndex < widget.video.slides!.length - 1
                ? () {
                    setState(() {
                      _currentSlideIndex++;
                    });
                  }
                : null,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSlideViewer() {
    final currentSlide = widget.video.slides![_currentSlideIndex];
    
    return Stack(
      children: [
        if (currentSlide.imageUrl != null)
          Center(
            child: Image.network(
              currentSlide.imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Text(
            currentSlide.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              backgroundColor: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currentSlide.content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
