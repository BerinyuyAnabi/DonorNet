import 'package:flutter/material.dart';

// Colors
class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkLight = Color(0xFFFF6B8A);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color background = Color(0xFFF5F7FA);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color inputBorder = Color(0xFFE8ECF0);
}

// Blood type data model
class BloodType {
  final String label;
  final String shortLabel;
  final String badgeText;
  final bool isFilled;

  const BloodType({
    required this.label,
    required this.shortLabel,
    required this.badgeText,
    this.isFilled = false,
  });
}

// Bottom action mode
enum SelectBloodMode { findDonor, search }

class SelectBloodGroupScreen extends StatefulWidget {
  final SelectBloodMode mode;
  final void Function(BloodType selectedType)? onEmergency;
  final void Function(BloodType selectedType)? onSchedule;
  final void Function(BloodType selectedType)? onFindDonor;
  final void Function(String query)? onSearch;

  const SelectBloodGroupScreen({
    super.key,
    this.mode = SelectBloodMode.findDonor,
    this.onEmergency,
    this.onSchedule,
    this.onFindDonor,
    this.onSearch,
  });

  @override
  State<SelectBloodGroupScreen> createState() =>
      _SelectBloodGroupScreenState();
}

class _SelectBloodGroupScreenState extends State<SelectBloodGroupScreen> {
  int _selectedIndex = -1;
  final _unitController = TextEditingController(text: '~525 mL');
  final _searchController = TextEditingController();

  static const _bloodTypes = [
    BloodType(label: 'A Positive', shortLabel: 'A+', badgeText: 'A\u207A', isFilled: true),
    BloodType(label: 'A Negative', shortLabel: 'A-', badgeText: 'A\u207B'),
    BloodType(label: 'B Positive', shortLabel: 'B+', badgeText: 'B\u207A', isFilled: true),
    BloodType(label: 'B Negative', shortLabel: 'B-', badgeText: 'B\u207B'),
    BloodType(label: 'O Positive', shortLabel: 'O+', badgeText: 'O\u207A', isFilled: true),
    BloodType(label: 'O Negative', shortLabel: 'O-', badgeText: 'O\u207B'),
    BloodType(label: 'AB Positive', shortLabel: 'AB+', badgeText: 'AB\u207A'),
    BloodType(label: 'AB Negative', shortLabel: 'AB-', badgeText: 'AB\u207B'),
  ];

  @override
  void dispose() {
    _unitController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildBloodGrid(),
                    const SizedBox(height: 20),
                    _buildUnitInput(),
                    const SizedBox(height: 20),
                    _buildEmergencyButton(),
                    const SizedBox(height: 14),
                    const Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 14,
                        color: _C.greyText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildScheduleRow(),
                    const SizedBox(height: 20),
                    if (widget.mode == SelectBloodMode.findDonor)
                      _buildFindDonorButton()
                    else
                      _buildSearchBar(),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back, color: _C.darkText, size: 24),
          ),
          const Expanded(
            child: Text(
              'Select Blood Group',
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
    );
  }

  Widget _buildBloodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: _bloodTypes.length,
      itemBuilder: (context, index) {
        final type = _bloodTypes[index];
        final isSelected = _selectedIndex == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: _BloodTypeCard(
            bloodType: type,
            isSelected: isSelected,
          ),
        );
      },
    );
  }

  Widget _buildUnitInput() {
    return Container(
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 68,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: _C.inputBorder, width: 1),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.bloodtype_outlined,
                color: _C.pinkLight.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unit Of Blood',
                    style: TextStyle(
                      fontSize: 12,
                      color: _C.greyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _unitController,
                    style: const TextStyle(fontSize: 15, color: _C.darkText),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(top: 2, bottom: 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedIndex >= 0) {
            widget.onEmergency?.call(_bloodTypes[_selectedIndex]);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Emergency'),
      ),
    );
  }

  Widget _buildScheduleRow() {
    return GestureDetector(
      onTap: () {
        if (_selectedIndex >= 0) {
          widget.onSchedule?.call(_bloodTypes[_selectedIndex]);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Schedule',
            style: TextStyle(
              fontSize: 16,
              color: _C.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: _C.blue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindDonorButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: () {
          if (_selectedIndex >= 0) {
            widget.onFindDonor?.call(_bloodTypes[_selectedIndex]);
          }
          Navigator.pushNamed(context, '/nearby-donors');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _C.blue,
          side: const BorderSide(color: _C.blue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Find A Donor'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.inputBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              widget.onSearch?.call(_searchController.text.trim());
            },
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _C.pink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: _C.darkText),
              decoration: InputDecoration(
                hintText: 'Type.. Ex A Positive (A+)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: _C.greyText.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Blood Type Card
class _BloodTypeCard extends StatelessWidget {
  final BloodType bloodType;
  final bool isSelected;

  const _BloodTypeCard({
    required this.bloodType,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? _C.pinkBg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: _C.pinkLight.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(40, 48),
                    painter: _BloodDropIconPainter(
                      isFilled: bloodType.isFilled,
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: bloodType.isFilled
                          ? _C.darkText.withValues(alpha: 0.85)
                          : _C.darkText.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        bloodType.badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bloodType.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: _C.darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '(${bloodType.shortLabel})',
            style: const TextStyle(
              fontSize: 10,
              color: _C.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

// Blood Drop Icon Painter
class _BloodDropIconPainter extends CustomPainter {
  final bool isFilled;

  _BloodDropIconPainter({this.isFilled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8;

    paint.color = _C.pinkLight;
    final outerPath = _dropPath(size, Offset(size.width * 0.5, size.height * 0.5), 0.9);
    canvas.drawPath(outerPath, paint);

    if (isFilled) {
      final innerPaint = Paint()
        ..color = _C.pink
        ..style = PaintingStyle.fill;
      final innerPath = _dropPath(size, Offset(size.width * 0.5, size.height * 0.55), 0.55);
      canvas.drawPath(innerPath, innerPaint);
    }
  }

  Path _dropPath(Size size, Offset center, double scale) {
    final w = size.width * scale;
    final h = size.height * scale;
    final cx = center.dx;
    final cy = center.dy;

    final path = Path();
    final top = Offset(cx, cy - h * 0.5);
    final bottom = Offset(cx, cy + h * 0.35);

    path.moveTo(top.dx, top.dy);
    path.quadraticBezierTo(cx + w * 0.55, cy + h * 0.05, bottom.dx, bottom.dy);
    path.quadraticBezierTo(cx - w * 0.55, cy + h * 0.05, top.dx, top.dy);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BloodDropIconPainter old) =>
      old.isFilled != isFilled;
}
