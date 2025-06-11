import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CustomFooter extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final bool useIosStyle;

  const CustomFooter({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
    this.useIosStyle = true,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home, cupertinoIcon: CupertinoIcons.home, label: 'Home'),
      _NavItem(icon: Icons.video_library, cupertinoIcon: CupertinoIcons.film, label: 'Videos'),
      _NavItem(icon: Icons.book, cupertinoIcon: CupertinoIcons.book, label: 'Courses'),
      _NavItem(icon: Icons.search, cupertinoIcon: CupertinoIcons.search, label: 'Search'),
      _NavItem(icon: Icons.person, cupertinoIcon: CupertinoIcons.profile_circled, label: 'Profile'),
    ];

    // Use Cupertino style for iOS look and feel
    if (useIosStyle) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTabSelected,
        backgroundColor: const Color(0xFFF8F8F8), // iOS style background
        activeColor: CupertinoColors.activeBlue,
        inactiveColor: CupertinoColors.inactiveGray,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Icon(item.cupertinoIcon),
          label: item.label,
        )).toList(),
        border: const Border(
          top: BorderSide(
            color: Color(0xFFBCBBC1),
            width: 0.5,
          ),
        ),
      );
    }
    
    // Use Material style for Android look and feel
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      items: items.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
      )).toList(),
    );
  }
}

// Helper class to define navigation items
class _NavItem {
  final IconData icon;
  final IconData cupertinoIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.cupertinoIcon,
    required this.label,
  });
}
