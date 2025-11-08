import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_api_service.dart';
import 'firebase_service.dart';

/// A separate authentication service for admin users.
/// This maintains a separate session from the regular Firebase authentication.
class AdminAuthService extends ChangeNotifier {
  static const String _adminSessionKey = 'admin_session_active';
  static const String _adminEmailKey = 'admin_email';
  static const String _isAdminKey = 'is_admin_user';

  final AdminApiService _adminApiService;
  final FirebaseService _firebaseService;
  bool _isAuthenticated = false;
  String? _adminEmail;

  AdminAuthService(this._adminApiService, this._firebaseService) {
    _loadSession();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get adminEmail => _adminEmail;

  /// Load the admin session from persistent storage
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAuthenticated = prefs.getBool(_adminSessionKey) ?? false;
      _adminEmail = prefs.getString(_adminEmailKey);
      notifyListeners();
    } catch (e) {
      print('Error loading admin session: $e');
      _isAuthenticated = false;
      _adminEmail = null;
    }
  }

  /// Sign in as admin (validates credentials via Firebase Auth and admin API)
  Future<bool> signIn(String email, String password) async {
    try {
      // First check if the email is an authorized admin
      final isAdmin = await _adminApiService.isAdmin(email);

      if (!isAdmin) {
        return false;
      }

      // Verify credentials using Firebase Auth
      await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store the admin session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminSessionKey, true);
      await prefs.setString(_adminEmailKey, email);
      await prefs.setBool(_isAdminKey, true);

      _isAuthenticated = true;
      _adminEmail = email;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Admin sign in error: $e');
      return false;
    }
  }

  /// Sign out the admin user
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminSessionKey);
      await prefs.remove(_adminEmailKey);
      await prefs.remove(_isAdminKey);

      // Also sign out from Firebase
      await _firebaseService.signOut();

      _isAuthenticated = false;
      _adminEmail = null;
      notifyListeners();
    } catch (e) {
      print('Admin sign out error: $e');
    }
  }

  /// Check if the current session is still valid
  Future<bool> validateSession() async {
    if (!_isAuthenticated || _adminEmail == null) {
      return false;
    }

    try {
      // Verify the admin status is still valid
      final isStillAdmin = await _adminApiService.isAdmin(_adminEmail!);

      if (!isStillAdmin) {
        await signOut();
        return false;
      }

      return true;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }

  /// Check if the current user (from SharedPreferences) is an admin
  /// This is checked before opening any dashboard
  Future<bool> isCurrentUserAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isAdminKey) ?? false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
