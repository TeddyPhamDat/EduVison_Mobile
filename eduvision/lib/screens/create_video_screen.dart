import 'package:flutter/cupertino.dart';
import '../services/video_service.dart';
import 'video_result_screen.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({Key? key}) : super(key: key);

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  final _subjectController = TextEditingController();
  final _chapterController = TextEditingController();
  final _topicController = TextEditingController();
  
  bool _isLoading = false;
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedGrade;
  String? _selectedImageCategory;
  String? _selectedTemplate;
  String? _selectedMode;
  
  final VideoService _videoService = VideoService();
  
  // Danh sách môn học
  final List<String> _subjects = [
    'Toán học', 'Vật lý', 'Hóa học', 'Sinh học', 
    'Ngữ văn', 'Lịch sử', 'Địa lý', 'Tiếng Anh', 'Tin học',
  ];
  
  // Danh sách chương theo môn học
  final Map<String, List<String>> _chaptersBySubject = {
    'Toán học': ['Đại số', 'Hình học', 'Giải tích', 'Số học', 'Xác suất thống kê'],
    'Vật lý': ['Cơ học', 'Nhiệt học', 'Điện học', 'Quang học', 'Vật lý nguyên tử'],
    'Hóa học': ['Hóa vô cơ', 'Hóa hữu cơ', 'Hóa phân tích', 'Hóa đại cương'],
    'Sinh học': ['Sinh học tế bào', 'Di truyền học', 'Sinh thái học', 'Sinh lý học'],
  };
  
  final List<String> _grades = [
    'Lớp 1', 'Lớp 2', 'Lớp 3', 'Lớp 4', 'Lớp 5',
    'Lớp 6', 'Lớp 7', 'Lớp 8', 'Lớp 9',
    'Lớp 10', 'Lớp 11', 'Lớp 12'
  ];
  
  final List<String> _imageCategories = [
    'Chân dung', 'Phong cảnh', 'Khoa học', 'Trừu tượng'
  ];
  
  final List<String> _templates = [
    'Mẫu cơ bản', 'Mẫu chuyên nghiệp', 'Mẫu sáng tạo'
  ];
  
  final List<String> _modes = [
    'Tự động', 'Thủ công'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _chapterController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  List<String> get _availableChapters {
    if (_selectedSubject == null) return [];
    return _chaptersBySubject[_selectedSubject] ?? [];
  }

  Future<void> _createVideo() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });    try {
      final video = await _videoService.createVideo(
        subject: _selectedSubject!,
        chapter: _selectedChapter!,
        topic: _topicController.text.trim(),
        grade: _selectedGrade,
        imageCategory: _selectedImageCategory,
        template: _selectedTemplate,
        mode: _selectedMode,
      );

      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => VideoResultScreen(videoId: video.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Lỗi'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateForm() {
    if (_selectedSubject == null) {
      _showErrorDialog('Vui lòng chọn môn học');
      return false;
    }
    if (_selectedChapter == null) {
      _showErrorDialog('Vui lòng chọn chương');
      return false;
    }
    if (_topicController.text.trim().isEmpty) {
      _showErrorDialog('Vui lòng nhập chủ đề');
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Tạo video mới',
          style: TextStyle(fontFamily: '.SF Pro Display'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.videocam_fill,
                      size: 40,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Thông tin bài giảng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: '.SF Pro Display',
                  ),
                ),
                const SizedBox(height: 20),

                // Subject dropdown
                _buildDropdownField(
                  label: 'Môn học',
                  value: _selectedSubject,
                  items: _subjects,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;
                      _selectedChapter = null; // Reset chapter when subject changes
                    });
                  },
                  icon: CupertinoIcons.book_fill,
                ),
                const SizedBox(height: 16),

                // Chapter dropdown
                _buildDropdownField(
                  label: 'Chương',
                  value: _selectedChapter,
                  items: _availableChapters,
                  onChanged: (value) {
                    setState(() {
                      _selectedChapter = value;
                    });
                  },
                  icon: CupertinoIcons.bookmark_fill,
                  enabled: _selectedSubject != null,
                ),
                const SizedBox(height: 16),

                // Topic text field
                _buildTextField(
                  controller: _topicController,
                  label: 'Chủ đề',
                  placeholder: 'Nhập chủ đề bài giảng...',
                  icon: CupertinoIcons.lightbulb_fill,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Cài đặt nâng cao (tùy chọn)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: '.SF Pro Display',
                  ),
                ),
                const SizedBox(height: 16),

                // Grade dropdown
                _buildDropdownField(
                  label: 'Lớp học',
                  value: _selectedGrade,
                  items: _grades,
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value;
                    });
                  },
                  icon: CupertinoIcons.building_2_fill,
                ),
                const SizedBox(height: 16),

                // Image category dropdown
                _buildDropdownField(
                  label: 'Thể loại hình ảnh',
                  value: _selectedImageCategory,
                  items: _imageCategories,
                  onChanged: (value) {
                    setState(() {
                      _selectedImageCategory = value;
                    });
                  },
                  icon: CupertinoIcons.photo_fill,
                ),
                const SizedBox(height: 16),

                // Template dropdown
                _buildDropdownField(
                  label: 'Mẫu thiết kế',
                  value: _selectedTemplate,
                  items: _templates,
                  onChanged: (value) {
                    setState(() {
                      _selectedTemplate = value;
                    });
                  },
                  icon: CupertinoIcons.square_grid_2x2_fill,
                ),
                const SizedBox(height: 16),

                // Mode dropdown
                _buildDropdownField(
                  label: 'Chế độ tạo',
                  value: _selectedMode,
                  items: _modes,
                  onChanged: (value) {
                    setState(() {
                      _selectedMode = value;
                    });
                  },
                  icon: CupertinoIcons.settings_solid,
                ),
                const SizedBox(height: 32),

                // Create button
                SizedBox(
                  height: 54,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading ? null : _createVideo,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Tạo video',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 1,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Text',
                color: enabled ? CupertinoColors.black : CupertinoColors.systemGrey3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? CupertinoColors.systemGrey6 : CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.systemGrey4,
              width: 1,
            ),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            color: enabled ? CupertinoColors.systemGrey6 : CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(12),
            onPressed: enabled ? () => _showPicker(items, value, onChanged) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? 'Chọn $label',
                  style: TextStyle(
                    color: value == null
                        ? CupertinoColors.systemGrey
                        : (enabled ? CupertinoColors.black : CupertinoColors.systemGrey3),
                    fontSize: 16,
                    fontFamily: '.SF Pro Text',
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 20,
                  color: enabled ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(List<String> items, String? currentValue, ValueChanged<String?> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: items.map((item) {
            return CupertinoActionSheetAction(
              onPressed: () {
                onChanged(item);
                Navigator.of(context).pop();
              },
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: '.SF Pro Text',
                ),
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
              ),
            ),
          ),
        );
      },
    );
  }
}

