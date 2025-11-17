import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'login_page.dart';
import 'theme.dart';

/// Handles Firebase auth action codes from email links
/// (password reset, email verification, etc.)
class AuthActionHandler extends StatefulWidget {
  const AuthActionHandler({Key? key}) : super(key: key);

  @override
  State<AuthActionHandler> createState() => _AuthActionHandlerState();
}

class _AuthActionHandlerState extends State<AuthActionHandler> {
  bool _isLoading = true;
  String? _mode;
  String? _actionCode;
  String? _email;
  String? _errorMessage;
  bool _codeVerified = false;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _handleActionCode();
  }

  Future<void> _handleActionCode() async {
    try {
      if (!kIsWeb) {
        setState(() {
          _errorMessage = 'This feature is only available on web';
          _isLoading = false;
        });
        return;
      }

      // Get URL parameters
      final uri = Uri.parse(html.window.location.href);
      final mode = uri.queryParameters['mode'];
      final actionCode = uri.queryParameters['oobCode'];

      debugPrint('Auth action handler - mode: $mode, code: $actionCode');

      if (mode == null || actionCode == null) {
        setState(() {
          _errorMessage = 'Invalid or missing action code';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _mode = mode;
        _actionCode = actionCode;
      });

      // Verify the action code is valid
      final info = await FirebaseAuth.instance.checkActionCode(actionCode);
      debugPrint('Action code verified, operation: ${info.operation}');

      setState(() {
        _email = info.data['email'] as String?;
        _codeVerified = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error handling action code: $e');
      setState(() {
        _errorMessage = 'Invalid or expired link: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isResetting = true);

    try {
      // Confirm the password reset with the action code and new password
      await FirebaseAuth.instance.confirmPasswordReset(
        code: _actionCode!,
        newPassword: newPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successful! You can now sign in.'),
            backgroundColor: Colors.green,
          ),
        );

        // Redirect to login after 2 seconds
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryLight,
              AppTheme.primaryVariant,
              AppTheme.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Verifying link...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 24),
          const Text(
            'Link Error',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    if (_mode == 'resetPassword' && _codeVerified) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_reset, size: 80, color: AppTheme.primary),
          const SizedBox(height: 24),
          const Text(
            'Reset Your Password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_email != null)
            Text(
              'for $_email',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          const SizedBox(height: 32),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResetting ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResetting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(
              'Back to Login',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      );
    }

    // Handle other action modes (email verification, etc.)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.help_outline, size: 80, color: Colors.orange[400]),
        const SizedBox(height: 24),
        Text(
          'Action: ${_mode ?? 'unknown'}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
