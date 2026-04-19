import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B8A),
                  Color(0xFFEF4F6F),
                  Color(0xFFE8446A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Decorative blobs
          Positioned(
            top: -60,
            right: -80,
            child: _BlobShape(
              width: 300,
              height: 280,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: -100,
            child: _BlobShape(
              width: 250,
              height: 200,
              color: Colors.white.withValues(alpha: 0.06),
              rotation: 0.5,
            ),
          ),
          Positioned(
            bottom: -40,
            left: -60,
            child: _BlobShape(
              width: 350,
              height: 250,
              color: Colors.white.withValues(alpha: 0.07),
              rotation: 2.5,
            ),
          ),
          Positioned(
            bottom: 80,
            right: -80,
            child: _BlobShape(
              width: 280,
              height: 220,
              color: Colors.white.withValues(alpha: 0.06),
              rotation: 1.2,
            ),
          ),

          // Squiggly lines
          const Positioned(top: 40, right: 50, child: _SquigglyLine()),
          const Positioned(left: 30, top: 380, child: _SquigglyLine()),
          const Positioned(right: 40, bottom: 230, child: _SquigglyLine()),
          const Positioned(left: 120, bottom: 40, child: _SquigglyLine()),

          // Small circles
          Positioned(top: 50, left: 30, child: _SmallCircle(size: 14)),
          Positioned(
            right: 50,
            top: MediaQuery.of(context).size.height * 0.52,
            child: _SmallCircle(size: 14),
          ),
          Positioned(left: 30, bottom: 200, child: _SmallCircle(size: 14)),

          // X marks
          Positioned(
            top: 220,
            left: MediaQuery.of(context).size.width * 0.45,
            child: const _XMark(),
          ),
          Positioned(
            bottom: 160,
            left: MediaQuery.of(context).size.width * 0.35,
            child: const _XMark(),
          ),

          // Logo
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 20,
                                left: 20,
                                child: Icon(
                                  Icons.water_drop,
                                  size: 45,
                                  color: Colors.white70,
                                ),
                              ),
                              Positioned(
                                top: 20,
                                right: 10,
                                child: Icon(
                                  Icons.water_drop,
                                  size: 45,
                                  color: Colors.white70,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Icon(
                                  Icons.water_drop,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'DonorNET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double rotation;

  const _BlobShape({
    required this.width,
    required this.height,
    required this.color,
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(width, height),
        painter: _BlobPainter(color: color),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final Color color;
  _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.cubicTo(
      size.width * 0.85,
      size.height * 0.1,
      size.width * 1.1,
      size.height * 0.4,
      size.width * 0.9,
      size.height * 0.7,
    );
    path.cubicTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width * 0.35,
      size.height * 1.05,
      size.width * 0.15,
      size.height * 0.8,
    );
    path.cubicTo(
      -size.width * 0.05,
      size.height * 0.55,
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.5,
      0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SquigglyLine extends StatelessWidget {
  const _SquigglyLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(40, 12), painter: _SquigglyPainter());
  }
}

class _SquigglyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    final segmentWidth = size.width / 3;
    for (int i = 0; i < 3; i++) {
      final startX = i * segmentWidth;
      path.quadraticBezierTo(
        startX + segmentWidth * 0.5,
        i.isEven ? 0 : size.height,
        startX + segmentWidth,
        size.height * 0.5,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SmallCircle extends StatelessWidget {
  final double size;
  const _SmallCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
    );
  }
}

class _XMark extends StatelessWidget {
  const _XMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(14, 14), painter: _XPainter());
  }
}

class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);

    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
