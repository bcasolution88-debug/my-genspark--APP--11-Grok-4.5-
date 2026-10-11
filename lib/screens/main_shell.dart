import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'albums_screen.dart';
import 'anniversary_screen.dart';
import 'family_screen.dart';
import 'profile_screen.dart';

/// 底部导航：首页 / 相册 / 金婚 / 家人 / 我的
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _albumsKey = GlobalKey<AlbumsScreenState>();
  final _annivKey = GlobalKey<AnniversaryScreenState>();

  void _switch(int i) {
    setState(() => _index = i);
    if (i == 1) _albumsKey.currentState?.load();
    if (i == 2) _annivKey.currentState?.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onSwitchTab: _switch),
      AlbumsScreen(key: _albumsKey),
      AnniversaryScreen(key: _annivKey),
      const FamilyScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 1
          ? FloatingActionButton(
              onPressed: () => _albumsKey.currentState?.showCreateDialog(),
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _switch,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: '首页'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library_rounded), label: '相册'),
            NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite_rounded, color: AppColors.gold), label: '金婚'),
            NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group_rounded), label: '家人'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: '我的'),
          ],
        ),
      ),
    );
  }
}
