import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  String? _error;

  int _mealsCount = 0;
  int _groceryCount = 0;
  int _recipesCount = 0;
  List<dynamic> _ingredientsStats = [];
  List<dynamic> _recipesStats = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _dio.options.baseUrl = ApiConfig.baseUrl;
      final res = await _dio.get(ApiConfig.statsEndpoint);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final stats = res.data['stats'];
        setState(() {
          _mealsCount = stats['mealPlansCount'] ?? 0;
          _groceryCount = stats['groceryItemsCount'] ?? 0;
          _recipesCount = stats['recipesCount'] ?? 0;
          _ingredientsStats = stats['popularIngredients'] ?? [];
          _recipesStats = stats['popularRecipes'] ?? [];
        });
      }
    } catch (e) {
      _error = 'Failed to retrieve stats: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A36)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStats,
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStats,
                  color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Highlight numbers row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Meals Planned',
                            value: '$_mealsCount',
                            icon: Icons.calendar_month,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Grocery Items',
                            value: '$_groceryCount',
                            icon: Icons.shopping_basket,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Recipes',
                            value: '$_recipesCount',
                            icon: Icons.restaurant,
                            color: Colors.amberAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Health Score',
                            value: '94%',
                            icon: Icons.favorite_border,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Popular ingredients progress list
                    const Text(
                      'Most Used Ingredients',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: _ingredientsStats.isEmpty
                          ? const Center(child: Text('No ingredient stats available', style: TextStyle(color: Colors.white30)))
                          : Column(
                              children: _ingredientsStats.map((ing) {
                                final name = ing['name'] ?? '';
                                final count = ing['count'] ?? 0;
                                final double percent = _mealsCount > 0 ? (count / _mealsCount) : 0.2;
                                final clampPercent = percent.clamp(0.15, 1.0);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          Text('$count times', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: clampPercent,
                                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Top recipes ranking card
                    const Text(
                      'Top Scheduled Recipes',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _recipesStats.isEmpty
                          ? const Center(child: Text('No recipe stats available', style: TextStyle(color: Colors.white30)))
                          : Column(
                              children: List.generate(_recipesStats.length, (idx) {
                                final recipe = _recipesStats[idx];
                                final name = recipe['name'] ?? '';
                                final count = recipe['count'] ?? 0;

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.02),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        '#${idx + 1}',
                                        style: TextStyle(
                                          color: idx == 0 ? Colors.amberAccent : Colors.white24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$count slots',
                                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final surfaceColor = const Color(0xFF1E1E2C);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
