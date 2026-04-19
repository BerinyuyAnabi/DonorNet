import 'package:flutter/material.dart';
import 'donor_data.dart';

class ProfileScreen extends StatelessWidget {
  final DonorData? donor;

  const ProfileScreen({super.key, this.donor});

  String _bloodTypeLabel(String short) {
    const labels = {
      'A+': 'A Positive (A+)',
      'A-': 'A Negative (A-)',
      'B+': 'B Positive (B+)',
      'B-': 'B Negative (B-)',
      'AB+': 'AB Positive (AB+)',
      'AB-': 'AB Negative (AB-)',
      'O+': 'O Positive (O+)',
      'O-': 'O Negative (O-)',
    };
    return labels[short] ?? short;
  }

  @override
  Widget build(BuildContext context) {
    final name = donor?.name ?? 'Unknown Donor';
    final bloodType = donor?.bloodType ?? '';
    final location = donor?.location ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F8),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Profile" title
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 24,
                bottom: 14,
              ),
              child: const Text(
                'Donor Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8567C),
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Header card with avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD4D4D4), Color(0xFFE8E8E8)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 14,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: const Color(0xFFE8567C).withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 110,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.person, size: 80,
                                  color: Color(0xFFBBBBBB)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar overlapping bottom
                  Positioned(
                    bottom: -32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFF5E6D8),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4A574),
                              ),
                            ),
                          ),
                          if (bloodType.isNotEmpty)
                            Positioned(
                              right: -4,
                              bottom: -2,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE8567C), Color(0xFFFF7EA1)],
                                  ),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    bloodType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 44),

            // Name
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E2C),
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Blood type pill
            if (bloodType.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8E0E4)),
                  ),
                  child: Text(
                    _bloodTypeLabel(bloodType),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8A8A9E),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // Request Now + message icon
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/blood-request'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFCA42), Color(0xFFFFB830)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCA42).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Request Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE8E0E4)),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: Color(0xFFFFCA42),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // About this donor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About this donor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (bloodType.isNotEmpty)
                      _infoRow(Icons.water_drop_rounded, const Color(0xFFE8567C),
                          'Blood Type', bloodType),
                    if (bloodType.isNotEmpty && location.isNotEmpty)
                      const SizedBox(height: 14),
                    if (location.isNotEmpty)
                      _infoRow(Icons.location_on_rounded, const Color(0xFFFF8845),
                          'Location', location),
                    if (donor?.distance.isNotEmpty == true) ...[
                      const SizedBox(height: 14),
                      _infoRow(Icons.straighten_rounded, const Color(0xFF5C9CE6),
                          'Distance', donor!.distance),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A9E))),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E2C))),
          ],
        ),
      ],
    );
  }
}
