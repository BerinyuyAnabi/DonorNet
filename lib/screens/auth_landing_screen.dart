import 'package:flutter/material.dart';
import 'auth_widgets.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            const Spacer(flex: 2),

            const DonorNetLogo(),

            const Spacer(flex: 3),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Column(
                children: [
                  OutlinedActionButton(
                    text: 'Sign Up',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Sign In',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
