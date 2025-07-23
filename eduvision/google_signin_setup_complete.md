# Hướng Dẫn Hoàn Thiện Cấu Hình Google Sign-In cho EduVision

## 1. Kiểm tra cấu hình hiện tại

Bạn đã tạo thành công:
- Web Client ID: `859564462424-a81d1ieeimchlh52a2mcmdriip828ju2.apps.googleusercontent.com`
- Android Client ID: `859564462424-o8iufugaok7ap1t0mrqg31k85odp4icr.apps.googleusercontent.com`
- SHA-1 fingerprint: `83:4E:A0:4A:F8:02:80:F9:08:54:39:8D:F6:77:F7:41:E1:43:B3:56`
- SHA-256 fingerprint: `D5:06:56:7A:8E:EA:45:02:7C:34:E0:46:B0:66:B8:37:DA:E5:AD:E1:E2:D7:6B:35:84:32:F4:17:29:A5:DE:2B`

## 2. Tải xuống google-services.json mới từ Firebase Console

1. Truy cập Firebase Console: https://console.firebase.google.com/
2. Chọn project EduVision của bạn
3. Chọn biểu tượng bánh răng ⚙️ (Cài đặt) > Cài đặt dự án
4. Chọn ứng dụng Android của bạn
5. Nhấn "google-services.json" để tải xuống file đã cập nhật
6. Thay thế file hiện tại tại đường dẫn: `android/app/google-services.json`

## 3. Kiểm tra OAuth Client đã được cài đặt

File `google-services.json` mới phải có phần `oauth_client` giống như sau:

```json
"oauth_client": [
  {
    "client_id": "859564462424-o8iufugaok7ap1t0mrqg31k85odp4icr.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.eduvision",
      "certificate_hash": "834ea04af80280f9085439d8f677f741e143b356"
    }
  },
  {
    "client_id": "859564462424-a81d1ieeimchlh52a2mcmdriip828ju2.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

## 4. Kiểm tra cấu hình trong ứng dụng

1. File `lib/config/api_config.dart` đã được cập nhật với client IDs mới
2. File `lib/services/google_signin_service.dart` đã được cập nhật để sử dụng Web client ID

## 5. Kiểm tra tính năng đăng nhập Google

1. Chạy ứng dụng
2. Nhấn vào nút "Đăng nhập với Google" trên màn hình login
3. Kiểm tra logs để theo dõi quá trình đăng nhập
4. Sử dụng màn hình "Google Sign In Config" để kiểm tra cấu hình và gỡ lỗi nếu cần

## 6. Xử lý sự cố

### Nếu đăng nhập thất bại với lỗi về PlatformException:
- Kiểm tra lại SHA fingerprints trong Firebase Console
- Đảm bảo đã tạo cả Web và Android OAuth clients
- Kiểm tra file google-services.json đã được cập nhật đầy đủ

### Nếu đăng nhập thành công nhưng backend authentication thất bại:
- Kiểm tra endpoint `/api/authentication/google-sessions` trên backend
- Đảm bảo backend được cấu hình để xác thực ID token từ Google

### Nếu ứng dụng crash:
- Kiểm tra Play Services trên thiết bị có được cập nhật không
- Đảm bảo thiết bị có tài khoản Google

## 7. Xác nhận hoàn thành

Khi đăng nhập Google hoạt động:
- Người dùng sẽ thấy màn hình chọn tài khoản Google
- Sau khi chọn tài khoản, ứng dụng sẽ đăng nhập thành công
- Thông tin người dùng (email, tên) sẽ được hiển thị trong ứng dụng

Chúc mừng! Bạn đã hoàn tất việc cài đặt Google Sign-In cho EduVision.
