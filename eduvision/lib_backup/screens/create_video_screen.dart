import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';
import '../services/video_service.dart';
import '../widgets/subject_dropdown.dart';
import 'video_result_screen.dart';
import '../utils/app_theme.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({Key? key}) : super(key: key);

  @override
  State<CreateVideoScreen> createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _chapterController = TextEditingController();
  final _topicController = TextEditingController();
  
  bool _isLoading = false;
  late AnimationController _loadingController;
  
  final VideoService _videoService = VideoService();
  
  // Danh sách môn học gợi ý
  final List<String> _subjects = [
    'Toán học',
    'Vật lý',
    'Hóa học',
    'Sinh học',
    'Ngữ văn',
    'Lịch sử',
    'Địa lý',
    'Tiếng Anh',
    'Tin học',
  ];
  
  // Danh sách chương theo môn học
  final Map<String, List<String>> _chaptersBySubject = {
    'Toán học': ['Đại số', 'Hình học', 'Giải tích', 'Số học', 'Xác suất thống kê'],
    'Vật lý': ['Cơ học', 'Nhiệt học', 'Điện học', 'Quang học', 'Vật lý nguyên tử'],
    'Hóa học': ['Hóa vô cơ', 'Hóa hữu cơ', 'Hóa phân tích', 'Hóa đại cương'],
    'Sinh học': ['Sinh học tế bào', 'Di truyền học', 'Sinh thái học', 'Sinh lý học'],
  };
  
  // Danh sách lớp học
  final List<String> _grades = [
    'Lớp 1',
    'Lớp 2',
    'Lớp 3',
    'Lớp 4',
    'Lớp 5',
    'Lớp 6',
    'Lớp 7',
    'Lớp 8',
    'Lớp 9',
    'Lớp 10',
    'Lớp 11',
    'Lớp 12',
    'Đại học',
  ];
  
  // Danh sách thể loại hình ảnh
  final List<String> _imageCategories = [
    'Hoạt hình',
    'Thực tế',
    'Đồ họa 3D',
    'Bản vẽ',
    'Minh họa',
  ];
  
  // Danh sách mẫu
  final List<String> _templates = [
    'Tiêu chuẩn',
    'Trẻ em',
    'Hiện đại',
    'Khoa học',
    'Sáng tạo',
  ];
  
  // Danh sách chế độ
  final List<String> _modes = [
    'Video và Slide',
    'Chỉ Video',
    'Chỉ Slide',
  ];
  
  String? _selectedSubject;
  String? _selectedChapter;
  String? _selectedGrade;
  String? _selectedImageCategory;
  String? _selectedTemplate;
  String? _selectedMode;
  List<String> _availableChapters = [];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _chapterController.dispose();
    _topicController.dispose();
    _loadingController.dispose();
    super.dispose();
  }
  
  void _onSubjectChanged(String? subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedChapter = null;
      
      if (subject != null && _chaptersBySubject.containsKey(subject)) {
        _availableChapters = _chaptersBySubject[subject]!;
      } else {
        _availableChapters = [];
      }
      
      if (subject != null) {
        _subjectController.text = subject;
      }
    });
  }
  
  void _onChapterChanged(String? chapter) {
    setState(() {
      _selectedChapter = chapter;
      if (chapter != null) {
        _chapterController.text = chapter;
      }
    });
  }
  
  void _onGradeChanged(String? grade) {
    setState(() {
      _selectedGrade = grade;
    });
  }
  
  void _onImageCategoryChanged(String? category) {
    setState(() {
      _selectedImageCategory = category;
    });
  }
  
  void _onTemplateChanged(String? template) {
    setState(() {
      _selectedTemplate = template;
    });
  }
  
  void _onModeChanged(String? mode) {
    setState(() {
      _selectedMode = mode;
    });
  }
  Future<void> _createVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final video = await _videoService.createVideo(
        subject: _subjectController.text.trim(),
        chapter: _chapterController.text.trim(),
        topic: _topicController.text.trim(),
        grade: _selectedGrade,
        imageCategory: _selectedImageCategory,
        template: _selectedTemplate,
        mode: _selectedMode,
      );
      
      if (mounted) {
        // Chuyển sang màn hình xử lý video
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoResultScreen(videoId: video.id),
          ),
        ).then((_) {
          // Đặt lại form khi quay lại
          setState(() {
            _subjectController.clear();
            _chapterController.clear();
            _topicController.clear();
            _selectedGrade = null;
            _selectedImageCategory = null;
            _selectedTemplate = null;
            _selectedMode = null;
          });
        });
      }
    } catch (e) {
      // Xử lý lỗi nếu có
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return Scaffold(
      appBar: CustomHeader(
        title: 'Tạo video bài giảng',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                const Text(
                  'Tạo video bài giảng',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Mô tả
                const Text(
                  'Chỉ cần 3 bước đơn giản để có video bài giảng hoàn chỉnh',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(height: 32),
                  // Khóa học
                AnimatedSubjectDropdown(
                  value: _selectedSubject,
                  onChanged: _onSubjectChanged,
                  items: _subjects,
                  labelText: 'Khóa học',
                  hintText: 'Chọn khóa học',
                  prefixIcon: Icons.book,
                  delay: const Duration(milliseconds: 100),
                ),
                const SizedBox(height: 16),
                
                // Chương
                AnimatedSubjectDropdown(
                  value: _selectedChapter,
                  onChanged: _onChapterChanged,
                  items: _availableChapters.isEmpty 
                      ? ['Nhập tên chương...']
                      : _availableChapters,
                  labelText: 'Chương học',
                  hintText: _selectedSubject == null
                      ? 'Vui lòng chọn khóa học trước'
                      : 'Chọn chương học',
                  prefixIcon: Icons.bookmark,
                  isRequired: true,
                  delay: const Duration(milliseconds: 200),
                ),                const SizedBox(height: 16),
                  // Kiến thức
                _buildTextField(
                  controller: _topicController,
                  labelText: 'Chọn kiến thức/slide',
                  hintText: 'Nhập tiêu đề kiến thức',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập kiến thức';
                    }
                    return null;
                  },
                  isIOS: isIOS,
                ),
                
                const SizedBox(height: 16),
                
                // Lớp học
                AnimatedSubjectDropdown(
                  value: _selectedGrade,
                  onChanged: (grade) {
                    setState(() {
                      _selectedGrade = grade;
                    });
                  },
                  items: _grades,
                  labelText: 'Lớp học',
                  hintText: 'Chọn lớp học',
                  prefixIcon: Icons.school,
                  delay: const Duration(milliseconds: 300),
                ),
                
                const SizedBox(height: 16),
                
                // Thể loại hình ảnh
                AnimatedSubjectDropdown(
                  value: _selectedImageCategory,
                  onChanged: (category) {
                    setState(() {
                      _selectedImageCategory = category;
                    });
                  },
                  items: _imageCategories,
                  labelText: 'Thể loại hình ảnh',
                  hintText: 'Chọn thể loại hình ảnh',
                  prefixIcon: Icons.image,
                  delay: const Duration(milliseconds: 400),
                ),
                
                const SizedBox(height: 16),
                
                // Mẫu
                AnimatedSubjectDropdown(
                  value: _selectedTemplate,
                  onChanged: (template) {
                    setState(() {
                      _selectedTemplate = template;
                    });
                  },
                  items: _templates,
                  labelText: 'Mẫu',
                  hintText: 'Chọn mẫu',
                  prefixIcon: Icons.style,
                  delay: const Duration(milliseconds: 500),
                ),
                
                const SizedBox(height: 16),
                
                // Chế độ
                AnimatedSubjectDropdown(
                  value: _selectedMode,
                  onChanged: (mode) {
                    setState(() {
                      _selectedMode = mode;
                    });
                  },
                  items: _modes,
                  labelText: 'Chế độ xuất bản',
                  hintText: 'Chọn chế độ xuất bản',
                  prefixIcon: Icons.settings,
                  delay: const Duration(milliseconds: 600),
                ),
                
                const SizedBox(height: 40),
                  // Create Video Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isLoading
                      ? _buildLoadingButton()
                      : ElevatedButton.icon(
                          onPressed: _createVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.video_library),
                          label: const Text(
                            'Tạo video bài giảng',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingButton() {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade300,
        disabledBackgroundColor: Colors.deepPurple.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingController.value * 2 * 3.14159,
                  child: child,
                );
              },
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Đang xử lý...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool isIOS,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(
        fontSize: isIOS ? 16 : 16,      ),
    );
  }
}
