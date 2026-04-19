import 'dart:math';
import 'package:flutter/material.dart';
import 'donor_data.dart';

// Colors
class _C {
  static const Color background = Color(0xFFF5F7FA);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkLight = Color(0xFFFF6B8A);
  static const Color mint = Color(0xFF4CD9A0);
  static const Color yellow = Color(0xFFFFBE45);
  static const Color ringLight = Color(0xFFE4EEF5);
  static const Color ringMid = Color(0xFFD4DCF0);
}

class NearbyDonorScreen extends StatefulWidget {
  final List<DonorData> nearbyDonors;
  final VoidCallback? onNext;

  const NearbyDonorScreen({
    super.key,
    required this.nearbyDonors,
    this.onNext,
  });

  @override
  State<NearbyDonorScreen> createState() => _NearbyDonorScreenState();
}

class _NearbyDonorScreenState extends State<NearbyDonorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

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
                  const Spacer(),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            const Text(
              'Search Nearby Donor...',
              style: TextStyle(
                fontSize: 16,
                color: _C.greyText,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return _OrbitalRadar(
                      donors: widget.nearbyDonors,
                      rotation: _rotationController.value * 2 * pi,
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onNext?.call();
                    Navigator.pushNamed(context, '/all-donators');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Orbital radar widget
class _OrbitalRadar extends StatelessWidget {
  final List<DonorData> donors;
  final double rotation;

  const _OrbitalRadar({
    required this.donors,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight) * 0.88;
        final center = size / 2;

        final outerR = size * 0.48;
        final midR = size * 0.33;
        final innerR = size * 0.18;

        final positions = _computePositions(
          center: Offset(center, center),
          donors: donors,
          outerR: outerR,
          midR: midR,
          rotation: rotation,
        );

        final dots = _computeDots(
          center: Offset(center, center),
          outerR: outerR,
          midR: midR,
          rotation: rotation,
        );

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _Ring(center: center, radius: outerR, color: _C.ringLight),
              _Ring(center: center, radius: midR, color: _C.ringMid.withValues(alpha: 0.5)),
              _Ring(center: center, radius: innerR, color: _C.pinkLight.withValues(alpha: 0.15)),

              Positioned(
                left: center - 6,
                top: center - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: _C.pinkLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              ...dots,
              ...positions,
            ],
          ),
        );
      },
    );
  }

  List<Widget> _computePositions({
    required Offset center,
    required List<DonorData> donors,
    required double outerR,
    required double midR,
    required double rotation,
  }) {
    final widgets = <Widget>[];
    final radii = [outerR, midR, outerR, midR, outerR];
    final sizes = [52.0, 64.0, 46.0, 56.0, 72.0];

    for (int i = 0; i < min(donors.length, 5); i++) {
      final angle = rotation + (i * 2 * pi / min(donors.length, 5));
      final r = radii[i % radii.length];
      final s = sizes[i % sizes.length];
      final x = center.dx + r * cos(angle) - s / 2;
      final y = center.dy + r * sin(angle) - s / 2;

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: _DonorAvatar(
            donor: donors[i],
            size: s,
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _computeDots({
    required Offset center,
    required double outerR,
    required double midR,
    required double rotation,
  }) {
    final dotData = <_DotInfo>[
      _DotInfo(angle: rotation * 0.7 + 0.5, radius: outerR * 1.02, size: 14, color: _C.blue),
      _DotInfo(angle: rotation * 0.5 + 2.0, radius: midR * 0.9, size: 10, color: _C.mint),
      _DotInfo(angle: rotation * 0.6 + 3.5, radius: outerR * 0.85, size: 8, color: _C.greyText.withValues(alpha: 0.4)),
      _DotInfo(angle: rotation * 0.4 + 1.0, radius: outerR * 1.1, size: 16, color: _C.yellow),
      _DotInfo(angle: rotation * 0.8 + 4.0, radius: midR * 1.2, size: 10, color: _C.mint),
      _DotInfo(angle: rotation * 0.3 + 5.0, radius: outerR * 0.6, size: 12, color: _C.yellow),
      _DotInfo(angle: rotation * 0.9 + 2.5, radius: outerR * 1.15, size: 9, color: _C.blue),
    ];

    return dotData.map((d) {
      final x = center.dx + d.radius * cos(d.angle) - d.size / 2;
      final y = center.dy + d.radius * sin(d.angle) - d.size / 2;
      return Positioned(
        left: x,
        top: y,
        child: Container(
          width: d.size,
          height: d.size,
          decoration: BoxDecoration(
            color: d.color,
            shape: BoxShape.circle,
          ),
        ),
      );
    }).toList();
  }
}

class _DotInfo {
  final double angle;
  final double radius;
  final double size;
  final Color color;
  const _DotInfo({
    required this.angle,
    required this.radius,
    required this.size,
    required this.color,
  });
}

// Ring
class _Ring extends StatelessWidget {
  final double center;
  final double radius;
  final Color color;

  const _Ring({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center - radius,
      top: center - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.2),
        ),
      ),
    );
  }
}

// Donor avatar circle
class _DonorAvatar extends StatelessWidget {
  final DonorData donor;
  final double size;

  const _DonorAvatar({required this.donor, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                donor.name.isNotEmpty ? donor.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w700,
                  color: _C.greyText,
                ),
              ),
            )
          : null,
    );
  }
}
