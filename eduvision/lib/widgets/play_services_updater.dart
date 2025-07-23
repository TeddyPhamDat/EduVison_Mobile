import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class PlayServicesUpdater extends StatelessWidget {
  final VoidCallback onRetry;

  const PlayServicesUpdater({Key? key, required this.onRetry}) : super(key: key);

  // Mở Google Play Store để cập nhật Google Play Services
  Future<void> _openPlayServicesInStore() async {
    final Uri playStoreUrl = Uri.parse('market://details?id=com.google.android.gms');
    final Uri webUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.gms');

    try {
      if (await canLaunchUrl(playStoreUrl)) {
        await launchUrl(playStoreUrl);
      } else {
        await launchUrl(webUrl);
      }
    } catch (e) {
      developer.log('Error launching Play Store: $e', name: 'PlayServicesUpdater');
    }
  }

  // Hiển thị hướng dẫn khắc phục lỗi Google Play Services
  void _showTroubleshootingInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hướng dẫn khắc phục chi tiết'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTroubleshootingStep(
                '1. Cập nhật Google Play Services',
                'Mở Google Play Store, tìm Google Play Services và cập nhật lên phiên bản mới nhất.'
              ),
              _buildTroubleshootingStep(
                '2. Xóa dữ liệu của Google Play Services',
                'Vào Cài đặt > Ứng dụng > Google Play Services > Lưu trữ > Xóa dữ liệu và Xóa bộ nhớ đệm.'
              ),
              _buildTroubleshootingStep(
                '3. Khởi động lại thiết bị',
                'Tắt hoàn toàn và khởi động lại thiết bị của bạn.'
              ),
              _buildTroubleshootingStep(
                '4. Kiểm tra tài khoản Google',
                'Vào Cài đặt > Tài khoản > Google và đảm bảo tài khoản của bạn đã được thêm vào thiết bị.'
              ),
              _buildTroubleshootingStep(
                '5. Kiểm tra kết nối internet',
                'Đảm bảo thiết bị được kết nối với mạng Wi-Fi hoặc dữ liệu di động ổn định.'
              ),
              _buildTroubleshootingStep(
                '6. Gỡ cài đặt các bản cập nhật',
                'Nếu không có các giải pháp trên không hiệu quả, hãy thử vào Cài đặt > Ứng dụng > Google Play Services > Gỡ cài đặt bản cập nhật.'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _openPlayServicesInStore,
            child: const Text('Mở Play Store'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTroubleshootingStep(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 70,
              color: Colors.orange,
            ),
            SizedBox(height: 20),
            Text(
              'Không thể đăng nhập với Google',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Vấn đề với Google Play Services đã được phát hiện. '
              'Đây là lỗi thường gặp khi Google Play Services bị lỗi hoặc không được cập nhật.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cách khắc phục lỗi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildFixStep(1, 'Cập nhật Google Play Services'),
                  _buildFixStep(2, 'Xóa dữ liệu và bộ nhớ đệm của Google Play Services'),
                  _buildFixStep(3, 'Kiểm tra Internet và khởi động lại thiết bị'),
                ],
              ),
            ),
            SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _openPlayServicesInStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.system_update),
              label: Text('Cập nhật Google Play Services'),
            ),
            SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                side: BorderSide(color: Colors.deepPurple),
              ),
              icon: Icon(Icons.refresh),
              label: Text('Thử lại đăng nhập'),
            ),
            SizedBox(height: 15),
            TextButton(
              onPressed: () => _showTroubleshootingInstructions(context),
              child: Text('Xem hướng dẫn chi tiết'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFixStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
