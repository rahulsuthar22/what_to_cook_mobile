import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'discover_screen.dart';
import 'recommendations_screen.dart';
import 'reels_screen.dart';
import 'future_specs_screen.dart';

class PortalNavigation extends StatefulWidget {
  final int initialTab;
  const PortalNavigation({super.key, this.initialTab = 0});

  @override
  State<PortalNavigation> createState() => PortalNavigationState();
}

class PortalNavigationState extends State<PortalNavigation> {
  int _currentIndex = 0;
  bool? _wasAuthenticated;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void setTab(int index) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final maxIndex = auth.isAuthenticated ? 3 : 2;
    setState(() {
      _currentIndex = index.clamp(0, maxIndex);
    });
  }

  /// Handles hardware back press & app back logic
  void _handleBackPress() {
    // 1. If not on the main Discover tab, switch back to Discover
    if (_currentIndex != 0) {
      setTab(0);
      _lastBackPressTime = null; // Reset exit timer so user gets clean 2s window on Discover
      return;
    }

    // 2. We ARE on the main Discover page (index == 0)
    // Double press within 2 seconds to exit app
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Press back again to exit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E2C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ),
      );
      return;
    }

    // Confirmed second press within 2 seconds -> exit app cleanly
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAuth = auth.isAuthenticated;

    // Detect login/logout transition and reset to Discover tab
    if (_wasAuthenticated != null && _wasAuthenticated != isAuth) {
      _currentIndex = 0;
    }
    _wasAuthenticated = isAuth;

    const primaryColor = Color(0xFFFF5A36);
    const surfaceColor = Color(0xFF1E1E2C);
    const bgColor = Color(0xFF0F0F1A);

    // Dynamic screen list:
    // Non-login (Guest): 3 tabs -> Discover, What to Cook, Reels
    // Logged in: 4 tabs -> Discover, What to Cook, Reels, AI Chef
    final List<Widget> screens = isAuth
        ? const [
            DiscoverScreen(),
            RecommendationsScreen(),
            ReelsScreen(),
            FutureSpecsScreen(),
          ]
        : const [
            DiscoverScreen(),
            RecommendationsScreen(),
            ReelsScreen(),
          ];

    final int safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: screens[safeIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (index) {
            setTab(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfaceColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: isAuth
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Discover',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.restaurant_menu_outlined),
                    activeIcon: Icon(Icons.restaurant_menu),
                    label: 'What to Cook',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.play_circle_outline),
                    activeIcon: Icon(Icons.play_circle_filled),
                    label: 'Reels',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.smart_toy_outlined),
                    activeIcon: Icon(Icons.smart_toy),
                    label: 'AI Chef',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Discover',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.restaurant_menu_outlined),
                    activeIcon: Icon(Icons.restaurant_menu),
                    label: 'What to Cook',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.play_circle_outline),
                    activeIcon: Icon(Icons.play_circle_filled),
                    label: 'Reels',
                  ),
                ],
        ),
      ),
    );
  }
}
