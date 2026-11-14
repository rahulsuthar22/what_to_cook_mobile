import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/planner_provider.dart';
import '../providers/grocery_provider.dart';
import '../models/meal_plan.dart';
import 'portal_navigation.dart';
import 'recipe_detail_screen.dart';
import 'grocery_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime _genStartDate = DateTime.now();
  DateTime _genEndDate = DateTime.now().add(const Duration(days: 6));
  bool _isGenerating = false;

  static const Color _primaryColor = Color(0xFFFF5A36);
  static const Color _bgColor = Color(0xFF0F0F1A);
  static const Color _surfaceColor = Color(0xFF1E1E2C);
  static const Color _surfaceElevated = Color(0xFF282840);
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlannerProvider>(context, listen: false).fetchMealPlans();
    });
  }

  /// Get the 7 dates (Mon–Sun) for the current week
  List<DateTime> _getWeekDates() {
    final monday = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Navigate forward/backward by one week
  void _navigateWeek(int direction) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: direction * 7));
    });
  }

  /// Format the week range label
  String _weekRangeLabel(List<DateTime> weekDates) {
    final start = weekDates.first;
    final end = weekDates.last;
    return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
  }

  /// Check if a given date is today
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Find a scheduled meal for a specific date + mealType with robust parsing
  MealPlanModel? _findMeal(List<MealPlanModel> plans, DateTime date, String type) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final targetType = type.toLowerCase().trim();
    try {
      return plans.firstWhere((p) {
        final pDate = p.date.contains('T') ? p.date.split('T')[0] : p.date;
        return pDate.trim() == dateStr && p.mealType.toLowerCase().trim() == targetType;
      });
    } catch (_) {
      return null;
    }
  }

  /// Delete a meal plan
  Future<void> _deleteMeal(int planId) async {
    final planner = Provider.of<PlannerProvider>(context, listen: false);
    final success = await planner.deleteMealPlan(planId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Meal removed' : 'Failed to remove meal'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Navigate to the Recommendations tab to schedule a recipe
  void _goToRecommendations() {
    final navState = context.findAncestorStateOfType<PortalNavigationState>();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    navState?.setTab(1); // index 1 = Recommendations / "What to Cook"
  }

  /// Handle grocery list compilation
  Future<void> _handleCompile() async {
    if (_genStartDate.isAfter(_genEndDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be after end date.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
    final startStr = DateFormat('yyyy-MM-dd').format(_genStartDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_genEndDate);

    final success = await groceryProvider.generateFromPlanner(startStr, endStr);

    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Shopping list compiled from $startStr to $endStr!'
                : 'Compilation failed. Please schedule some meals first.',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          action: success
              ? SnackBarAction(
                  label: 'VIEW LIST',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GroceryScreen()),
                    );
                  },
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = Provider.of<PlannerProvider>(context);
    final weekDates = _getWeekDates();

    return Scaffold(
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        color: _primaryColor,
        backgroundColor: _surfaceColor,
        onRefresh: () => planner.fetchMealPlans(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── App Bar ───
            SliverAppBar(
              pinned: true,
              backgroundColor: _surfaceColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    final navState = context.findAncestorStateOfType<PortalNavigationState>();
                    navState?.setTab(0);
                  }
                },
              ),
              title: const Text(
                'Weekly Meal Planner',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
            ),

            // ─── Subtitle ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Schedule recipes for breakfast, lunch, and dinner to stay organized.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
                ),
              ),
            ),

            // ─── Week Navigation Bar ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 22),
                        onPressed: () => _navigateWeek(-1),
                        splashRadius: 20,
                      ),
                      Text(
                        _weekRangeLabel(weekDates),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
                        onPressed: () => _navigateWeek(1),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Loading State ───
            if (planner.isLoading && planner.mealPlans.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                ),
              )
            else
              // ─── Day Cards ───
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final date = weekDates[index];
                    final dayName = _weekdays[index];
                    final isToday = _isToday(date);
                    return _buildDayCard(planner, date, dayName, isToday);
                  },
                  childCount: 7,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ─── Generate Grocery List Section ───
            SliverToBoxAdapter(child: _buildGrocerySection()),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  /// Builds a single day card — shows the day header + 4 meal type slots in a 2×2 grid
  Widget _buildDayCard(PlannerProvider planner, DateTime date, String dayName, bool isToday) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? _primaryColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? _primaryColor.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                if (isToday)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: _primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  dayName,
                  style: TextStyle(
                    color: isToday ? _primaryColor : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d').format(date),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                ),
                if (isToday) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Meal type slots — 2 columns × 2 rows grid with anti-overflow aspect ratio
          Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: _mealTypes.map((type) {
                final meal = _findMeal(planner.mealPlans, date, type);
                return meal != null
                    ? _buildMealCard(meal, type)
                    : _buildEmptySlot(type);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a filled meal card with tap-to-view recipe details
  Widget _buildMealCard(MealPlanModel meal, String mealType) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: meal.recipe),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal type label + delete button
            Row(
              children: [
                Text(
                  mealType,
                  style: TextStyle(
                    color: _primaryColor.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _deleteMeal(meal.planId),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Recipe name
            Expanded(
              child: Text(
                meal.recipe.recipeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Meta info
            Row(
              children: [
                Icon(Icons.access_time, size: 10, color: Colors.white.withValues(alpha: 0.35)),
                const SizedBox(width: 3),
                Text(
                  '${meal.recipe.cookingTime}m',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${meal.recipe.calories} kcal',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an empty slot with meal type label and "+ Schedule" action
  Widget _buildEmptySlot(String mealType) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _goToRecommendations,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mealType,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 12, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(width: 3),
                Text(
                  'Schedule',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the grocery generation card
  Widget _buildGrocerySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: _primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Generate Grocery List',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Define a date range, and we\'ll pull all required ingredients from your scheduled meals.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Date range pickers
          Row(
            children: [
              Expanded(
                child: _buildDatePicker('Start Date', _genStartDate, (d) {
                  setState(() => _genStartDate = d);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker('End Date', _genEndDate, (d) {
                  setState(() => _genEndDate = d);
                }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Compile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _handleCompile,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              label: Text(
                _isGenerating ? 'Analyzing recipes...' : 'Compile Shopping List',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0),
                disabledBackgroundColor: const Color(0xFF06D6A0).withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable date picker tile with dark theme support & safety bounds
  Widget _buildDatePicker(String label, DateTime date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: now.subtract(const Duration(days: 365)),
          lastDate: now.add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: _primaryColor,
                  onPrimary: Colors.white,
                  surface: _surfaceColor,
                  onSurface: Colors.white,
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: _surfaceColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
