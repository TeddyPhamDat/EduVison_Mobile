import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập họ tên');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      setState(() => _errorMessage = 'Email không hợp lệ');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu');
      return false;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp');
      return false;
    }
    return true;
  }

  Future<void> _signUp() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Đăng ký thành công
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Đăng ký thành công'),
            content: const Text('Tài khoản của bạn đã được tạo thành công!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng dialog
                  Navigator.of(context).pop(); // Quay về màn hình đăng nhập
                },
              ),
            ],
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Đăng ký'),
        previousPageTitle: 'Quay lại',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.person_add_solid,
                      size: 60,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Name field
                _buildTextField(
                  controller: _nameController,
                  placeholder: 'Họ và tên',
                  keyboardType: TextInputType.name,
                  prefix: const Icon(
                    CupertinoIcons.person,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email field
                _buildTextField(
                  controller: _emailController,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(
                    CupertinoIcons.mail,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password field
                _buildTextField(
                  controller: _passwordController,
                  placeholder: 'Mật khẩu',
                  obscureText: _obscurePassword,
                  prefix: const Icon(
                    CupertinoIcons.lock,
                    color: CupertinoColors.systemGrey,
                  ),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      color: CupertinoColors.systemGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Confirm Password field
                _buildTextField(
                  controller: _confirmPasswordController,
                  placeholder: 'Xác nhận mật khẩu',
                  obscureText: _obscureConfirmPassword,
                  prefix: const Icon(
                    CupertinoIcons.lock,
                    color: CupertinoColors.systemGrey,
                  ),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      _obscureConfirmPassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      color: CupertinoColors.systemGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                
                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Sign up button
                SizedBox(
                  height: 50,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            radius: 10,
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Đăng ký',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Back to login
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Đã có tài khoản? ',
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: 'Đăng nhập',
                            style: TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefix,
    Widget? suffix,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      prefix: prefix != null 
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: prefix,
            )
          : null,
      suffix: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: suffix,
            )
          : null,
      style: const TextStyle(
        fontSize: 16,
        color: CupertinoColors.black,
      ),
    );
  }
}
