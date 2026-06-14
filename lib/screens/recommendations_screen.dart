import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/planner_provider.dart';
import '../models/recipe.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  // Predefined common ingredients matching seeds.sql
  final List<String> _commonIngredients = [
    'Paneer', 'Butter', 'Tomato', 'Onion', 'Garlic', 
    'Ginger', 'Cream', 'Spinach', 'Potato', 'Cauliflower', 
    'Green Peas', 'Rice', 'Flour', 'Yogurt', 'Cucumber', 'Mint'
  ];

  void _showRecipeDetails(RecipeModel recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => RecipeDetailSheet(
          recipe: recipe, 
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('What to Cook?', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => recipeProvider.clearSelection(),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected ingredients pills bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Available Pantry Ingredients:',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _commonIngredients.length,
                    itemBuilder: (context, idx) {
                      final name = _commonIngredients[idx];
                      final isSelected = recipeProvider.selectedIngredients.contains(name);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (_) => recipeProvider.toggleIngredient(name),
                          selectedColor: primaryColor,
                          backgroundColor: surfaceColor,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Search Matches trigger
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: recipeProvider.selectedIngredients.isEmpty 
                        ? null 
                        : () => recipeProvider.findMatches(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text(
                      'Find Matching Recipes!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Matches Result list
          Expanded(
            child: recipeProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A36)))
                : recipeProvider.recommendedRecipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant, color: Colors.white24, size: 56),
                            const SizedBox(height: 16),
                            Text(
                              recipeProvider.selectedIngredients.isEmpty
                                  ? 'Select ingredients above to begin'
                                  : 'No exact recipe matches found',
                              style: const TextStyle(color: Colors.white38, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: recipeProvider.recommendedRecipes.length,
                        itemBuilder: (context, idx) {
                          final recipe = recipeProvider.recommendedRecipes[idx];
                          final matchScore = ((recipe.matchPercentage ?? 0.0) * 100).round();
                          return GestureDetector(
                            onTap: () => _showRecipeDetails(recipe),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Recipe Image / Thumbnail header
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: recipe.imageUrl.isNotEmpty
                                        ? Image.network(
                                            recipe.imageUrl,
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 140,
                                              color: Colors.white10,
                                              child: const Icon(Icons.image, color: Colors.white24, size: 40),
                                            ),
                                          )
                                        : Container(
                                            height: 140,
                                            color: Colors.white10,
                                            child: const Icon(Icons.image, color: Colors.white24, size: 40),
                                          ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Category & Score row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                recipe.category,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: matchScore > 70 
                                                    ? Colors.green.withValues(alpha: 0.12)
                                                    : Colors.orange.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '$matchScore% Match',
                                                style: TextStyle(
                                                  color: matchScore > 70 ? Colors.greenAccent : Colors.orangeAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Recipe Name
                                        Text(
                                          recipe.recipeName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Metadata
                                        Text(
                                          '${recipe.cookingTime} mins • ${recipe.difficultyLevel} • ${recipe.calories} kcal',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class RecipeDetailSheet extends StatefulWidget {
  final RecipeModel recipe;
  final ScrollController scrollController;

  const RecipeDetailSheet({
    super.key,
    required this.recipe,
    required this.scrollController,
  });

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet> {
  String _mealType = 'Lunch';
  DateTime _selectedDate = DateTime.now();
  bool _isScheduling = false;

  Future<void> _handleSchedule() async {
    setState(() {
      _isScheduling = true;
    });

    final planner = Provider.of<PlannerProvider>(context, listen: false);
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);
    
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        // Pill Indicator
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          widget.recipe.recipeName,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.recipe.category} • ${widget.recipe.cookingTime} mins • ${widget.recipe.difficultyLevel}',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Schedule Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Schedule this Meal',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Date Picker
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.date_range, color: Colors.white70, size: 18),
                      label: Text(
                        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Meal Type Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _mealType,
                      dropdownColor: const Color(0xFF1E1E2C),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isScheduling ? null : _handleSchedule,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.all(12)),
                child: _isScheduling 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Cooking instructions text block
        const Text(
          'Cooking Instructions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          widget.recipe.instructions.replaceAll('\\n', '\n'),
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}
