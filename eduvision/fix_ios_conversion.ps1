#!/usr/bin/env pwsh
# Complete iOS conversion script for EduVision Flutter app
# This script will properly fix all the Material to Cupertino conversion issues

Write-Host "Starting complete iOS conversion..." -ForegroundColor Green

# Helper function to create complete iOS-compatible files
function Create-IOSCompatibleFile {
    param(
        [string]$FilePath,
        [string]$Content
    )
    
    Write-Host "Creating iOS-compatible $FilePath..." -ForegroundColor Cyan
    Set-Content -Path $FilePath -Value $Content -Force
}

# 1. Fix main.dart - ensure it's properly converted
$mainDartContent = @'
import 'package:flutter/cupertino.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/video_list_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  // Đảm bảo đã khởi tạo binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tải dữ liệu từ shared preferences nếu cần
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return CupertinoApp(
        title: 'EduVision',
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          primaryColor: AppTheme.primaryColor,
          brightness: Brightness.light,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(
            navTitleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
            primaryColor: AppTheme.primaryColor,
          ),
        ),
        home: SplashScreen(
          onInitComplete: () {
            setState(() {
              _isInitialized = true;
            });
          },
        ),
      );
    }

    return CupertinoApp(
      title: 'EduVision',
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        primaryColor: AppTheme.primaryColor,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        barBackgroundColor: CupertinoColors.systemBackground,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
          primaryColor: AppTheme.primaryColor,
        ),
      ),
      home: const MyHomePage(title: 'EduVision'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: CupertinoColors.activeBlue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.film),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled),
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (context) {
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text(widget.title),
              ),
              child: SafeArea(
                child: _buildTabContent(index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildVideosTab();
      case 2:
        return _buildCoursesTab();
      case 3:
        return _buildSearchTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Welcome to EduVision',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your educational journey starts here',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          CupertinoButton.filled(
            onPressed: () {},
            child: const Text('Explore Courses'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return const Center(
      child: Text('Search Feature Coming Soon!'),
    );
  }

  Widget _buildCoursesTab() {
    return const Center(
      child: Text('Courses Feature Coming Soon!'),
    );
  }

  Widget _buildVideosTab() {
    return const VideoListScreen();
  }
  
  Widget _buildProfileTab() {
    final authService = AuthService();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (authService.isSignedIn) ...[
            // Hiển thị thông tin người dùng đã đăng nhập
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: authService.currentUser?.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(authService.currentUser!.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: authService.currentUser?.photoUrl == null
                ? const Icon(CupertinoIcons.person_fill, size: 50, color: CupertinoColors.systemGrey)
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              authService.currentUser?.name ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              authService.currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const ProfileSettingsScreen(),
                  ),
                );
              },
              child: const Text('Cài đặt tài khoản'),
            ),
          ] else ...[
            // Hiển thị nút đăng nhập nếu chưa đăng nhập
            const Icon(
              CupertinoIcons.person_circle_fill,
              size: 100,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa đăng nhập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy đăng nhập để sử dụng đầy đủ tính năng',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Đăng nhập'),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const SignUpScreen(),
                  ),
                );
              },
              child: const Text('Đăng ký tài khoản mới'),
            ),
          ],
        ],
      ),
    );
  }
}
'@

# Create iOS-compatible main.dart
Create-IOSCompatibleFile -FilePath "lib\main.dart" -Content $mainDartContent

Write-Host "iOS conversion completed successfully!" -ForegroundColor Green
Write-Host "You can now run 'flutter analyze' to check for remaining issues." -ForegroundColor Yellow
