import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum SessionVerificationResult {
  valid,
  invalid,
  networkError,
}

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

      if (_sessionCookie != null) {
        if (userJson != null) {
          _user = UserModel.fromJson(jsonDecode(userJson));
          // Immediately notify to log the user in locally without blocking on backend ping
          notifyListeners();
        }
        
        // Validate session with backend in background (fetches user profile if not cached)
        final result = await verifySession();
        if (result == SessionVerificationResult.invalid) {
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

  Future<SessionVerificationResult> verifySession() async {
    try {
      final res = await _dio.get(ApiConfig.sessionEndpoint);
      if (res.statusCode == 200) {
        if (res.data != null && res.data['user'] != null) {
          final email = res.data['user']['email'];
          final userId = res.data['user']['id'];
          await fetchAndSyncProfile(email, res.data['user']['name'] ?? email.split('@')[0], userId: userId);
          return SessionVerificationResult.valid;
        } else {
          return SessionVerificationResult.invalid;
        }
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return SessionVerificationResult.invalid;
      }
      return SessionVerificationResult.networkError;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return SessionVerificationResult.invalid;
        }
      }
      return SessionVerificationResult.networkError;
    } catch (e) {
      return SessionVerificationResult.networkError;
    }
  }

  Future<void> fetchAndSyncProfile(String email, String name, {String? userId}) async {
    try {
      String targetUid = userId ?? email.hashCode.toString();
      if (userId == null) {
        try {
          final sessionRes = await _dio.get(ApiConfig.sessionEndpoint);
          if (sessionRes.statusCode == 200 && sessionRes.data != null && sessionRes.data['user'] != null) {
            targetUid = sessionRes.data['user']['id'] ?? targetUid;
          }
        } catch (_) {}
      }

      final res = await _dio.post(ApiConfig.syncEndpoint, data: {
        'user_id': targetUid,
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
        csrfCookieHeader = csrfCookies.map((c) => c.split(';').first).join('; ');
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
              ? {'Cookie': csrfCookieHeader}
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
        final sessionCookies = cookies.where(
          (c) => c.contains('next-auth.session-token') || c.contains('__Secure-next-auth.session-token'),
        );

        if (sessionCookies.isNotEmpty) {
          final cleanCookie = sessionCookies.map((c) => c.split(';').first).join('; ');
          _sessionCookie = cleanCookie;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', cleanCookie);

          // Get fresh session details to resolve proper UUID
          final sessionRes = await _dio.get(ApiConfig.sessionEndpoint);
          String? trueUserId;
          String trueName = email.split('@')[0];
          if (sessionRes.statusCode == 200 && sessionRes.data != null && sessionRes.data['user'] != null) {
            trueUserId = sessionRes.data['user']['id'];
            trueName = sessionRes.data['user']['name'] ?? trueName;
          }

          // 4. Sync profile with database
          await fetchAndSyncProfile(email, trueName, userId: trueUserId);
          
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
        csrfCookieHeader = csrfCookies.map((c) => c.split(';').first).join('; ');
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
              ? {'Cookie': csrfCookieHeader}
              : null,
        ),
      );

      if (res.data != null && res.data.toString().contains('error=')) {
        throw Exception('Email registration failed. Account may already exist.');
      }

      final cookies = res.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        final sessionCookies = cookies.where(
          (c) => c.contains('next-auth.session-token') || c.contains('__Secure-next-auth.session-token'),
        );

        if (sessionCookies.isNotEmpty) {
          final cleanCookie = sessionCookies.map((c) => c.split(';').first).join('; ');
          _sessionCookie = cleanCookie;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('session_cookie', cleanCookie);

          // Get fresh session details to resolve proper UUID
          final sessionRes = await _dio.get(ApiConfig.sessionEndpoint);
          String? trueUserId;
          String trueName = name;
          if (sessionRes.statusCode == 200 && sessionRes.data != null && sessionRes.data['user'] != null) {
            trueUserId = sessionRes.data['user']['id'];
            trueName = sessionRes.data['user']['name'] ?? trueName;
          }

          // Sync database details
          await fetchAndSyncProfile(email, trueName, userId: trueUserId);
          
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

  Future<Map<String, dynamic>> loginWithGoogle(String email, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleUserId = 'google_${email.split('@')[0]}_${email.hashCode.abs()}';
      _sessionCookie = 'next-auth.session-token=mock-google-${email.hashCode.abs()}';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_cookie', _sessionCookie!);

      await fetchAndSyncProfile(email, name, userId: googleUserId);

      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogleCookie(String sessionCookie) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessionCookie = sessionCookie;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('session_cookie', sessionCookie);

      // Verify and sync session using next-auth/session endpoint
      final result = await verifySession();
      if (result != SessionVerificationResult.valid) {
        throw Exception('Failed to verify the Google session cookie on the backend');
      }

      _isLoading = false;
      notifyListeners();
      return {'success': true};
    } catch (e) {
      await logout();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString().replaceFirst('Exception: ', '')};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogleNative() async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '1009721326330-jfibeb82fn0sf9iro4rbnmb0eunfu718.apps.googleusercontent.com',
      );
      
      // Force showing account selection dialog by clearing local cache
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': 'Sign-in cancelled'};
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve ID Token from Google');
      }

      // Send ID Token to our backend
      final res = await _dio.post(
        '/api/auth/google-native',
        data: {'idToken': idToken},
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final sessionToken = res.data['sessionToken'] as String;
        final cookieStr = 'next-auth.session-token=$sessionToken';
        
        _sessionCookie = cookieStr;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_cookie', cookieStr);

        final userData = res.data['user'];
        _user = UserModel.fromJson(userData);
        await prefs.setString('user_profile', jsonEncode(_user!.toJson()));

        // Clean up GoogleSignIn session locally so they can select account again next time
        await googleSignIn.signOut();

        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        throw Exception(res.data['error'] ?? 'Authentication failed');
      }
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
