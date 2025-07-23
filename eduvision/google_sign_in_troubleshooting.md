# Hướng dẫn khắc phục lỗi Google Sign-In trong EduVision

## Lỗi hiện tại

```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

Lỗi này thường liên quan đến cấu hình Google Play Services hoặc thiết lập SHA-1 fingerprint.

## Giải pháp từng bước

### 1. Kiểm tra Google Play Services

- **Cập nhật Google Play Services**:
  - Mở Google Play Store
  - Tìm "Google Play Services"
  - Cập nhật lên phiên bản mới nhất

- **Kiểm tra phiên bản**:
  - Vào Cài đặt > Ứng dụng > Google Play Services
  - Xác nhận rằng nó đã được cập nhật

### 2. Kiểm tra và cập nhật SHA fingerprint

- **Kiểm tra SHA-1 fingerprint đã thêm vào Firebase**:
  - Lưu ý rằng SHA-1 đã thêm là: `83:4E:A0:4A:F8:02:80:F9:08:54:39:8D:F6:77:F7:41:E1:43:B3:56`
  - Đảm bảo nó khớp với giá trị trên Firebase Console

- **Thêm SHA-1 fingerprint cho keystore đang sử dụng**:
  - Nếu bạn đang build với keystore khác (không phải debug.keystore), lấy SHA-1 từ keystore đó

### 3. Kiểm tra AndroidManifest.xml

- **Thêm quyền Internet**:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 4. Cấu hình OAuth consent screen

- **Tạo và cấu hình OAuth consent screen**:
  - Đảm bảo bạn đã hoàn tất quá trình cấu hình OAuth consent screen
  - Thêm ít nhất một Test User nếu bạn đang trong quá trình phát triển

### 5. Bật Google Sign-In API

- **Bật API trong Google Cloud Console**:
  - Vào Google Cloud Console > APIs & Services > Library
  - Tìm "Google Sign-In API"
  - Bấm "Enable"

### 6. Sửa lỗi với plugin và cấu hình Flutter

- **Cập nhật pubspec.yaml**:
  ```yaml
  dependencies:
    google_sign_in: ^6.2.1
  ```

- **Chạy flutter clean và flutter pub get**:
  ```
  flutter clean
  flutter pub get
  ```

### 7. Kiểm tra package name

- **Xác nhận package name trong AndroidManifest.xml khớp với giá trị trên Firebase Console**:
  - Hiện tại là: `com.example.eduvision`

### 8. Thử đăng nhập trong chế độ debug

- **Thêm chi tiết log**:
  - Đã cập nhật `GoogleSignInService.dart` với log chi tiết hơn
  - Kiểm tra output khi thử đăng nhập để xem chi tiết lỗi

## Nguyên nhân và giải pháp cho mã lỗi cụ thể

### ApiException: 10:
- **Nguyên nhân**: SHA-1 fingerprint không chính xác hoặc thiếu
- **Giải pháp**: Thêm SHA-1 fingerprint chính xác vào Firebase Console

### ApiException: 12501:
- **Nguyên nhân**: Người dùng hủy quá trình đăng nhập
- **Giải pháp**: Không cần làm gì, đây là hành động của người dùng

### ApiException: 7:
- **Nguyên nhân**: Lỗi kết nối mạng
- **Giải pháp**: Kiểm tra kết nối internet

## Kiểm tra sau khi thực hiện các bước trên

1. Chạy ứng dụng trong chế độ debug
2. Theo dõi log để xác định nguyên nhân chính xác
3. Thử đăng nhập lại sau khi đã thực hiện các thay đổi

## Liên hệ hỗ trợ

Nếu bạn vẫn gặp vấn đề sau khi thử các giải pháp trên, hãy liên hệ hỗ trợ với:
- Log chi tiết
- Phiên bản Flutter và Dart
- Phiên bản Google Play Services trên thiết bị thử nghiệm
