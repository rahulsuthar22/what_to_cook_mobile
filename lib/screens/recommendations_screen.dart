import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final List<String> _commonIngredients = [
    'Paneer', 'Tomato', 'Butter', 'Onion', 'Garlic', 
    'Ginger', 'Potato', 'Rice', 'Spinach', 'Egg', 
    'Chicken', 'Carrot', 'Peas', 'Cheese', 'Milk'
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _currentMood = 'Lazy';
  String _currentWeather = 'Sunny';
  String _timeOfDay = 'Lunch';
  final TextEditingController _customIngredientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).fetchRecipes();
    });

    final hours = DateTime.now().hour;
    if (hours >= 5 && hours < 11) {
      _timeOfDay = 'Breakfast';
    } else if (hours >= 11 && hours < 16) {
      _timeOfDay = 'Lunch';
    } else if (hours >= 16 && hours < 22) {
      _timeOfDay = 'Dinner';
    } else {
      _timeOfDay = 'Late Snack';
    }

    final month = DateTime.now().month;
    if (month >= 6 && month <= 9) {
      _currentWeather = 'Rainy';
    } else if (month >= 11 || month <= 2) {
      _currentWeather = 'Chilly';
    } else {
      _currentWeather = 'Sunny';
    }
  }

  List<RecipeModel> _getSmartPicks(List<RecipeModel> allRecipes) {
    if (allRecipes.isEmpty) return [];

    final scored = allRecipes.map((recipe) {
      int score = 0;
      final cat = recipe.category.toLowerCase();
      final name = recipe.recipeName.toLowerCase();

      // Time of Day match
      if (_timeOfDay == 'Breakfast' && cat == 'breakfast') score += 3;
      if (_timeOfDay == 'Lunch' && (cat == 'lunch' || cat == 'main course' || cat == 'curry' || cat == 'rice' || cat == 'salad')) score += 3;
      if (_timeOfDay == 'Dinner' && (cat == 'dinner' || cat == 'main course' || cat == 'curry' || cat == 'pasta')) score += 3;
      if (_timeOfDay == 'Late Snack' && (cat == 'snack' || cat == 'dessert')) score += 3;

      // Weather match
      if (_currentWeather == 'Chilly') {
        if (cat == 'soup' || cat == 'curry' || recipe.cookingTime > 25) score += 2;
      } else if (_currentWeather == 'Rainy') {
        if (cat == 'snack' || name.contains('tea') || name.contains('fry') || name.contains('pakoda') || name.contains('samosa')) score += 2;
      } else if (_currentWeather == 'Sunny') {
        if (cat == 'salad' || cat == 'dessert' || recipe.calories < 450) score += 2;
      }

      // Mood match
      if (_currentMood == 'Lazy') {
        if (recipe.cookingTime <= 20) score += 3;
        if (recipe.difficultyLevel.toLowerCase() == 'easy') score += 1;
      } else if (_currentMood == 'Healthy') {
        if (recipe.calories < 400 || cat == 'salad') score += 3;
      } else if (_currentMood == 'Comfort') {
        if (cat == 'curry' || cat == 'pasta' || recipe.calories > 500) score += 3;
      } else if (_currentMood == 'Fancy') {
        if (recipe.difficultyLevel.toLowerCase() == 'hard' || recipe.difficultyLevel.toLowerCase() == 'medium') score += 2;
        if (recipe.cookingTime > 30) score += 1;
      } else if (_currentMood == 'Sweet') {
        if (cat == 'dessert' || name.contains('sweet') || name.contains('cake') || name.contains('pudding') || name.contains('halwa')) score += 4;
      }

      return _ScoredRecipe(recipe, score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.recipe).take(3).toList();
  }

  void _showRecipeDetails(RecipeModel recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);

    final smartPicks = _getSmartPicks(recipeProvider.recipes);
    final categories = ['All'] + recipeProvider.recipes.map((r) => r.category).toSet().toList();

    final filteredRecipes = recipeProvider.recipes.where((r) {
      final matchesSearch = r.recipeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r.ingredients != null && r.ingredients!.any((ing) => ing.ingredientName.toLowerCase().contains(_searchQuery.toLowerCase())));
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Picks Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.08),
                    const Color(0xFF00B4D8).withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Today's Smart Picks",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⏰ $_timeOfDay',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Mood Selector Row
                  const Text(
                    "What is your current mood?",
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        {'id': 'Lazy', 'label': 'Fast & Lazy ⚡'},
                        {'id': 'Healthy', 'label': 'Healthy & Fit 🥗'},
                        {'id': 'Comfort', 'label': 'Comfort Food 🍔'},
                        {'id': 'Fancy', 'label': 'Gourmet Feast 🍳'},
                        {'id': 'Sweet', 'label': 'Sweet Craving 🍰'},
                      ].map((mood) {
                        final isSelected = _currentMood == mood['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(mood['label']!, style: const TextStyle(fontSize: 11)),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _currentMood = mood['id']!),
                            selectedColor: primaryColor.withValues(alpha: 0.25),
                            backgroundColor: Colors.white.withValues(alpha: 0.03),
                            labelStyle: TextStyle(
                              color: isSelected ? primaryColor : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Weather Selector Row
                  const Text(
                    "How is the weather?",
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      {'id': 'Sunny', 'label': 'Sunny ☀️'},
                      {'id': 'Rainy', 'label': 'Rainy 🌧️'},
                      {'id': 'Chilly', 'label': 'Chilly ❄️'},
                    ].map((weather) {
                      final isSelected = _currentWeather == weather['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(weather['label']!, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _currentWeather = weather['id']!),
                          selectedColor: const Color(0xFF00B4D8).withValues(alpha: 0.25),
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF00B4D8) : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Smart suggestion horizontal cards
                  if (smartPicks.isEmpty)
                    const Center(child: Text("Loading recipes...", style: TextStyle(color: Colors.white38, fontSize: 12)))
                  else
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: smartPicks.length,
                        itemBuilder: (context, idx) {
                          final recipe = smartPicks[idx];
                          return GestureDetector(
                            onTap: () => _showRecipeDetails(recipe),
                            child: Container(
                              width: 240,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: recipe.imageUrl.isNotEmpty
                                        ? Image.network(recipe.imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10, width: 64, height: 64, child: const Icon(Icons.restaurant, color: Colors.white24, size: 24)))
                                        : Container(color: Colors.white10, width: 64, height: 64, child: const Icon(Icons.restaurant, color: Colors.white24, size: 24)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(recipe.category.toUpperCase(), style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(recipe.recipeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('⏱️ ${recipe.cookingTime}m  🔥 ${recipe.calories} kcal', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Pantry Ingredients
            const Text(
              'Select Pantry Ingredients',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Custom manual input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customIngredientController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type an ingredient (e.g. Tomato)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: surfaceColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        recipeProvider.toggleIngredient(val.trim());
                        _customIngredientController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final val = _customIngredientController.text;
                    if (val.trim().isNotEmpty) {
                      recipeProvider.toggleIngredient(val.trim());
                      _customIngredientController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Quick click common ingredients
            const Text("Common Ingredients (Click to add):", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _commonIngredients.map((name) {
                final isSelected = recipeProvider.selectedIngredients.contains(name);
                return ChoiceChip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => recipeProvider.toggleIngredient(name),
                  selectedColor: primaryColor,
                  backgroundColor: surfaceColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Selected tags indicator
            if (recipeProvider.selectedIngredients.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Selected Pantry Items (${recipeProvider.selectedIngredients.length}):", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => recipeProvider.clearSelection(),
                    child: const Text("Clear All", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  )
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recipeProvider.selectedIngredients.map((name) {
                  return Chip(
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                    label: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white54),
                    onDeleted: () => recipeProvider.toggleIngredient(name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Match Trigger Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: recipeProvider.selectedIngredients.isEmpty || recipeProvider.isLoading
                        ? null 
                        : () => recipeProvider.findMatches(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: recipeProvider.isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search, color: Colors.white, size: 20),
                    label: Text(
                      recipeProvider.isLoading ? 'Finding Recipes...' : 'Find Matches!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Suggested Matches Result List
            if (recipeProvider.recommendedRecipes.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.list_alt, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text("Suggested Recipes (${recipeProvider.recommendedRecipes.length})", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recipeProvider.recommendedRecipes.length,
                itemBuilder: (context, idx) {
                  final recipe = recipeProvider.recommendedRecipes[idx];
                  final matchScore = ((recipe.matchPercentage ?? 0.0) * 100).round();
                  return GestureDetector(
                    onTap: () => _showRecipeDetails(recipe),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: recipe.imageUrl.isNotEmpty
                                ? Image.network(recipe.imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 130, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)))
                                : Container(height: 130, color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                                      child: Text(recipe.category, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: matchScore > 70 ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                      child: Text('$matchScore% Match', style: TextStyle(color: matchScore > 70 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(recipe.recipeName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${recipe.cookingTime} mins • ${recipe.difficultyLevel} • ${recipe.calories} kcal', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // Explore All Recipes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Explore All Recipes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${filteredRecipes.length} recipes', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search recipes by name or ingredients...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Category Filter Pills
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: primaryColor,
                      backgroundColor: surfaceColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Filtered Recipes Grid
            if (filteredRecipes.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("No recipes match your criteria", style: TextStyle(color: Colors.white38))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRecipes.length,
                itemBuilder: (context, idx) {
                  final recipe = filteredRecipes[idx];
                  return Card(
                    color: surfaceColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showRecipeDetails(recipe),
                      contentPadding: const EdgeInsets.all(8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: recipe.imageUrl.isNotEmpty
                            ? Image.network(recipe.imageUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.white10, width: 56, height: 56, child: const Icon(Icons.restaurant, color: Colors.white24)))
                            : Container(color: Colors.white10, width: 56, height: 56, child: const Icon(Icons.restaurant, color: Colors.white24)),
                      ),
                      title: Text(recipe.recipeName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${recipe.category} • ${recipe.cookingTime} mins', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoredRecipe {
  final RecipeModel recipe;
  final int score;
  _ScoredRecipe(this.recipe, this.score);
}
