import 'package:flutter/cupertino.dart';

class SubjectFilterChip extends StatelessWidget {
  final String subject;
  final bool isSelected;
  final Function(String) onSelected;

  const SubjectFilterChip({
    Key? key,
    required this.subject,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => onSelected(subject),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? CupertinoColors.systemBlue 
                : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            subject,
            style: TextStyle(
              color: isSelected 
                  ? CupertinoColors.white 
                  : CupertinoColors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class SubjectFilterBar extends StatelessWidget {
  final List<String> subjects;
  final String? selectedSubject;
  final Function(String?) onSubjectSelected;

  const SubjectFilterBar({
    Key? key,
    required this.subjects,
    this.selectedSubject,
    required this.onSubjectSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Thêm tùy chọn "Tất cả" vào đầu danh sách
    final allSubjects = ['Tất cả', ...subjects];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allSubjects.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final subject = allSubjects[index];
          final isSelected = index == 0 
              ? selectedSubject == null
              : subject == selectedSubject;
          
          return SubjectFilterChip(
            subject: subject,
            isSelected: isSelected,
            onSelected: (selected) {
              if (index == 0) {
                // Nếu chọn "Tất cả", đặt giá trị null
                onSubjectSelected(null);
              } else {
                onSubjectSelected(selected);
              }
            },
          );
        },
      ),
    );
  }
}

