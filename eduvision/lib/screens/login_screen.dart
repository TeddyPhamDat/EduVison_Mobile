import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
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

    try {
      // Sử dụng AuthService với API đã cung cấp
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Quay lại màn hình trước đó sau khi đăng nhập thành công
        Navigator.of(context).pop();
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

  // Đăng nhập với Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      if (mounted) {
        // Quay lại màn hình trước đó sau khi đăng nhập thành công
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Google Sign In Error in UI: $e');
      setState(() {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('Google Sign In was cancelled')) {
          _errorMessage = 'Đăng nhập Google đã bị hủy';
        } else if (errorMsg.contains('Network error')) {
          _errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại.';
        } else if (errorMsg.contains('Backend error')) {
          _errorMessage = 'Lỗi từ server. Vui lòng thử lại sau.';
        } else {
          _errorMessage = 'Lỗi đăng nhập Google: $errorMsg';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email hoặc tên đăng nhập';
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Đăng nhập',
          style: TextStyle(fontFamily: '.SF Pro Display'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

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
                      CupertinoIcons.person_crop_circle_fill,
                      size: 50,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Email field
                _buildCupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Tên đăng nhập hoặc Email',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(
                    CupertinoIcons.person,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                _buildCupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'Mật khẩu',
                  obscureText: _obscurePassword,
                  prefix: const Icon(
                    CupertinoIcons.lock,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      _obscurePassword
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                          fontSize: 14,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  height: 50,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Google Sign In button
                SizedBox(
                  height: 50,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.systemGrey4,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google icon (you can replace with actual Google icon)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.globe,
                              size: 12,
                              color: CupertinoColors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _isLoading
                              ? const CupertinoActivityIndicator()
                              : const Text(
                                  'Đăng nhập với Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.black,
                                    fontFamily: '.SF Pro Text',
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Forgot password
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontFamily: '.SF Pro Text',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Hoặc',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sign up button
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Chưa có tài khoản? ',
                        style: TextStyle(
                          color: CupertinoColors.black,
                          fontFamily: '.SF Pro Text',
                        ),
                        children: [
                          TextSpan(
                            text: 'Đăng ký',
                            style: TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontWeight: FontWeight.bold,
                              fontFamily: '.SF Pro Text',
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

  Widget _buildCupertinoTextField({
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
      prefix: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: prefix,
            )
          : null,
      suffix: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 8), child: suffix)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
      ),
      style: const TextStyle(fontSize: 16, fontFamily: '.SF Pro Text'),
    );
  }
}
