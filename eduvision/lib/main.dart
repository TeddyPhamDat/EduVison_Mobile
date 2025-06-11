import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'screens/profile_screen.dart';
import 'screens/video_list_screen.dart';
import 'screens/content_generation_screen.dart';
import 'screens/content_history_screen.dart';
import 'screens/gdcd_test_screen.dart';
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

// Simple HomePage implementation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('EduVision'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  size: 60,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Welcome text
              const Text(
                'Chào mừng đến với EduVision',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Nền tảng tạo video và nội dung học tập thông minh',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              
              // Create content button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  // Navigate to Content Generation tab
                  final tabController = CupertinoTabController(initialIndex: 2);
                  // This just forces a rebuild to show Content Generation screen
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => CupertinoTabScaffold(
                        controller: tabController,
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
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Tạo nội dung học tập ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
                // View history button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const ContentHistoryScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Xem nội dung đã tạo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Test API button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const GDCDTestScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Test GDCD API',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
