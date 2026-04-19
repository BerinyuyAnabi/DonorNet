import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// ROLE SELECTION SCREEN
///
/// Shown right after sign-up (or when an existing user has no role set).
/// The user picks one of two roles:
///
///   "I'm a Donor"     → sees incoming requests, can respond, track donations
///   "I Need Blood"    → can post requests, search for donors, find blood banks
///
/// The role is saved to their Firestore profile as 'donor' or 'requester'.
/// The home screen reads this role and shows different content accordingly.

class _C {
  static const Color pink = Color(0xFFFF4D6D);

  static const Color blue = Color(0xFF5BA8E0);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBg = Color(0xFFFFFFFF);
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _authService = AuthService();
  String? _selectedRole;
  bool _loading = false;

  Future<void> _continue() async {
    if (_selectedRole == null) return;

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save the chosen role to the user's Firestore profile
      await _authService.updateUserProfile(user.uid, {
        'role': _selectedRole,
      });
    }

    if (mounted) {
      // Navigate to home — the router in main.dart will read the role
      // and show the correct home screen.
      Navigator.pushReplacementNamed(context, '/home', arguments: _selectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Header
              const Text(
                'How will you use\nDonorNet?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _C.darkText,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You can always change this later in Settings',
                style: TextStyle(
                  fontSize: 14,
                  color: _C.greyText.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(height: 48),

              // Donor card
              _RoleCard(
                icon: Icons.volunteer_activism_rounded,
                title: "I'm a Donor",
                subtitle: 'I want to donate blood and help save lives',
                color: _C.pink,
                isSelected: _selectedRole == 'donor',
                onTap: () => setState(() => _selectedRole = 'donor'),
              ),

              const SizedBox(height: 20),

              // Requester card
              _RoleCard(
                icon: Icons.bloodtype_rounded,
                title: 'I Need Blood',
                subtitle: 'I want to find donors and request blood',
                color: _C.blue,
                isSelected: _selectedRole == 'requester',
                onTap: () => setState(() => _selectedRole = 'requester'),
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRole == null || _loading
                      ? null
                      : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole == 'donor'
                        ? _C.pink
                        : _C.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _C.greyText.withValues(alpha: 0.2),
                    elevation: _selectedRole != null ? 6 : 0,
                    shadowColor: _selectedRole == 'donor'
                        ? _C.pink.withValues(alpha: 0.4)
                        : _C.blue.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Role Card Widget
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color : _C.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : _C.greyText.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 18),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _C.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : _C.greyText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
