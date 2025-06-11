import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:eduvision/widgets/eduvision_header.dart';

class HeaderDemoScreen extends StatelessWidget {
  const HeaderDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          // Header cơ bản
          const EduVisionHeader(
            title: 'EduVision',
            showBackButton: false,
          ),
          
          const SizedBox(height: 20),
          
          // Header với nút quay lại
          const EduVisionHeader(
            title: 'Tạo Video',
            showBackButton: true,
          ),
          
          const SizedBox(height: 20),
          
          // Header với hành động
          EduVisionHeader(
            title: 'Tài liệu của tôi',
            showBackButton: true,
            actions: [
              HeaderActionButton(
                icon: CupertinoIcons.search,
                onPressed: () {},
              ),
              HeaderActionButton(
                icon: CupertinoIcons.ellipsis_vertical,
                onPressed: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Header lớn
          const EduVisionLargeHeader(
            title: 'Tạo video bài giảng',
            subtitle: 'Chọn mẫu và tùy chỉnh nội dung bài giảng của bạn',
            showBackButton: true,
          ),
          
          const Expanded(
            child: Center(
              child: Text(
                'Nội dung trang',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
