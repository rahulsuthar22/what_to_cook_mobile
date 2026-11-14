import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'portal_navigation.dart';
import 'planner_screen.dart';
import 'grocery_screen.dart';
import 'reports_screen.dart';
import 'future_specs_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _dietaryPreference = 'None';
  bool _isSaving = false;

  static const Color _primaryColor = Color(0xFFFF5A36);
  static const Color _bgColor = Color(0xFF0F0F1A);
  static const Color _surfaceColor = Color(0xFF1E1E2C);
  static const Color _surfaceElevated = Color(0xFF282840);

  static const List<String> _dietOptions = [
    'None',
    'Vegetarian',
    'Vegan',
    'Keto',
    'Gluten-Free',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.displayName;
      _phoneController.text = user.mobileNumber;
      _dietaryPreference = user.dietaryPreference.isNotEmpty ? user.dietaryPreference : 'None';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _dietaryPreference,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                success ? 'Profile updated successfully!' : 'Failed to update profile',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: success ? const Color(0xFF06D6A0) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of What to Cook?',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PortalNavigation(initialTab: 0)),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Logged out successfully',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: _surfaceColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final displayName = (user != null && user.displayName.isNotEmpty)
        ? user.displayName
        : 'Chef Explorer';
    final email = user?.email ?? 'user@whattocook.app';
    final phone = (user != null && user.mobileNumber.isNotEmpty)
        ? user.mobileNumber
        : 'No phone linked';
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Zomato/Swiggy Style Profile Card ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24243A), Color(0xFF1E1E2C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar circle with glow
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5A36), Color(0xFFFF7A45)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name, Email, Phone & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _primaryColor.withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: _primaryColor, size: 12),
                                SizedBox(width: 5),
                                Text(
                                  'WhatToCook Member',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ─── Section 1: Food & Kitchen Hub (Features moved from bottom bar) ───
              _buildSectionHeader('MEAL & KITCHEN HUB'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    _buildHubOptionTile(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF00B4D8),
                      title: 'Weekly Meal Planner',
                      subtitle: 'Schedule breakfast, lunch & dinner',
                      badge: 'Planner',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlannerScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildHubOptionTile(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: const Color(0xFF06D6A0),
                      title: 'Grocery Checklist',
                      subtitle: 'Missing ingredients & shopping items',
                      badge: 'Smart List',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GroceryScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildHubOptionTile(
                      icon: Icons.bar_chart_rounded,
                      iconColor: const Color(0xFF8338EC),
                      title: 'Cooking Insights & Stats',
                      subtitle: 'Ingredient metrics & recipe analytics',
                      badge: 'Analytics',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportsScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildHubOptionTile(
                      icon: Icons.smart_toy_rounded,
                      iconColor: _primaryColor,
                      title: 'AI Chef & Smart Tools',
                      subtitle: 'Voice assistant, AI chat & fridge scanner',
                      badge: 'AI Lab',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FutureSpecsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ─── Section 2: Dietary Preferences (Zomato/Swiggy Veg Mode style) ───
              _buildSectionHeader('DIETARY PREFERENCE'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded, color: Color(0xFF06D6A0), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Food Lifestyle Preference',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Filters recipes in Discover & What to Cook feeds',
                                style: TextStyle(color: Colors.white54, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dietOptions.map((diet) {
                        final isSelected = _dietaryPreference.toLowerCase() == diet.toLowerCase();
                        return ChoiceChip(
                          label: Text(
                            diet,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: _primaryColor,
                          backgroundColor: _surfaceElevated,
                          side: BorderSide(
                            color: isSelected
                                ? _primaryColor
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dietaryPreference = diet;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ─── Section 3: Edit Profile Information ───
              _buildSectionHeader('ACCOUNT SETTINGS'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.4), size: 20),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Mobile Number
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.phone_outlined, color: Colors.white.withValues(alpha: 0.4), size: 20),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email (Read only)
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Email Address (Verified)',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withValues(alpha: 0.4), size: 20),
                        suffixIcon: const Icon(Icons.check_circle, color: Color(0xFF06D6A0), size: 18),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check, size: 18, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving Changes...' : 'Save Profile Changes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          disabledBackgroundColor: _primaryColor.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ─── Section 4: Logout Button ───
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showLogoutDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─── Footer: App Info ───
              Center(
                child: Column(
                  children: [
                    Text(
                      'What to Cook • v1.2.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crafted for foodies & smart home cooks',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 11,
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildHubOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Trailing Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 74,
      endIndent: 16,
    );
  }
}
