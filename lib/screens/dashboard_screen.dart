import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/grocery_provider.dart';
import 'recipe_detail_screen.dart';
import 'portal_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlannerProvider>(context, listen: false).fetchMealPlans();
      Provider.of<GroceryProvider>(context, listen: false).fetchGroceryItems();
    });
  }

  Future<void> _updateDietary(String newDiet) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;
    await authProvider.updateProfile(
      authProvider.user!.displayName,
      authProvider.user!.mobileNumber,
      newDiet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final plannerProvider = Provider.of<PlannerProvider>(context);
    final groceryProvider = Provider.of<GroceryProvider>(context);

    final user = authProvider.user;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Filter today's plans
    final todaysMeals = plannerProvider.mealPlans
        .where((plan) => plan.date == todayStr)
        .toList();

    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile Greeting Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      const Color(0xFF00B4D8).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()).toUpperCase(),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hello, ${user?.displayName ?? "User"}! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ready to cook something amazing today? Enter your ingredients or schedule your next meal plan.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.findAncestorStateOfType<PortalNavigationState>()?.setTab(1);
                      },
                      icon: const Icon(Icons.restaurant_menu, size: 16, color: Colors.white),
                      label: const Text('What to Cook?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Modules Grid
              const Text(
                "Explore Modules",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  _buildActionCard(
                    title: 'Smart Suggestion',
                    subtitle: 'Prevent food waste',
                    icon: Icons.auto_awesome,
                    color: primaryColor,
                    onTap: () {
                      context.findAncestorStateOfType<PortalNavigationState>()?.setTab(1);
                    },
                  ),
                  _buildActionCard(
                    title: 'Weekly Planner',
                    subtitle: 'Manage your diet',
                    icon: Icons.calendar_today,
                    color: const Color(0xFF00B4D8),
                    onTap: () {
                      context.findAncestorStateOfType<PortalNavigationState>()?.setTab(3);
                    },
                  ),
                  _buildActionCard(
                    title: 'Shopping Bags',
                    subtitle: 'Checklist helper',
                    icon: Icons.shopping_bag,
                    color: const Color(0xFF06D6A0),
                    onTap: () {
                      context.findAncestorStateOfType<PortalNavigationState>()?.setTab(4);
                    },
                  ),
                  _buildActionCard(
                    title: 'Reels Sandbox',
                    subtitle: 'Watch video reels',
                    icon: Icons.play_circle_filled,
                    color: Colors.amber,
                    onTap: () {
                      context.findAncestorStateOfType<PortalNavigationState>()?.setTab(2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Diet Preference Selector Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant, color: Color(0xFFFF5A36), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Dietary Preference',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['None', 'Vegetarian', 'Vegan', 'Keto', 'Gluten-Free']
                          .map((diet) {
                        final isSelected = user?.dietaryPreference == diet;
                        return ChoiceChip(
                          label: Text(diet),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _updateDietary(diet);
                          },
                          selectedColor: primaryColor,
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Today's Meal Plan Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Schedule",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.findAncestorStateOfType<PortalNavigationState>()?.setTab(3);
                    },
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF5A36)),
                    label: const Text('Add Meal', style: TextStyle(color: Color(0xFFFF5A36), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (todaysMeals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 40, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text(
                        'No meals scheduled for today',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose recipes and plan your breakfast, lunch or dinner.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.findAncestorStateOfType<PortalNavigationState>()?.setTab(3);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Schedule Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todaysMeals.length,
                  itemBuilder: (context, idx) {
                    final meal = todaysMeals[idx];
                    return Card(
                      color: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipe: meal.recipe),
                            ),
                          );
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: meal.recipe.imageUrl.isNotEmpty
                              ? Image.network(
                                  meal.recipe.imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: Colors.white10,
                                    width: 48,
                                    height: 48,
                                    child: const Icon(Icons.image, color: Colors.white30),
                                  ),
                                )
                              : Container(
                                  color: Colors.white10,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(Icons.image, color: Colors.white30),
                                ),
                        ),
                        title: Text(
                          meal.recipe.recipeName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${meal.mealType} • ${meal.recipe.cookingTime} mins',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            meal.mealType,
                            style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
              const SizedBox(height: 24),

              // Overview Stats Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      label: 'Total Planned',
                      value: '${plannerProvider.mealPlans.length}',
                      icon: Icons.calendar_month,
                      iconColor: Colors.blueAccent,
                      onTap: () {
                        context.findAncestorStateOfType<PortalNavigationState>()?.setTab(3);
                      },
                    ),
                    Container(width: 1, height: 40, color: Colors.white12),
                    _buildStatCol(
                      label: 'Grocery Items',
                      value: '${groceryProvider.groceryItems.length}',
                      icon: Icons.shopping_basket,
                      iconColor: Colors.tealAccent,
                      onTap: () {
                        context.findAncestorStateOfType<PortalNavigationState>()?.setTab(4);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final surfaceColor = const Color(0xFF1E1E2C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
