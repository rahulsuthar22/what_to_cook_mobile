import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/grocery_provider.dart';

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
              // Header with Profile Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.displayName ?? "User"} 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5A36), Color(0xFFFF7A45)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (user != null && user.displayName.isNotEmpty)
                          ? user.displayName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Diet Preference Selector Card
              Container(
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
              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              if (todaysMeals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
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
                        'Find matching recipes and schedule your dinner.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Change parent index to 'What to Cook'
                          // In our nested navigation we can just suggest to use tabs
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Search Recipes', style: TextStyle(color: Colors.white)),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      label: 'Total Planned',
                      value: '${plannerProvider.mealPlans.length}',
                      icon: Icons.calendar_month,
                      iconColor: Colors.blueAccent,
                    ),
                    Container(width: 1, height: 40, color: Colors.white12),
                    _buildStatCol(
                      label: 'Grocery List',
                      value: '${groceryProvider.groceryItems.length}',
                      icon: Icons.shopping_basket,
                      iconColor: Colors.tealAccent,
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

  Widget _buildStatCol({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
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
    );
  }
}
