import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/grocery_provider.dart';
import 'screens/login_screen.dart';
import 'screens/portal_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RecipeProvider>(
          create: (ctx) => RecipeProvider(Provider.of<AuthProvider>(ctx, listen: false)),
          update: (ctx, auth, recipe) => recipe!..updateSession(auth.sessionCookie),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PlannerProvider>(
          create: (ctx) => PlannerProvider(Provider.of<AuthProvider>(ctx, listen: false)),
          update: (ctx, auth, planner) => planner!..updateSession(auth.sessionCookie),
        ),
        ChangeNotifierProxyProvider<AuthProvider, GroceryProvider>(
          create: (ctx) => GroceryProvider(Provider.of<AuthProvider>(ctx, listen: false)),
          update: (ctx, auth, grocery) => grocery!..updateSession(auth.sessionCookie),
        ),
      ],
      child: MaterialApp(
        title: 'WhatToCook',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          cardColor: const Color(0xFF1E1E2C),
          primaryColor: const Color(0xFFFF5A36),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF5A36),
            secondary: Color(0xFFFF7A45),
            surface: Color(0xFF1E1E2C),
          ),
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData.dark().textTheme,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading && !auth.isAuthenticated) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, color: Color(0xFFFF5A36), size: 60),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFFF5A36)),
            ],
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const PortalNavigation();
    }

    return const LoginScreen();
  }
}
