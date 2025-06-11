import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen_new.dart';
import 'screens/profile_screen.dart';
import 'screens/video_list_screen.dart';
import 'screens/content_generation_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AuthService
  final authService = AuthService();
  await authService.initialize();
  
  runApp(const EduVisionApp());
}

class EduVisionApp extends StatelessWidget {
  const EduVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'EduVision',
      theme: CupertinoThemeData(
        primaryColor: Color(0xFF6C5CE7),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF2D3436),
        ),
      ),
      home: MainTabView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainTabView extends StatelessWidget {
  const MainTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.white,
        activeColor: const Color(0xFF6C5CE7),
        inactiveColor: CupertinoColors.systemGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.play_rectangle),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.sparkles),
            label: 'Tạo nội dung',
          ),          
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomePage();
          case 1:
            return const VideoListScreen();
          case 2:
            return const ContentGenerationScreen();
          case 3:
            return const ProfileScreen();
          default:
            return const HomePage();
        }
      },
    );
  }
}
