import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isOtpStep = false; // false = email step, true = OTP step

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendForgotPasswordOtp() async {
    if (!_validateEmailForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );

      setState(() {
        _isOtpStep = true;
        _successMessage = message.isNotEmpty
            ? message
            : 'Mã OTP đã được gửi đến email của bạn.';
      });
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

  Future<void> _resetPassword() async {
    if (!_validateResetForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await _authService.resetPassword(
        email: _emailController.text.trim(),
        otpToken: _otpController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );

      setState(() {
        _successMessage = message.isNotEmpty
            ? message
            : 'Mật khẩu đã được đặt lại thành công.';
      });

      // Delay rồi quay về login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
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

  bool _validateEmailForm() {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return false;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Email không hợp lệ';
      });
      return false;
    }

    return true;
  }

  bool _validateResetForm() {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã OTP';
      });
      return false;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu mới';
      });
      return false;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      return false;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không khớp';
      });
      return false;
    }

    return true;
  }

  void _goBackToEmailStep() {
    setState(() {
      _isOtpStep = false;
      _errorMessage = null;
      _successMessage = null;
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _isOtpStep ? 'Đặt lại mật khẩu' : 'Quên mật khẩu',
          style: const TextStyle(fontFamily: '.SF Pro Display'),
        ),
        leading: _isOtpStep
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _goBackToEmailStep,
                child: const Icon(CupertinoIcons.back),
              )
            : null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isOtpStep
                          ? CupertinoIcons.lock_shield
                          : CupertinoIcons.mail_solid,
                      size: 50,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  _isOtpStep ? 'Đặt lại mật khẩu' : 'Khôi phục mật khẩu',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: '.SF Pro Display',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  _isOtpStep
                      ? 'Nhập mã OTP đã được gửi đến email và mật khẩu mới của bạn.'
                      : 'Nhập địa chỉ email của bạn và chúng tôi sẽ gửi mã OTP để đặt lại mật khẩu.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                    fontFamily: '.SF Pro Text',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email field (always show but disabled in OTP step)
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isOtpStep,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      CupertinoIcons.mail,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _isOtpStep
                        ? CupertinoColors.systemGrey5
                        : CupertinoColors.systemGrey6,
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

                // OTP field (only show in OTP step)
                if (_isOtpStep) ...[
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _otpController,
                    placeholder: 'Mã OTP',
                    keyboardType: TextInputType.number,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        CupertinoIcons.lock,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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

                // Password fields (only show in OTP step)
                if (_isOtpStep) ...[
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Mật khẩu mới',
                    obscureText: true,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        CupertinoIcons.lock_fill,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _confirmPasswordController,
                    placeholder: 'Xác nhận mật khẩu mới',
                    obscureText: true,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        CupertinoIcons.lock_fill,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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

                // Success message
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.systemGreen,
                          fontSize: 14,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Main button
                SizedBox(
                  height: 50,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading
                        ? null
                        : (_isOtpStep
                              ? _resetPassword
                              : _sendForgotPasswordOtp),
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          )
                        : Text(
                            _isOtpStep ? 'Đặt lại mật khẩu' : 'Gửi mã OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: '.SF Pro Text',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to login
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontFamily: '.SF Pro Text',
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
}
