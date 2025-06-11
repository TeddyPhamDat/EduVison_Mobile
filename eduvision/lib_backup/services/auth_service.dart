import 'dart:async';

import '../models/user.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  
  factory AuthService() => _instance;
  
  AuthService._internal();

  // Giả lập người dùng đang đăng nhập
  User? _currentUser;

  // Giả lập danh sách người dùng (trong thực tế sẽ kết nối với backend)
  final Map<String, User> _users = {
    'user@example.com': User(
      id: '1',
      name: 'Lê Thiên Phúc',
      email: 'user@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    ),
  };

  // Stream để theo dõi thay đổi trạng thái đăng nhập
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Trả về người dùng hiện tại
  User? get currentUser => _currentUser;

  // Đăng nhập với email và mật khẩu
  Future<User> signIn({required String email, required String password}) async {
    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(seconds: 1));

    // Kiểm tra xem email có tồn tại không
    if (!_users.containsKey(email)) {
      throw Exception('Người dùng không tồn tại');
    }

    // Trong thực tế, cần kiểm tra mật khẩu đúng hay không
    // Ở đây chúng ta giả định mật khẩu là '123456'
    if (password != '123456') {
      throw Exception('Mật khẩu không đúng');
    }

    // Đăng nhập thành công
    _currentUser = _users[email];
    _authStateController.add(_currentUser);
    
    return _currentUser!;
  }

  // Đăng ký người dùng mới
  Future<User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(seconds: 1));

    // Kiểm tra xem email đã được sử dụng chưa
    if (_users.containsKey(email)) {
      throw Exception('Email đã được sử dụng');
    }

    // Tạo người dùng mới
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg', // Avatar mặc định
    );

    // Lưu vào danh sách người dùng
    _users[email] = newUser;

    // Tự động đăng nhập sau khi đăng ký
    _currentUser = newUser;
    _authStateController.add(_currentUser);

    return newUser;
  }

  // Đăng xuất
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  // Đóng stream khi không cần thiết
  void dispose() {
    _authStateController.close();
  }

  // Kiểm tra người dùng đã đăng nhập chưa
  bool get isSignedIn => _currentUser != null;
}
