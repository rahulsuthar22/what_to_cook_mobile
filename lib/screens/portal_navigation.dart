import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'recommendations_screen.dart';
import 'planner_screen.dart';
import 'grocery_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'future_specs_screen.dart';

class PortalNavigation extends StatefulWidget {
  const PortalNavigation({super.key});

  @override
  State<PortalNavigation> createState() => _PortalNavigationState();
}

class _PortalNavigationState extends State<PortalNavigation> {
  int _currentIndex = 0;

  final List<Widget> _primaryScreens = [
    const DashboardScreen(),
    const RecommendationsScreen(),
    const PlannerScreen(),
    const GroceryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);
    final bgColor = const Color(0xFF0F0F1A);

    return Scaffold(
      backgroundColor: bgColor,
      body: _currentIndex < 4 
          ? _primaryScreens[_currentIndex]
          : const MoreMenuScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'What to Cook',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Grocery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('More Portal Options', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            title: 'My Profile',
            subtitle: 'Update details & diet preferences',
            icon: Icons.person_outline,
            color: Colors.blueAccent,
            targetScreen: const ProfileScreen(),
          ),
          _buildMenuCard(
            context,
            title: 'Reports & Stats',
            subtitle: 'Ingredient metrics & charts',
            icon: Icons.bar_chart_outlined,
            color: Colors.green,
            targetScreen: const ReportsScreen(),
          ),
          _buildMenuCard(
            context,
            title: 'Future Specs',
            subtitle: 'AI Chat, Voice, scanner sandbox',
            icon: Icons.auto_awesome_outlined,
            color: Colors.amber,
            targetScreen: const FutureSpecsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget targetScreen,
  }) {
    final surfaceColor = const Color(0xFF1E1E2C);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
