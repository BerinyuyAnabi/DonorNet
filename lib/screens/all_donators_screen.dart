import 'package:flutter/material.dart';
import 'donor_data.dart';

// Colors
class _C {
  static const Color background = Color(0xFFF5F7FA);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color pinkLight = Color(0xFFFF6B8A);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE8ECF0);
}

class AllDonatorsScreen extends StatelessWidget {
  final String bloodTypeLabel;
  final String bloodTypeShort;
  final String badgeText;
  final int requestCount;
  final List<DonorData> donors;
  final void Function(DonorData donor)? onDonorTap;

  const AllDonatorsScreen({
    super.key,
    required this.bloodTypeLabel,
    required this.bloodTypeShort,
    required this.badgeText,
    required this.requestCount,
    required this.donors,
    this.onDonorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back,
                        color: _C.darkText, size: 24),
                  ),
                  const Expanded(
                    child: Text(
                      'All donators',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _C.darkText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildBloodTypeCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Your $requestCount request available !',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _C.greyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...donors.map((donor) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DonorRow(
                            donor: donor,
                            onTap: () {
                              onDonorTap?.call(donor);
                              Navigator.pushNamed(context, '/profile', arguments: donor);
                            },
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeCard() {
    return Center(
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: CustomPaint(
                      size: const Size(44, 52),
                      painter: _DropPainter(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _C.darkText.withValues(alpha: 0.82),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bloodTypeLabel,
              style: const TextStyle(
                fontSize: 13,
                color: _C.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '($bloodTypeShort)',
              style: const TextStyle(
                fontSize: 12,
                color: _C.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Donor list row
class _DonorRow extends StatelessWidget {
  final DonorData donor;
  final VoidCallback? onTap;

  const _DonorRow({required this.donor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                image: donor.avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: AssetImage(donor.avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: donor.avatarUrl.isEmpty
                  ? Center(
                      child: Text(
                        donor.name.isNotEmpty
                            ? donor.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _C.greyText,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _C.darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 13, color: _C.pinkLight.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text(
                        donor.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.greyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _C.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.inputBorder),
              ),
              child: Text(
                donor.distance,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Blood drop painter
class _DropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.pinkLight
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final top = Offset(cx, cy - size.height * 0.45);
    final bottom = Offset(cx, cy + size.height * 0.3);

    final path = Path();
    path.moveTo(top.dx, top.dy);
    path.quadraticBezierTo(
        cx + size.width * 0.55, cy + size.height * 0.05, bottom.dx, bottom.dy);
    path.quadraticBezierTo(
        cx - size.width * 0.55, cy + size.height * 0.05, top.dx, top.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
