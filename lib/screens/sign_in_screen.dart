import 'package:flutter/material.dart';
import 'auth_widgets.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// SIGN IN FLOW:
  /// 1. Takes email + password from the text fields
  /// 2. Sends them to Firebase Auth via AuthService
  /// 3. Firebase checks credentials — if valid, returns the user
  /// 4. On success: navigate to home (auth state also updates automatically)
  /// 5. On error: show message like "wrong password" or "user not found"
  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.signIn(email: email, password: password);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
      }
    } catch (e) {
      _showError(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.pink),
    );
  }

  Future<void> _handleForgotPassword() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter your email',
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.pink.withValues(alpha: 0.3))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.pink, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send',
                style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;

    try {
      await _authService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent!'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(_friendlyError(e.toString()));
    }
  }

  String _friendlyError(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (error.contains('wrong-password') || error.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (error.contains('invalid-email')) return 'Please enter a valid email.';
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                AuthTopBar(
                  onBack: () => Navigator.of(context).pop(),
                ),

                const Spacer(flex: 2),

                const DonorNetLogo(),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      AuthInputField(
                        label: 'Email',
                        hint: 'someone@gmail.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      AuthInputField(
                        label: 'Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: true,
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32.0, top: 8),
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.pink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.pink))
                      : PrimaryButton(
                          text: 'Sign In',
                          onPressed: _handleSignIn,
                        ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
