import 'package:flutter/cupertino.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validateEmail() {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _message = 'Vui lòng nhập email';
        _isSuccess = false;
      });
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      setState(() {
        _message = 'Email không hợp lệ';
        _isSuccess = false;
      });
      return false;
    }
    return true;
  }
  Future<void> _resetPassword() async {
    if (!_validateEmail()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Giả lập gửi email khôi phục mật khẩu vì API chưa có method này
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _message = 'Email khôi phục mật khẩu đã được gửi đến ${_emailController.text.trim()}';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
        _isSuccess = false;
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
        middle: Text('Quên mật khẩu'),
        previousPageTitle: 'Quay lại',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_rotation,
                      size: 60,
                      color: CupertinoColors.systemOrange,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Title
                const Text(
                  'Khôi phục mật khẩu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                const Text(
                  'Nhập email của bạn để nhận liên kết khôi phục mật khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Email field
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Email của bạn',
                  keyboardType: TextInputType.emailAddress,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                      width: 1,
                    ),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      CupertinoIcons.mail,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.black,
                  ),
                ),
                
                // Message
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess 
                            ? CupertinoColors.systemGreen.withOpacity(0.1)
                            : CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess 
                                ? CupertinoIcons.checkmark_circle
                                : CupertinoIcons.exclamationmark_circle,
                            color: _isSuccess 
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message!,
                              style: TextStyle(
                                color: _isSuccess 
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemRed,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Reset button
                SizedBox(
                  height: 50,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(
                            radius: 10,
                            color: CupertinoColors.white,
                          )
                        : const Text(
                            'Gửi email khôi phục',
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
                    child: const Text(
                      'Quay về đăng nhập',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 16,
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
