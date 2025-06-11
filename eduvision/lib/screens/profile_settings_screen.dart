import 'package:flutter/cupertino.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/eduvision_header.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  
  final AuthService _authService = AuthService();
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.name;
      _emailController.text = _currentUser!.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  Future<void> _updateProfile() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      // Giả lập cập nhật profile vì API chưa có method này
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }
  
  void _showSuccessDialog() {
    setState(() {
      _isLoading = false;
    });
    
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Cập nhật thành công'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFF10B981),
                size: 50,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thông tin cá nhân của bạn đã được cập nhật thành công',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Cập nhật thông tin thành công!');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập họ tên';
      });
      return false;
    }
    
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return false;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Email không hợp lệ';
      });
      return false;
    }
    
    return true;
  }

  Future<void> _signOut() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Đăng xuất'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }  }

  void _showPhotoOptions() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Thay đổi ảnh đại diện'),
        message: const Text('Chọn nguồn ảnh'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement camera photo capture functionality
              _showSuccessMessage('Tính năng đang được phát triển');
            },
            child: const Text('Chụp ảnh'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement gallery photo selection functionality
              _showSuccessMessage('Tính năng đang được phát triển');
            },
            child: const Text('Chọn từ thư viện'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
      ),
    );
  }
  
  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
    
    // Auto-hide the success message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const EduVisionHeader(
        title: 'Thông tin cá nhân',
        showBackButton: true,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [                // Profile avatar
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoColors.activeBlue.withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.person_crop_circle_fill,
                          size: 60,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _showPhotoOptions,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.camera_fill,
                              size: 18,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Họ và tên',
                  placeholder: 'Nhập họ và tên...',
                  icon: CupertinoIcons.person,
                ),
                const SizedBox(height: 20),

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  placeholder: 'Nhập email...',
                  icon: CupertinoIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),

                // Messages
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 14,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_circle,
                          color: CupertinoColors.systemGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(
                              color: CupertinoColors.systemGreen,
                              fontSize: 14,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Update button
                SizedBox(
                  height: 54,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading ? null : _updateProfile,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Cập nhật thông tin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // Settings section
                Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: CupertinoIcons.bell,
                        title: 'Thông báo',
                        onTap: () {
                          // TODO: Navigate to notification settings
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        icon: CupertinoIcons.lock,
                        title: 'Đổi mật khẩu',
                        onTap: () {
                          // TODO: Navigate to change password
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsItem(
                        icon: CupertinoIcons.info,
                        title: 'Về ứng dụng',
                        onTap: () {
                          // TODO: Show about dialog
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign out button
                SizedBox(
                  height: 54,
                  child: CupertinoButton(
                    color: CupertinoColors.systemRed,
                    onPressed: _signOut,
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: '.SF Pro Text',
                        color: CupertinoColors.white,
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile(
      leading: Icon(
        icon,
        color: CupertinoColors.systemGrey,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: '.SF Pro Text',
        ),
      ),
      trailing: const Icon(
        CupertinoIcons.chevron_right,
        color: CupertinoColors.systemGrey2,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 50),
      color: CupertinoColors.systemGrey4,
    );
  }
}

