import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import '../utils/eduvision_theme.dart';
import '../widgets/custom_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String password;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.fullName,
    required this.password,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool _validateOtp() {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã OTP');
      return false;
    }
    if (_otpController.text.trim().length < 4) {
      setState(() => _errorMessage = 'Mã OTP phải có ít nhất 4 ký tự');
      return false;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  Future<void> _verifyOtp() async {
    if (!_validateOtp()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.completeRegistration(
        email: widget.email,
        otpToken: _otpController.text.trim(),
        password: widget.password,
        fullName: widget.fullName,
      );

      if (mounted) {
        // Đăng ký thành công, quay về màn hình chính
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Hiển thị thông báo thành công
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Đăng ký thành công'),
            content: const Text('Tài khoản của bạn đã được tạo và đăng nhập thành công!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.startRegistration(email: widget.email);
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('OTP đã được gửi lại'),
            content: Text('Mã OTP mới đã được gửi đến ${widget.email}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Email Verification'),
        backgroundColor: EduVisionTheme.backgroundSecondary,
      ),
      backgroundColor: EduVisionTheme.backgroundPrimary,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Email Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: EduVisionTheme.successGradient,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: EduVisionTheme.primaryTeal.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.mail_solid,
                  size: 50,
                  color: CupertinoColors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Header Text
              Text(
                'Check your email',
                style: EduVisionTheme.title1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification code to:\n${widget.email}',
                style: EduVisionTheme.body.copyWith(
                  color: EduVisionTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input Card
              CustomCard(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _otpController,
                      placeholder: 'Enter verification code',
                      keyboardType: TextInputType.text,
                      errorText: _errorMessage,
                      prefix: const Icon(
                        CupertinoIcons.number,
                        color: EduVisionTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Verify Code',
                      onPressed: _verifyOtp,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: EduVisionTheme.body,
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        color: EduVisionTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Back Button
              SecondaryButton(
                text: 'Back to Sign Up',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
