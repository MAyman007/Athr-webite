import 'package:flutter/foundation.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_auth_service.dart';

class AdminLoginViewModel extends ChangeNotifier {
  final AdminAuthService _adminAuthService = locator<AdminAuthService>();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the admin auth service (which checks admin status and validates with Firebase)
      final success = await _adminAuthService.signIn(email, password);

      if (!success) {
        _errorMessage =
            'Invalid credentials or this email is not an authorized admin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
