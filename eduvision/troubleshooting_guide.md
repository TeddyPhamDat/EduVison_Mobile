# Google Sign-In Troubleshooting Guide

Dựa trên lỗi **ApiException: 10** mà bạn đang gặp phải với Google Sign-In, đây là hướng dẫn khắc phục chi tiết:

## Nguyên nhân của ApiException: 10

Lỗi này thường xảy ra do một trong những nguyên nhân sau:

1. **SHA-1 Certificate Mismatch**: SHA-1 fingerprint của ứng dụng không khớp với cấu hình trong Firebase Console
2. **Google Play Services**: Phiên bản Google Play Services trên thiết bị quá cũ hoặc có vấn đề
3. **Client ID Configuration**: Sử dụng sai Client ID hoặc không cấu hình đúng trong ứng dụng

## Các bước khắc phục

### 1. Kiểm tra và cập nhật Google Play Services

- Mở **Google Play Store** > tìm **Google Play Services** > cập nhật nếu có
- Vào **Settings** > **Apps** > **Google Play Services** > **Storage** > **Clear Cache** và **Clear Data**
- Khởi động lại thiết bị

### 2. Kiểm tra SHA-1 Fingerprint

- Chạy lệnh sau trong terminal/command prompt từ thư mục dự án Flutter:

```bash
cd android
./gradlew signingReport
```

- So sánh SHA-1 output với SHA-1 đã đăng ký trong Firebase Console
- Đảm bảo bạn đã thêm **cả SHA-1 debug và release** vào Firebase Console

### 3. Kiểm tra cấu hình Client ID

- Xác nhận rằng Web Client ID (`server_client_id`) trong ứng dụng khớp với Web Client ID trong Google Cloud Console
- Đảm bảo `google-services.json` đã được cập nhật và chứa đúng thông tin

### 4. Kiểm tra Manifest và Permissions

- Đảm bảo AndroidManifest.xml có quyền INTERNET
- Kiểm tra file strings.xml chứa web_client_id chính xác

### 5. Giải pháp khác

- Thử đăng nhập trên thiết bị thực (không phải emulator)
- Gỡ và cài đặt lại ứng dụng
- Dùng một tài khoản Google khác để thử

## Kiểm tra Debug Logs

Khi ứng dụng khởi động, hãy kiểm tra debug logs để xem:

1. SHA-1 fingerprint thực tế của ứng dụng
2. Client ID đang được sử dụng
3. Chi tiết lỗi đầy đủ

## Thay đổi gần đây

- Đã cải thiện xử lý lỗi và logging cho ApiException: 10
- Đã thêm debug utility để xem thông tin signing
- Đã kiểm tra và cập nhật cấu hình trong Firebase

Nếu vẫn gặp vấn đề, vui lòng cung cấp thêm thông tin về thiết bị, phiên bản Android, và logs đầy đủ để được hỗ trợ thêm.
