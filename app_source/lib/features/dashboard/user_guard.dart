import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/locator.dart';
import '../../../core/services/admin_auth_service.dart';

/// A guard widget that checks if the current user is NOT an admin
/// before allowing access to regular user routes
class UserGuard extends StatelessWidget {
  final Widget child;

  const UserGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final adminAuthService = locator<AdminAuthService>();

    return FutureBuilder<bool>(
      future: adminAuthService.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        // Show loading while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is an admin, redirect to admin dashboard
        if (snapshot.hasData && snapshot.data!) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/admin/dashboard');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not admin, show the child widget
        return child;
      },
    );
  }
}
