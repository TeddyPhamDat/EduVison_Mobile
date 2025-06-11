import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/eduvision_header.dart';

class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});

  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {      // Gọi API đăng nhập
      await _authService.signIn(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        // Show welcome alert
        _showWelcomeAlert();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showWelcomeAlert() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Đăng nhập thành công!'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFF6366F1),
                size: 60,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chào mừng ${_usernameController.text.split('@').first} đã quay trở lại!',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success result
            },
            child: const Text('Đi tới trang chủ'),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập tên đăng nhập hoặc email';
      });
      return false;
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu';
      });
      return false;
    }
    
    return true;
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: const EduVisionHeader(
        title: 'Đăng nhập',
        showBackButton: true,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo section
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(top: 20, bottom: 40),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  size: 50,
                  color: CupertinoColors.white,
                ),
              ),
              
              // Form section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để tiếp tục sử dụng EduVision',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Username field
                    _buildFormField(
                      controller: _usernameController,
                      label: 'Tên đăng nhập hoặc Email',
                      placeholder: 'Nhập tên đăng nhập hoặc email',
                      prefix: const Icon(
                        CupertinoIcons.person,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    _buildFormField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      placeholder: 'Nhập mật khẩu',
                      obscureText: _obscurePassword,
                      prefix: const Icon(
                        CupertinoIcons.lock,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      suffix: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword 
                              ? CupertinoIcons.eye 
                              : CupertinoIcons.eye_slash,
                          color: const Color(0xFF9CA3AF),
                          size: 20,
                        ),
                      ),
                    ),
                    
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Forgot password
                    Center(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          // TODO: Navigate to forgot password screen
                        },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: Color(0xFF6C5CE7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Register section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // TODO: Navigate to signup screen
                    },
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefix,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          keyboardType: keyboardType,
          obscureText: obscureText,
          prefix: prefix != null ? Padding(
            padding: const EdgeInsets.only(left: 12),
            child: prefix,
          ) : null,
          suffix: suffix != null ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: suffix,
          ) : null,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
