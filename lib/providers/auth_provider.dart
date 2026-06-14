import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  UserModel? _user;
  bool _isLoading = false;
  String? _sessionCookie;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get sessionCookie => _sessionCookie;

  AuthProvider() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add Interceptor to automatically append NextAuth session cookie
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_sessionCookie != null) {
          options.headers['Cookie'] = _sessionCookie;
        }
        return handler.next(options);
      },
    ));
    
    _loadSession();
  }

  // Set custom baseUrl at runtime (helpful for testing on dynamic IPs)
  void setBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    notifyListeners();
  }

  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionCookie = prefs.getString('session_cookie');
      final userJson = prefs.getString('user_profile');

      if (_sessionCookie != null && userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
        
        // Validate session with backend
        final valid = await verifySession();
        if (!valid) {
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifySession() async {
    try {
      final res = await _dio.get(ApiConfig.sessionEndpoint);
      if (res.statusCode == 200 && res.data != null && res.data['user'] != null) {
        // Re-sync profile to ensure fresh database values
        final email = res.data['user']['email'];
        await fetchAndSyncProfile(email, res.data['user']['name'] ?? email.split('@')[0]);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchAndSyncProfile(String email, String name) async {
    try {
      final res = await _dio.post(ApiConfig.syncEndpoint, data: {
        'user_id': email.hashCode.toString(), // Consistent hash-based ID matching route.ts authorization
        'full_name': name,
        'email': email,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(_user!.toJson()));
      }
    } catch (e) {
      debugPrint('Sync profile error: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get CSRF Token
      final csrfRes = await _dio.get(ApiConfig.csrfEndpoint);
      final String? csrfToken = csrfRes.data['csrfToken'];
      if (csrfToken == null) {
        throw Exception('Failed to obtain NextAuth CSRF token');
      }

      final csrfCookies = csrfRes.headers['set-cookie'];
      String? csrfCookieHeader;
      if (csrfCookies != null && csrfCookies.isNotEmpty) {
        csrfCookieHeader = csrfCookies.firstWhere(
          (c) => c.contains('next-auth.csrf-token') || c.contains('__Secure-next-auth.csrf-token'),
          orElse: () => '',
        );
      }

      // 2. Perform Credentials SignIn
      final res = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {
          'csrfToken': csrfToken,
          'email': email,
          'password': password,
          'json': 'true',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => (status ?? 500) < 500,
          headers: csrfCookieHeader != null && csrfCookieHeader.isNotEmpty
              ? {'Cookie': csrfCookieHeader.split(';').first}
              : null,
        ),
      );

      // Check if signIn response indicates error redirect or error in body
      if (res.data != null && res.data.toString().contains('error=')) {
        throw Exception('Invalid credentials or authentication error');
      }

      // 3. Extract Session Cookie
      final cookies = res.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        // Extract next-auth.session-token
        final sessionCookie = cookies.firstWhere(
          (c) => c.contains('next-auth.session-token') || c.contains('__Secure-next-auth.session-token'),
          orElse: () => '',
        );

        if (sessionCookie.isNotEmpty) {
          // Clean cookie string to extract just the token part
          final cleanCookie = sessionCookie.split(';').first;
          _sessionCookie = cleanCookie;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', cleanCookie);

          // 4. Sync profile with database
          await fetchAndSyncProfile(email, email.split('@')[0]);
          
          _isLoading = false;
          notifyListeners();
          return {'success': true};
        }
      }
      
      throw Exception('Session token cookie not returned by authorization callback');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<Map<String, dynamic>> register(
    String name, 
    String email, 
    String phone, 
    String preference, 
    String password
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In production scalability, we can submit directly to signin/credentials flow.
      // The NextAuth authorization callback handles password hashing and upserting users into PostgreSQL.
      // So we can hit credentials login directly with the user profile metadata!
      final csrfRes = await _dio.get(ApiConfig.csrfEndpoint);
      final String? csrfToken = csrfRes.data['csrfToken'];
      if (csrfToken == null) {
        throw Exception('Failed to obtain NextAuth CSRF token');
      }

      final csrfCookies = csrfRes.headers['set-cookie'];
      String? csrfCookieHeader;
      if (csrfCookies != null && csrfCookies.isNotEmpty) {
        csrfCookieHeader = csrfCookies.firstWhere(
          (c) => c.contains('next-auth.csrf-token') || c.contains('__Secure-next-auth.csrf-token'),
          orElse: () => '',
        );
      }

      // Post registration parameters directly to NextAuth credentials logic
      final res = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {
          'csrfToken': csrfToken,
          'email': email,
          'password': password,
          'fullName': name,
          'mobileNumber': phone,
          'dietaryPreference': preference,
          'isRegistering': 'true', // Signal to NextAuth credentials flow to register
          'json': 'true',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => (status ?? 500) < 500,
          headers: csrfCookieHeader != null && csrfCookieHeader.isNotEmpty
              ? {'Cookie': csrfCookieHeader.split(';').first}
              : null,
        ),
      );

      if (res.data != null && res.data.toString().contains('error=')) {
        throw Exception('Email registration failed. Account may already exist.');
      }

      final cookies = res.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        final sessionCookie = cookies.firstWhere(
          (c) => c.contains('next-auth.session-token') || c.contains('__Secure-next-auth.session-token'),
          orElse: () => '',
        );

        if (sessionCookie.isNotEmpty) {
          final cleanCookie = sessionCookie.split(';').first;
          _sessionCookie = cleanCookie;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', cleanCookie);

          // Sync database details
          await fetchAndSyncProfile(email, name);
          
          _isLoading = false;
          notifyListeners();
          return {'success': true};
        }
      }
      throw Exception('Registration succeeded but session could not be established');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<bool> updateProfile(String name, String phone, String preference) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.post(ApiConfig.syncEndpoint, data: {
        'user_id': _user!.uid,
        'full_name': name,
        'email': _user!.email,
        'mobile_number': phone,
        'dietary_preference': preference,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Update profile error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_cookie');
    await prefs.remove('user_profile');
    notifyListeners();
  }
}
