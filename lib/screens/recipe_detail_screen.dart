import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/grocery_provider.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  YoutubePlayerController? _ytController;
  List<bool> _stepCompletionList = [];
  List<String> _instructionsSteps = [];

  // Scheduling State
  String _mealType = 'Lunch';
  DateTime _selectedDate = DateTime.now();
  bool _isScheduling = false;
  bool _isAddingGrocery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize YouTube Player if a video URL is present
    final videoId = YoutubePlayer.convertUrlToId(widget.recipe.videoUrl);
    if (videoId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          enableCaption: true,
        ),
      );
    }

    // Split cooking instructions by newlines
    _instructionsSteps = widget.recipe.instructions
        .split(RegExp(r'\r?\n|\n'))
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();
    _stepCompletionList = List.generate(_instructionsSteps.length, (_) => false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  Future<void> _handleSchedule() async {
    setState(() {
      _isScheduling = true;
    });

    final planner = Provider.of<PlannerProvider>(context, listen: false);
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final success = await planner.scheduleMeal(
      recipeId: widget.recipe.recipeId,
      date: dateStr,
      mealType: _mealType,
    );

    if (mounted) {
      setState(() {
        _isScheduling = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled ${widget.recipe.recipeName} for $_mealType successfully!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _tabController.animateTo(2); // Jump to instructions or dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule meal. Please try again.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleAddMissingToGrocery() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);

    // Compute missing ingredients
    final pantry = recipeProvider.selectedIngredients.map((i) => i.toLowerCase()).toList();
    final recipeIngredients = widget.recipe.ingredients ?? [];
    final missing = recipeIngredients.where((ing) => !pantry.contains(ing.ingredientName.toLowerCase())).toList();

    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All ingredients are already in your pantry!'),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAddingGrocery = true;
    });

    int addedCount = 0;
    for (var ing in missing) {
      final success = await groceryProvider.addCustomItem(ing.ingredientName, ing.quantity ?? '');
      if (success) addedCount++;
    }

    if (mounted) {
      setState(() {
        _isAddingGrocery = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $addedCount missing ingredients to your grocery list!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);
    final bgColor = const Color(0xFF0F0F1A);

    Widget buildMainContent(Widget? playerWidget) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            widget.recipe.recipeName,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            if (playerWidget != null)
              playerWidget
            else
              Hero(
                tag: 'recipe_image_${widget.recipe.recipeId}',
                child: widget.recipe.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.recipe.imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          height: 220,
                          color: Colors.white10,
                          child: const Icon(Icons.image, color: Colors.white24, size: 50),
                        ),
                      )
                    : Container(
                        height: 220,
                        color: Colors.white10,
                        child: const Icon(Icons.restaurant, color: Colors.white24, size: 50),
                      ),
              ),

            // Tabs
            Container(
              color: surfaceColor,
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.white54,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.analytics_outlined), text: 'Nutrition'),
                  Tab(icon: Icon(Icons.shopping_basket_outlined), text: 'Ingredients'),
                  Tab(icon: Icon(Icons.checklist_outlined), text: 'Steps'),
                  Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Schedule'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNutritionTab(surfaceColor, primaryColor),
                  _buildIngredientsTab(surfaceColor, primaryColor),
                  _buildStepsTab(surfaceColor, primaryColor),
                  _buildScheduleTab(surfaceColor, primaryColor),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_ytController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: primaryColor,
        ),
        builder: (context, player) => buildMainContent(player),
      );
    }

    return buildMainContent(null);
  }

  Widget _buildNutritionTab(Color surfaceColor, Color primaryColor) {
    final stats = [
      {'name': 'Calories', 'val': '${widget.recipe.calories} kcal', 'color': Colors.orangeAccent, 'icon': Icons.local_fire_department},
      {'name': 'Protein', 'val': '${widget.recipe.protein}g', 'color': Colors.redAccent, 'icon': Icons.fitness_center},
      {'name': 'Carbs', 'val': '${widget.recipe.carbs}g', 'color': Colors.blueAccent, 'icon': Icons.grain},
      {'name': 'Fat', 'val': '${widget.recipe.fat}g', 'color': Colors.pinkAccent, 'icon': Icons.opacity},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutritional Content',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, idx) {
              final stat = stats[idx];
              return Container(
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
                    Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 24),
                    const SizedBox(height: 12),
                    Text(
                      stat['name'] as String,
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['val'] as String,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.recipe.vitamins.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Vitamins & Minerals',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                widget.recipe.vitamins,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(Color surfaceColor, Color primaryColor) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final pantry = recipeProvider.selectedIngredients.map((i) => i.toLowerCase()).toList();
    final ingredients = widget.recipe.ingredients ?? [];

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: ingredients.length,
            itemBuilder: (context, idx) {
              final ing = ingredients[idx];
              final isMatched = pantry.contains(ing.ingredientName.toLowerCase());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMatched
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMatched ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isMatched ? Colors.greenAccent : Colors.white30,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        ing.ingredientName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      ing.quantity ?? '',
                      style: GoogleFonts.outfit(
                        color: isMatched ? Colors.greenAccent : Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAddingGrocery ? null : _handleAddMissingToGrocery,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isAddingGrocery
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart, color: Colors.white),
              label: Text(
                'Add Missing to Grocery List',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsTab(Color surfaceColor, Color primaryColor) {
    if (_instructionsSteps.isEmpty) {
      return Center(
        child: Text(
          'No specific step breakdown available.',
          style: GoogleFonts.outfit(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _instructionsSteps.length,
      itemBuilder: (context, idx) {
        final stepText = _instructionsSteps[idx];
        final isCompleted = _stepCompletionList[idx];

        return GestureDetector(
          onTap: () {
            setState(() {
              _stepCompletionList[idx] = !isCompleted;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.white.withValues(alpha: 0.02) : surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted ? primaryColor.withValues(alpha: 0.3) : Colors.white10,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? primaryColor : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${idx + 1}',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    stepText,
                    style: GoogleFonts.outfit(
                      color: isCompleted ? Colors.white38 : Colors.white,
                      fontSize: 14,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab(Color surfaceColor, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Schedule Meal Plan',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: primaryColor,
                                surface: surfaceColor,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.date_range, color: Colors.white70, size: 20),
                    label: Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _mealType,
                    dropdownColor: surfaceColor,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    items: ['Breakfast', 'Lunch', 'Dinner']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _mealType = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isScheduling ? null : _handleSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isScheduling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Confirm Schedule',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
