import 'package:flutter/cupertino.dart';
import '../models/lecture_video.dart';
import '../utils/app_utils.dart';

class VideoCard extends StatelessWidget {
  final LectureVideo video;
  final VoidCallback onTap;
  final bool animate;
  final int index;

  const VideoCard({
    Key? key,
    required this.video,
    required this.onTap,
    this.animate = true,
    this.index = 0,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.play_circle,
                  size: 50,
                  color: video.isCompleted ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                ),
              ),
            ),
            
                        Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Details
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.book,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        video.subject,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        CupertinoIcons.doc_text,
                        size: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video.topic,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: video.isCompleted
                              ? CupertinoColors.systemGreen.withOpacity(0.2)
                              : CupertinoColors.systemOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              video.isCompleted
                                  ? CupertinoIcons.checkmark_circle
                                  : CupertinoIcons.clock,
                              size: 14,
                              color: video.isCompleted
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video.isCompleted ? 'Hoàn thành' : 'Đang xử lý',
                              style: TextStyle(
                                fontSize: 12,
                                color: video.isCompleted
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Date
                      Text(
                        AppUtils.getRelativeTime(video.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!animate) {
      return card;
    }

    // Apply animation
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

