import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/planner_provider.dart';
import '../providers/grocery_provider.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'portal_navigation.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'future_specs_screen.dart';
import 'reports_screen.dart';
import 'planner_screen.dart';
import 'grocery_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _displayedCount = 8;

  static const Color _primaryColor = Color(0xFFFF5A36);
  static const Color _surfaceColor = Color(0xFF1E1E2C);
  static const Color _surfaceElevated = Color(0xFF282840);
  static const Color _bgColor = Color(0xFF0F0F1A);

  static const List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Healthy',
    'Dessert',
    'Indian',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      if (recipeProvider.recipes.isEmpty) {
        recipeProvider.fetchRecipes();
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<PlannerProvider>(context, listen: false).fetchMealPlans();
        Provider.of<GroceryProvider>(context, listen: false).fetchGroceryItems();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 350) {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      if (_displayedCount < recipeProvider.recipes.length) {
        setState(() {
          _displayedCount = (_displayedCount + 6).clamp(0, recipeProvider.recipes.length);
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final plannerProvider = Provider.of<PlannerProvider>(context, listen: false);
    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await recipeProvider.fetchRecipes();
    if (authProvider.isAuthenticated && mounted) {
      await plannerProvider.fetchMealPlans();
      await groceryProvider.fetchGroceryItems();
    }
    if (mounted) {
      setState(() {
        _displayedCount = 8;
      });
    }
  }

  void _showAuthRequiredDialog(String featureName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, color: _primaryColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign In for $featureName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or create an account to save your personal $featureName and access your synced data across devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign In / Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final isAuth = authProvider.isAuthenticated;
    final user = authProvider.user;
    final allRecipes = recipeProvider.recipes;

    // Filter recipes by category and search query
    final filteredRecipes = allRecipes.where((r) {
      final matchesQuery = _searchQuery.isEmpty ||
          r.recipeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' ||
          r.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesQuery && matchesCat;
    }).toList();

    // BuzzFeed Tasty Curated Slices (shown when not searching)
    final spotlightRecipe = allRecipes.isNotEmpty ? allRecipes.first : null;
    final trendingRecipes = allRecipes.length > 1
        ? allRecipes.skip(1).take(8).toList()
        : allRecipes;
    final quickRecipes = allRecipes.where((r) => r.cookingTime > 0 && r.cookingTime <= 30).toList();
    final healthyRecipes = allRecipes
        .where((r) => r.category.toLowerCase() == 'healthy' || r.calories < 450 || r.protein >= 15)
        .toList();

    // Sliced list for the progressive infinite-feed
    final displayedRecipes = filteredRecipes.take(_displayedCount).toList();

    return PopScope(
      canPop: _searchQuery.isEmpty,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_searchQuery.isNotEmpty) {
          setState(() {
            _searchController.clear();
            _searchQuery = '';
            _displayedCount = 8;
          });
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: RefreshIndicator(
            color: _primaryColor,
            backgroundColor: _surfaceColor,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Top Bar: Search Bar + Avatar / Login Button ───
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                                _displayedCount = 8;
                              });
                            },
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search recipes, ingredients...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white.withValues(alpha: 0.45),
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _displayedCount = 8;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // Top Avatar (if logged in) or Login Button (if guest)
                      if (isAuth)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 10),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5A36), Color(0xFFFF7A45)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (user != null && user.displayName.isNotEmpty)
                                  ? user.displayName.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _primaryColor.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, color: _primaryColor, size: 18),
                                SizedBox(width: 5),
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // When actively searching, jump straight to Search Results
                  if (_searchQuery.isNotEmpty) ...[
                    _buildSectionTitle(
                      title: 'Search Results',
                      subtitle: 'Found ${filteredRecipes.length} recipes matching "$_searchQuery"',
                      trailing: TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _displayedCount = 8;
                          });
                        },
                        child: const Text('Clear', style: TextStyle(color: _primaryColor, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildRecipeGrid(displayedRecipes, filteredRecipes),
                  ] else ...[
                    // ─── Welcome Header Banner ───
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withValues(alpha: 0.15),
                            const Color(0xFF00B4D8).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAuth ? 'WELCOME BACK' : 'EXPLORE & DISCOVER',
                                style: const TextStyle(
                                  color: _primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAuth
                                      ? _primaryColor.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAuth ? 'Member' : 'Guest',
                                  style: TextStyle(
                                    color: isAuth ? Colors.white : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAuth
                                ? 'Hello, ${user?.displayName ?? "Chef"}! 👋'
                                : 'Welcome to WhatToCook! 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAuth
                                ? 'Search our full recipe library, match pantry items, or plan upcoming meals.'
                                : 'Discover personalized recipes, watch food reels, and find meals using ingredients you already own.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ─── Accessible Features Section (PRESERVED UNCHANGED) ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isAuth ? 'All Unlocked' : 'Free Access',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _buildFeatureCard(
                          title: 'What to Cook?',
                          subtitle: 'Pantry ingredients match',
                          icon: Icons.auto_awesome,
                          color: _primaryColor,
                          badge: 'Popular',
                          onTap: () {
                            context.findAncestorStateOfType<PortalNavigationState>()?.setTab(1);
                          },
                        ),
                        _buildFeatureCard(
                          title: 'Food Reels',
                          subtitle: 'Watch video tutorials',
                          icon: Icons.play_circle_filled,
                          color: const Color(0xFFFF7A45),
                          badge: 'Video',
                          onTap: () {
                            context.findAncestorStateOfType<PortalNavigationState>()?.setTab(2);
                          },
                        ),
                        _buildFeatureCard(
                          title: 'Weekly Planner',
                          subtitle: isAuth ? 'Schedule diet plans' : 'Sign in to plan',
                          icon: Icons.calendar_today,
                          color: const Color(0xFF00B4D8),
                          isLocked: !isAuth,
                          onTap: () {
                            if (isAuth) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PlannerScreen()),
                              );
                            } else {
                              _showAuthRequiredDialog('Weekly Planner');
                            }
                          },
                        ),
                        _buildFeatureCard(
                          title: 'Grocery List',
                          subtitle: isAuth ? 'Smart shopping list' : 'Sign in to compile',
                          icon: Icons.shopping_bag,
                          color: const Color(0xFF06D6A0),
                          isLocked: !isAuth,
                          onTap: () {
                            if (isAuth) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const GroceryScreen()),
                              );
                            } else {
                              _showAuthRequiredDialog('Grocery List');
                            }
                          },
                        ),
                        _buildFeatureCard(
                          title: 'AI Chef & Specs',
                          subtitle: 'Voice, chat & scanner',
                          icon: Icons.smart_toy_outlined,
                          color: Colors.purpleAccent,
                          onTap: () {
                            if (isAuth) {
                              context.findAncestorStateOfType<PortalNavigationState>()?.setTab(3);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const FutureSpecsScreen()),
                              );
                            }
                          },
                        ),
                        _buildFeatureCard(
                          title: 'Reports & Stats',
                          subtitle: 'Platform analytics',
                          icon: Icons.bar_chart,
                          color: Colors.tealAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ReportsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),

                    // ─── BuzzFeed Tasty Section 1: Recipe of the Day Spotlight ───
                    if (spotlightRecipe != null) ...[
                      _buildSectionTitle(
                        title: "Chef's Spotlight 🌟",
                        subtitle: 'Featured culinary pick of the day',
                      ),
                      _buildSpotlightCard(spotlightRecipe),
                      const SizedBox(height: 26),
                    ],

                    // ─── BuzzFeed Tasty Section 2: Trending Now (Horizontal Rail) ───
                    if (trendingRecipes.isNotEmpty) ...[
                      _buildSectionTitle(
                        title: 'Trending on Tasty 🔥',
                        subtitle: 'Most cooked by home foodies this week',
                      ),
                      _buildHorizontalRail(trendingRecipes),
                      const SizedBox(height: 26),
                    ],

                    // ─── BuzzFeed Tasty Section 3: Quick & Easy (Under 30 Mins) ───
                    if (quickRecipes.isNotEmpty) ...[
                      _buildSectionTitle(
                        title: 'Quick & Easy ⏱',
                        subtitle: 'Delicious recipes in 30 minutes or less',
                      ),
                      _buildHorizontalRail(quickRecipes),
                      const SizedBox(height: 26),
                    ],

                    // ─── BuzzFeed Tasty Section 4: Healthy & Wholesome ───
                    if (healthyRecipes.isNotEmpty) ...[
                      _buildSectionTitle(
                        title: 'Healthy & Wholesome 🥗',
                        subtitle: 'Nutrient-rich, guilt-free culinary wonders',
                      ),
                      _buildHorizontalRail(healthyRecipes),
                      const SizedBox(height: 26),
                    ],

                    // ─── Section 5: Browse by Category Filter Chips ───
                    _buildSectionTitle(
                      title: 'Browse by Category 🏷',
                      subtitle: 'Filter the endless culinary library',
                      trailing: _selectedCategory != 'All'
                          ? GestureDetector(
                              onTap: () => setState(() {
                                _selectedCategory = 'All';
                                _displayedCount = 8;
                              }),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final cat = _categories[idx];
                          final isSelected = _selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat : 'All';
                                _displayedCount = 8;
                              });
                            },
                            selectedColor: _primaryColor,
                            backgroundColor: _surfaceColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isSelected ? _primaryColor : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── BuzzFeed Tasty Section 6: Endless Recipe Feed (Infinite Page) ───
                    _buildSectionTitle(
                      title: _selectedCategory == 'All'
                          ? 'Endless Recipe Feed 🍽'
                          : '$_selectedCategory Recipes',
                      subtitle: _selectedCategory == 'All'
                          ? 'Browse through our complete collection'
                          : 'Showing all recipes tagged under $_selectedCategory',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Text(
                          '${filteredRecipes.length} recipes',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2-Column Responsive Grid with zero dead space
                    _buildRecipeGrid(displayedRecipes, filteredRecipes),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a section header with title, subtitle, and optional trailing widget
  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
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
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Builds the 2-column responsive recipe grid with infinite scroll indicators
  Widget _buildRecipeGrid(List<RecipeModel> displayedList, List<RecipeModel> totalFiltered) {
    final recipeProvider = Provider.of<RecipeProvider>(context);

    if (recipeProvider.isLoading && recipeProvider.recipes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    if (totalFiltered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No recipes match "$_searchQuery"'
                  : 'No recipes found for category "$_selectedCategory"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _displayedCount = 8;
                });
              },
              child: const Text('Clear Filters', style: TextStyle(color: _primaryColor)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.79, // Optimized ratio removing awkward inside gaps
          ),
          itemBuilder: (context, idx) {
            final recipe = displayedList[idx];
            return _buildRecipeCard(recipe);
          },
        ),

        // Infinite Feed Progressive Loader or Caught Up Badge
        if (displayedList.length < totalFiltered.length)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                ),
                const SizedBox(width: 10),
                Text(
                  'Loading more recipes (${displayedList.length} of ${totalFiltered.length})...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF06D6A0), size: 15),
                  SizedBox(width: 6),
                  Text(
                    "You've reached the end of the feed! 👨‍🍳",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the full-width Hero Spotlight Card (BuzzFeed Tasty signature)
  Widget _buildSpotlightCard(RecipeModel recipe) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 195,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Background Image
              recipe.imageUrl.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImageFallback(height: 195),
                    )
                  : _buildImageFallback(height: 195),

              // Gradient Scrim Overlay for crisp text contrast
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Content inside Hero Card
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Spotlight Tag + Rating
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryColor, Color(0xFFFF7A45)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                              SizedBox(width: 5),
                              Text(
                                'RECIPE OF THE DAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              SizedBox(width: 3),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom: Title, Chips & Cook Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.recipeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildHeroPill(Icons.access_time, '${recipe.cookingTime}m'),
                            const SizedBox(width: 6),
                            _buildHeroPill(Icons.local_fire_department_outlined, '${recipe.calories} kcal'),
                            const SizedBox(width: 6),
                            _buildHeroPill(Icons.restaurant_menu, recipe.category),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Cook Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildHeroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a horizontal scrolling Tasty recipe rail
  Widget _buildHorizontalRail(List<RecipeModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
          final recipe = items[idx];
          return _buildHorizontalRecipeCard(recipe);
        },
      ),
    );
  }

  /// Builds a compact horizontal recipe card without internal empty space
  Widget _buildHorizontalRecipeCard(RecipeModel recipe) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
            // Image with badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: recipe.imageUrl.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl,
                          height: 115,
                          width: 190,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImageFallback(height: 115, width: 190),
                        )
                      : _buildImageFallback(height: 115, width: 190),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      recipe.difficultyLevel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 10, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.cookingTime}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (compact, perfectly balanced, NO empty gap)
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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

  /// Builds a modern recipe tile with image, metadata, and detail navigation
  /// Tightened layout removing inside empty space
  Widget _buildRecipeCard(RecipeModel recipe) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
            // Recipe image with floating Tasty-style badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: recipe.imageUrl.isNotEmpty
                      ? Image.network(
                          recipe.imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildImageFallback(height: 120),
                        )
                      : _buildImageFallback(height: 120),
                ),
                // Difficulty badge on top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      recipe.difficultyLevel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Cooking time badge on bottom-right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 10, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.cookingTime}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (compact, perfectly proportioned, NO empty void)
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
                            letterSpacing: 0.5,
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
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),

                    // Nutrition & Rating Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${recipe.calories} kcal',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '4.8',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildImageFallback({double height = 120, double? width}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _surfaceElevated,
            _surfaceColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            color: Colors.white.withValues(alpha: 0.2),
            size: height > 140 ? 38 : 28,
          ),
          if (height > 140) ...[
            const SizedBox(height: 6),
            Text(
              'What to Cook',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a feature shortcut card (PRESERVED UNCHANGED)
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badge,
    bool isLocked = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                if (isLocked)
                  Icon(Icons.lock_outline, size: 14, color: Colors.white.withValues(alpha: 0.4))
                else if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
