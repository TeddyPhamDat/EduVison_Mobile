import 'package:flutter/material.dart';
import '../services/google_signin_service_new.dart';
import '../config/api_config.dart';
import 'dart:developer' as developer;
import 'package:url_launcher/url_launcher.dart';

class GoogleSignInConfigScreen extends StatefulWidget {
  const GoogleSignInConfigScreen({Key? key}) : super(key: key);

  @override
  _GoogleSignInConfigScreenState createState() => _GoogleSignInConfigScreenState();
}

class _GoogleSignInConfigScreenState extends State<GoogleSignInConfigScreen> {
  final GoogleSignInService _googleSignInService = GoogleSignInService();
  bool _isLoading = false;
  String _status = "Chưa kiểm tra";
  
  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }
  
  Future<void> _checkConfiguration() async {
    setState(() {
      _isLoading = true;
      _status = "Đang kiểm tra cấu hình...";
    });
    
    try {
      // Kiểm tra cấu hình Google Client ID
      final clientId = ApiConfig.googleClientId;
      if (clientId.isEmpty || clientId.contains('your-client-id')) {
        setState(() {
          _status = "❌ Google Client ID chưa được cấu hình";
        });
        return;
      }
      
      // Khởi tạo Google Sign In service
      _googleSignInService.initialize();
      
      setState(() {
        _status = "✅ Cấu hình hợp lệ. Google Client ID: ${clientId.substring(0, 10)}...";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Lỗi kiểm tra: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = "Đang thử đăng nhập...";
    });
    
    try {
      final result = await _googleSignInService.signIn();
      if (result != null) {
        setState(() {
          _status = "✅ Đăng nhập thành công với: ${result.user.email}";
        });
      } else {
        setState(() {
          _status = "❌ Người dùng đã hủy đăng nhập";
        });
      }
    } catch (e) {
      setState(() {
        _status = "❌ Lỗi đăng nhập: $e";
      });
      developer.log("Google Sign In test error: $e", name: "GoogleSignInConfig");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _openFirebaseConsole() async {
    const url = 'https://console.firebase.google.com/';
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở trang web: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cấu hình Google Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái cấu hình',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : Text(_status),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading ? null : _checkConfiguration,
                            child: Text('Kiểm tra lại'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _testGoogleSignIn,
                            child: Text('Thử đăng nhập'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Hướng dẫn cấu hình',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              _buildInstructionStep(
                '1. Cấu hình trong Firebase Console',
                'Thêm SHA-1 và SHA-256 fingerprints trong phần Project Settings > Android App',
                onTap: _openFirebaseConsole,
              ),
              _buildInstructionStep(
                '2. Cập nhật google-services.json',
                'Tải và cập nhật file từ Firebase Console vào thư mục android/app/',
              ),
              _buildInstructionStep(
                '3. Cập nhật Client ID',
                'Cập nhật Google Client ID trong file api_config.dart',
              ),
              _buildInstructionStep(
                '4. Lấy SHA-1 và SHA-256 fingerprints',
                'Chạy lệnh sau trong terminal:\n'
                'keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android',
              ),
              SizedBox(height: 24),
              Text(
                'Yêu cầu cho Google Sign In:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                '• Google Client ID cho Web và Android\n'
                '• SHA-1 và SHA-256 fingerprints được thêm vào Firebase\n'
                '• Cấu hình oauth_client trong google-services.json\n'
                '• API Google Sign-In được bật trong Google Cloud Console',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructionStep(String title, String content, {VoidCallback? onTap}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(content),
              if (onTap != null) ...[
                SizedBox(height: 8),
                Text(
                  'Nhấn để mở',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
