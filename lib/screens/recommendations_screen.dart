import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/grocery_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'portal_navigation.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  // ─── Constants & Colors ───
  static const Color _primaryColor = Color(0xFFFF5A36);
  static const Color _surfaceColor = Color(0xFF1E1E2C);
  static const Color _surfaceElevated = Color(0xFF282840);
  static const Color _bgColor = Color(0xFF0F0F1A);
  static const Color _successGreen = Color(0xFF06D6A0);

  // ─── State Controllers & Selection ───
  final TextEditingController _customIngredientController = TextEditingController();
  int _shuffleIndex = 0;
  String _selectedPantryTab = 'Popular Staples';
  String _selectedMood = 'All'; // 'All', 'Quick', 'Healthy', 'Comfort', 'Sweet'
  String _mealWindow = 'Dinner';
  String _mealEmoji = '🍲';

  // ─── Pantry Taxonomy ───
  static const Map<String, List<String>> _pantryCategories = {
    'Popular Staples': [
      'Onion', 'Tomato', 'Potato', 'Garlic', 'Ginger', 
      'Paneer', 'Cheese', 'Butter', 'Egg', 'Chicken',
      'Rice', 'Spinach', 'Milk', 'Carrot', 'Peas'
    ],
    'Veggies 🥦': [
      'Tomato', 'Onion', 'Potato', 'Spinach', 'Carrot', 
      'Peas', 'Capsicum', 'Green Chili', 'Garlic', 'Ginger',
      'Coriander', 'Cauliflower', 'Mushroom'
    ],
    'Dairy & Eggs 🧀': [
      'Paneer', 'Butter', 'Milk', 'Cheese', 'Cream', 
      'Egg', 'Yogurt', 'Ghee'
    ],
    'Protein & Meat 🍗': [
      'Chicken', 'Egg', 'Fish', 'Mutton', 'Paneer', 'Tofu'
    ],
    'Grains & Flour 🍚': [
      'Rice', 'Wheat Flour', 'Pasta', 'Oats', 'Bread', 'Noodles'
    ],
  };

  @override
  void initState() {
    super.initState();
    _determineMealWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      if (recipeProvider.recipes.isEmpty) {
        recipeProvider.fetchRecipes();
      }
    });
  }

  @override
  void dispose() {
    _customIngredientController.dispose();
    super.dispose();
  }

  void _determineMealWindow() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      _mealWindow = 'Breakfast';
      _mealEmoji = '☀️';
    } else if (hour >= 11 && hour < 16) {
      _mealWindow = 'Lunch';
      _mealEmoji = '🥪';
    } else if (hour >= 16 && hour < 22) {
      _mealWindow = 'Dinner';
      _mealEmoji = '🍲';
    } else {
      _mealWindow = 'Late Night Snack';
      _mealEmoji = '🌙';
    }
  }

  void _showRecipeDetails(RecipeModel recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  void _addMissingToGrocery(String ingredientName) async {
    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
    final success = await groceryProvider.addCustomItem(ingredientName, 'as needed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                success ? 'Added "$ingredientName" to Grocery Checklist' : 'Sign in to sync Grocery Checklist',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          backgroundColor: success ? _successGreen : _surfaceColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─── Modal Bottom Sheet for "What's in your Kitchen?" ───
  void _openKitchenPantryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final recipeProvider = Provider.of<RecipeProvider>(context);
            final selectedPantry = recipeProvider.selectedIngredients;

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Color(0xFF181826),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // 1. Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 2. Modal Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  "What's in your Kitchen?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text('🍳', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Select items you currently have at home',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (selectedPantry.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              recipeProvider.clearSelection();
                              setModalState(() {});
                            },
                            child: const Text(
                              'Reset All',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),

                  // 3. Scrollable Modal Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search / Add Custom Ingredient
                          Container(
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.search, size: 18, color: Colors.white.withValues(alpha: 0.4)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _customIngredientController,
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Type any item (e.g. Mushroom, Pasta)...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.35),
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onSubmitted: (val) {
                                      if (val.trim().isNotEmpty) {
                                        recipeProvider.toggleIngredient(val.trim());
                                        _customIngredientController.clear();
                                        setModalState(() {});
                                      }
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final val = _customIngredientController.text;
                                    if (val.trim().isNotEmpty) {
                                      recipeProvider.toggleIngredient(val.trim());
                                      _customIngredientController.clear();
                                      setModalState(() {});
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Add', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Active Selected Chips in Modal
                          if (selectedPantry.isNotEmpty) ...[
                            Text(
                              'Selected Ingredients (${selectedPantry.length}):',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: selectedPantry.map((item) {
                                return Chip(
                                  backgroundColor: _primaryColor.withValues(alpha: 0.18),
                                  side: BorderSide(color: _primaryColor.withValues(alpha: 0.35)),
                                  label: Text(item, style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                                  deleteIcon: const Icon(Icons.close, size: 13, color: Colors.white70),
                                  onDeleted: () {
                                    recipeProvider.toggleIngredient(item);
                                    setModalState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // Category Tabs
                          const Text(
                            'Quick Add by Category',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _pantryCategories.keys.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, idx) {
                                final tab = _pantryCategories.keys.elementAt(idx);
                                final isSelected = _selectedPantryTab == tab;
                                return InkWell(
                                  onTap: () => setModalState(() => _selectedPantryTab = tab),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _primaryColor.withValues(alpha: 0.2)
                                          : _surfaceColor,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryColor
                                            : Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Text(
                                      tab,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ingredient Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_pantryCategories[_selectedPantryTab] ?? []).map((name) {
                              final isSelected = selectedPantry.contains(name);
                              return FilterChip(
                                avatar: Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  size: 15,
                                  color: isSelected ? Colors.white : Colors.white54,
                                ),
                                label: Text(name),
                                selected: isSelected,
                                onSelected: (_) {
                                  recipeProvider.toggleIngredient(name);
                                  setModalState(() {});
                                },
                                selectedColor: _primaryColor,
                                backgroundColor: _surfaceColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: isSelected ? _primaryColor : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Fixed Bottom Apply Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            recipeProvider.findMatches();
                            Navigator.pop(ctx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: _successGreen, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      selectedPantry.isNotEmpty
                                          ? 'Kitchen filter applied (${selectedPantry.length} items)'
                                          : 'Showing all curated recipes',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                backgroundColor: _surfaceElevated,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: Text(
                            selectedPantry.isNotEmpty
                                ? 'Apply Filter (${selectedPantry.length} Ingredients)'
                                : 'Show All Recipes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Intelligent Ranking Algorithm ───
  List<RecipeModel> _getRankedCandidates(List<RecipeModel> allRecipes, List<String> selectedPantry) {
    if (allRecipes.isEmpty) return [];

    // Filter by mood/craving first if set
    List<RecipeModel> baseList = allRecipes.where((r) {
      if (_selectedMood == 'Quick' && r.cookingTime > 20) return false;
      if (_selectedMood == 'Healthy' && (r.calories > 450 && r.category.toLowerCase() != 'healthy')) return false;
      if (_selectedMood == 'Comfort' && r.calories < 400 && r.category.toLowerCase() != 'dinner') return false;
      if (_selectedMood == 'Sweet' && !r.category.toLowerCase().contains('dessert') && !r.recipeName.toLowerCase().contains('sweet')) return false;
      return true;
    }).toList();

    if (baseList.isEmpty) baseList = allRecipes;

    // Score based on meal window and selected pantry ingredients
    final scored = baseList.map((recipe) {
      double score = 0;
      final cat = recipe.category.toLowerCase();

      // Meal time affinity
      if (_mealWindow == 'Breakfast' && cat == 'breakfast') score += 15;
      if (_mealWindow == 'Lunch' && (cat == 'lunch' || cat == 'main course' || cat == 'curry' || cat == 'rice')) score += 15;
      if (_mealWindow == 'Dinner' && (cat == 'dinner' || cat == 'main course' || cat == 'curry' || cat == 'pasta')) score += 15;
      if (_mealWindow == 'Late Night Snack' && (cat == 'snack' || cat == 'dessert')) score += 15;

      // Pantry matching score
      if (selectedPantry.isNotEmpty) {
        int matches = 0;
        final recipeLower = recipe.recipeName.toLowerCase();
        for (final item in selectedPantry) {
          final itemLower = item.toLowerCase();
          if (recipeLower.contains(itemLower)) {
            matches += 2;
          }
          if (recipe.ingredients != null &&
              recipe.ingredients!.any((i) => i.ingredientName.toLowerCase().contains(itemLower))) {
            matches += 1;
          }
        }
        score += matches * 20;
      }

      return _ScoredRecipe(recipe, score.toInt());
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.recipe).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final allRecipes = recipeProvider.recipes;
    final selectedPantry = recipeProvider.selectedIngredients;
    final recommendedRecipes = recipeProvider.recommendedRecipes;

    final candidates = _getRankedCandidates(allRecipes, selectedPantry);
    final heroRecipe = candidates.isNotEmpty ? candidates[_shuffleIndex % candidates.length] : null;

    // Active displayed list (from server recommendations if present, otherwise ranked candidates)
    final List<RecipeModel> displayResults = recommendedRecipes.isNotEmpty ? recommendedRecipes : candidates;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'What to Cook Today?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
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
        actions: [
          if (selectedPantry.isNotEmpty || _selectedMood != 'All')
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'Reset all filters',
              onPressed: () {
                recipeProvider.clearSelection();
                setState(() {
                  _selectedMood = 'All';
                  _shuffleIndex = 0;
                });
              },
            ),
        ],
      ),
      // ─── Floating Action Button: What's in your Kitchen? ───
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _openKitchenPantryModal,
          backgroundColor: _primaryColor,
          elevation: 0,
          icon: const Icon(Icons.kitchen_rounded, color: Colors.white, size: 20),
          label: Text(
            selectedPantry.isNotEmpty
                ? "Kitchen Filter (${selectedPantry.length}) 🍳"
                : "What's in your Kitchen? 🍳",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        backgroundColor: _surfaceColor,
        onRefresh: () => recipeProvider.fetchRecipes(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 86), // Extra bottom padding for floating button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. Instant Decider Header ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$_mealWindow Decision Hub',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_mealEmoji, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Instant recommendation • Tap roll to shuffle',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _mealWindow.toUpperCase(),
                      style: const TextStyle(
                        color: _primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ─── 2. Hero Decider Card (Instant Answer with Roll Action) ───
              if (heroRecipe != null)
                _buildHeroDeciderCard(heroRecipe, candidates.length)
              else
                _buildLoadingPlaceholder(),

              const SizedBox(height: 22),

              // ─── 3. Kitchen Pantry Filter Status Banner ───
              if (selectedPantry.isNotEmpty)
                _buildActiveKitchenBanner(selectedPantry, displayResults.length)
              else
                _buildKitchenPantryShortcutBanner(),

              const SizedBox(height: 22),

              // ─── 4. Cravings & Speed Filter ───
              _buildSectionTitle(
                title: '⚡ Mood & Quick Filters',
                subtitle: 'Pick by cooking speed, calorie count, or appetite',
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMoodFilterChip('All', 'Everything 🍽', Icons.restaurant_menu),
                    const SizedBox(width: 8),
                    _buildMoodFilterChip('Quick', 'Under 20m ⚡', Icons.flash_on_rounded),
                    const SizedBox(width: 8),
                    _buildMoodFilterChip('Healthy', 'Healthy & Fit 🥗', Icons.spa_rounded),
                    const SizedBox(width: 8),
                    _buildMoodFilterChip('Comfort', 'Comfort Food 🍔', Icons.favorite_rounded),
                    const SizedBox(width: 8),
                    _buildMoodFilterChip('Sweet', 'Sweet Tooth 🍰', Icons.cake_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ─── 5. Results & Recommendations Feed ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPantry.isNotEmpty
                            ? 'Matched for your Pantry (${displayResults.length})'
                            : 'Curated Picks for You (${displayResults.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedPantry.isNotEmpty
                            ? 'Sorted by available ingredients'
                            : 'Perfect for $_mealWindow • Ready to cook',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  if (recipeProvider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Responsive 2-Column Recipe Grid with zero dead space
              if (displayResults.isEmpty)
                _buildEmptyResultsState(selectedPantry.isNotEmpty)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayResults.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.77,
                  ),
                  itemBuilder: (context, idx) {
                    final recipe = displayResults[idx];
                    return _buildSolutionRecipeCard(recipe, selectedPantry);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper UI Builders ───

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  /// Banner displayed when kitchen pantry filter is active on the page
  Widget _buildActiveKitchenBanner(List<String> selectedPantry, int matchCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.16),
            const Color(0xFF00B4D8).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.kitchen_rounded, color: _primaryColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kitchen Filter Active (${selectedPantry.length} items)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _openKitchenPantryModal,
                    icon: const Icon(Icons.edit_outlined, size: 14, color: _primaryColor),
                    label: const Text('Edit', style: TextStyle(color: _primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Provider.of<RecipeProvider>(context, listen: false).clearSelection();
                      setState(() {});
                    },
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: selectedPantry.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Inviting banner displayed when no pantry filters are active
  Widget _buildKitchenPantryShortcutBanner() {
    return InkWell(
      onTap: _openKitchenPantryModal,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.kitchen_rounded, color: _primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What's in your Kitchen?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to match dishes with ingredients in your fridge',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodFilterChip(String id, String label, IconData icon) {
    final isSelected = _selectedMood == id;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedMood = id),
      selectedColor: _primaryColor,
      backgroundColor: _surfaceColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? _primaryColor : Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  /// Builds the Hero Decider Card with primary CTA and Roll Again action
  Widget _buildHeroDeciderCard(RecipeModel recipe, int totalCandidates) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Image with overlay chips
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: recipe.imageUrl.isNotEmpty
                    ? Image.network(
                        recipe.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackHeroImage(),
                      )
                    : _buildFallbackHeroImage(),
              ),
              // Top Overlay Tag
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'TOP PICK FOR ${_mealWindow.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Right Duration
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.cookingTime} mins',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      recipe.category.toUpperCase(),
                      style: const TextStyle(color: _primaryColor, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•   ${recipe.calories} kcal',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recipe.difficultyLevel.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.recipeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                // Handy Actions: Let's Cook & Roll Again
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _showRecipeDetails(recipe),
                        icon: const Icon(Icons.restaurant, color: Colors.white, size: 16),
                        label: const Text(
                          "Let's Cook This! 👨‍🍳",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: totalCandidates > 1
                            ? () {
                                setState(() {
                                  _shuffleIndex++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.white70, size: 16),
                        label: const Text(
                          'Roll 🎲',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds optimized, compact recipe card with match badge and zero internal dead space
  Widget _buildSolutionRecipeCard(RecipeModel recipe, List<String> selectedPantry) {
    final hasMatchPercentage = recipe.matchPercentage != null;
    final int matchScore = hasMatchPercentage
        ? (recipe.matchPercentage! > 1.0 ? recipe.matchPercentage!.round() : (recipe.matchPercentage! * 100).round())
        : 0;

    final isFullMatch = matchScore >= 100;
    final isGoodMatch = matchScore >= 50;

    return InkWell(
      onTap: () => _showRecipeDetails(recipe),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFullMatch
                ? _successGreen.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: recipe.imageUrl.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl,
                          height: 115,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackTileImage(),
                        )
                      : _buildFallbackTileImage(),
                ),
                // Top-Left: Match or Difficulty badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: hasMatchPercentage
                          ? (isFullMatch ? _successGreen : (isGoodMatch ? Colors.orangeAccent : Colors.black87))
                          : Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      hasMatchPercentage
                          ? (isFullMatch ? '100% MATCH' : '$matchScore% MATCH')
                          : recipe.difficultyLevel.toUpperCase(),
                      style: TextStyle(
                        color: hasMatchPercentage && (isFullMatch || isGoodMatch) ? Colors.black : Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                // Bottom-Right: Duration
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 9, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.cookingTime}m',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (compact, balanced, zero wasted empty void)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.category.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _primaryColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recipe.recipeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Calories / Missing Item
                    if (recipe.missingIngredients != null && recipe.missingIngredients!.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Missing: ${recipe.missingIngredients!.first}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _addMissingToGrocery(recipe.missingIngredients!.first),
                            child: const Icon(Icons.add_shopping_cart, size: 14, color: _primaryColor),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${recipe.calories} kcal',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                          const SizedBox(width: 2),
                          const Text(
                            '4.8',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResultsState(bool hadPantryFilter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.kitchen_outlined, size: 48, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            hadPantryFilter
                ? 'No recipes match all chosen items'
                : 'No recipes found for the selected craving',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            hadPantryFilter
                ? 'Try adding staples like Onion, Tomato, or Paneer, or clear filters to view curated meals.'
                : 'Try switching to another mood filter like Quick or Comfort food.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Provider.of<RecipeProvider>(context, listen: false).clearSelection();
              setState(() {
                _selectedMood = 'All';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: _primaryColor),
    );
  }

  Widget _buildFallbackHeroImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: _surfaceElevated,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant_menu_rounded, color: Colors.white.withValues(alpha: 0.25), size: 48),
    );
  }

  Widget _buildFallbackTileImage() {
    return Container(
      height: 115,
      width: double.infinity,
      color: _surfaceElevated,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant_rounded, color: Colors.white.withValues(alpha: 0.2), size: 28),
    );
  }
}

class _ScoredRecipe {
  final RecipeModel recipe;
  final int score;
  _ScoredRecipe(this.recipe, this.score);
}
