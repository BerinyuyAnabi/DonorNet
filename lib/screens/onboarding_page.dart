import 'package:flutter/material.dart';
import 'dart:math';
import 'onboarding_screen.dart';

/// The actual onboarding page that defines the 3 steps and wires up navigation.
/// Uses Flutter-drawn illustrations instead of static PNGs for a polished look.

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = [
      OnboardingData(
        title: 'Find Donors',
        subtitle:
            'Find blood donors near you instantly. No more waiting hours or days — connect with the right match in seconds.',
        illustration: const _FindDonorsIllustration(),
      ),
      OnboardingData(
        title: 'Quick & Safe',
        subtitle:
            'All donors are verified and screened. Follow our guidelines to ensure a safe donation experience for everyone.',
        illustration: const _SafeTestingIllustration(),
      ),
      OnboardingData(
        title: 'Save Lives',
        subtitle:
            'Your blood can bring a smile to another person\'s face. Each donation saves up to 3 lives.',
        illustration: const _DonatedIllustration(),
      ),
    ];

    return OnboardingScreen(
      pages: pages,
      finishButtonText: "Let's Begin",
      skipButtonText: 'Skip Step',
      onFinish: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      onSkip: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}

// ILLUSTRATION 1: Find Donors
// A radar/search visual with donor avatars orbiting around a center pin
class _FindDonorsIllustration extends StatelessWidget {
  const _FindDonorsIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
            ),
            // Inner ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF4D6D).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
            ),
            // Inner filled circle
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B8A), Color(0xFFE8446A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            // Donor avatars positioned around
            _positionedAvatar(0, 'K', const Color(0xFF5BA8E0), 130),
            _positionedAvatar(1, 'A', const Color(0xFF4CAF50), 130),
            _positionedAvatar(2, 'Y', const Color(0xFFFF9B50), 130),
            _positionedAvatar(3, 'M', const Color(0xFF7E57C2), 95),
            _positionedAvatar(4, 'E', const Color(0xFF26A69A), 95),
            // Location pin dots
            Positioned(
              top: 30,
              right: 60,
              child: _dot(8, const Color(0xFFFF4D6D).withValues(alpha: 0.5)),
            ),
            Positioned(
              bottom: 50,
              left: 30,
              child: _dot(6, const Color(0xFF5BA8E0).withValues(alpha: 0.5)),
            ),
            Positioned(
              top: 80,
              left: 25,
              child: _dot(10, const Color(0xFFFFD580).withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionedAvatar(int index, String letter, Color color, double radius) {
    final angle = (index * 2 * pi / 5) - pi / 2;
    final x = 140 + radius * cos(angle) - 22;
    final y = 140 + radius * sin(angle) - 22;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ILLUSTRATION 2: Quick & Safe
// A shield with a check mark and safety elements
class _SafeTestingIllustration extends StatelessWidget {
  const _SafeTestingIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background soft circle
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
              ),
            ),
            // Inner soft circle
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              ),
            ),
            // Shield
            Container(
              width: 110,
              height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(55),
                  topRight: Radius.circular(55),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
            // Floating elements
            Positioned(
              top: 30,
              right: 40,
              child: _floatingChip(
                Icons.verified_user_outlined, const Color(0xFF5BA8E0)),
            ),
            Positioned(
              bottom: 40,
              left: 30,
              child: _floatingChip(
                Icons.health_and_safety_outlined, const Color(0xFFFF6B8A)),
            ),
            Positioned(
              top: 50,
              left: 35,
              child: _floatingChip(
                Icons.medical_services_outlined, const Color(0xFF7E57C2)),
            ),
            Positioned(
              bottom: 50,
              right: 35,
              child: _floatingChip(
                Icons.bloodtype_outlined, const Color(0xFFFF9B50)),
            ),
            // Small decorative dots
            Positioned(
              top: 20,
              left: 100,
              child: _smallDot(6, const Color(0xFF4CAF50).withValues(alpha: 0.4)),
            ),
            Positioned(
              bottom: 25,
              right: 90,
              child: _smallDot(8, const Color(0xFF5BA8E0).withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingChip(IconData icon, Color color) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }

  Widget _smallDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ILLUSTRATION 3: Save Lives
// A heart with blood drop and "3 lives" visual
class _DonatedIllustration extends StatelessWidget {
  const _DonatedIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glow circle
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.06),
              ),
            ),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.08),
              ),
            ),
            // Central heart
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B8A), Color(0xFFE8446A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            // 3 people icons representing "3 lives saved"
            Positioned(
              top: 25,
              left: 70,
              child: _lifeCircle('1', const Color(0xFF5BA8E0)),
            ),
            Positioned(
              top: 25,
              right: 70,
              child: _lifeCircle('2', const Color(0xFF4CAF50)),
            ),
            Positioned(
              bottom: 25,
              child: _lifeCircle('3', const Color(0xFF7E57C2)),
            ),
            // Blood drops
            Positioned(
              top: 70,
              right: 45,
              child: Icon(
                Icons.water_drop,
                size: 22,
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.35),
              ),
            ),
            Positioned(
              bottom: 75,
              left: 45,
              child: Icon(
                Icons.water_drop,
                size: 18,
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.25),
              ),
            ),
            Positioned(
              top: 55,
              left: 50,
              child: Icon(
                Icons.water_drop,
                size: 16,
                color: const Color(0xFFFF4D6D).withValues(alpha: 0.2),
              ),
            ),
            // Connecting lines (dashed effect with dots)
            ..._connectingDots(140, 140, 70 + 25, 92, 5),
            ..._connectingDots(140, 140, 210 - 25, 92, 5),
            ..._connectingDots(140, 140, 140, 255 - 25, 5),
          ],
        ),
      ),
    );
  }

  Widget _lifeCircle(String number, Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_rounded, size: 20, color: color),
          Text(
            number,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _connectingDots(
      double cx, double cy, double tx, double ty, int count) {
    final dots = <Widget>[];
    for (int i = 1; i <= count; i++) {
      final t = i / (count + 1);
      final x = cx + (tx - cx) * t - 2;
      final y = cy + (ty - cy) * t - 2;
      dots.add(Positioned(
        left: x,
        top: y,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF4D6D).withValues(alpha: 0.15 + 0.1 * t),
          ),
        ),
      ));
    }
    return dots;
  }
}
