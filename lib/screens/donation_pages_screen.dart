import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

// Colors
class C {
  static const pink = Color(0xFFE85475);
  static const pinkLight = Color(0xFFFCE4EC);
  static const pinkBg = Color(0xFFFFF0F3);
  static const coral = Color(0xFFFF7E9A);
  static const blue = Color(0xFF4A5AC7);
  static const blueMid = Color(0xFF6C7AE0);
  static const teal = Color(0xFF2EC4B6);
  static const dark = Color(0xFF1E1E2E);
  static const muted = Color(0xFF8E8EA0);
  static const border = Color(0xFFEDE8EB);
  static const scaffoldBg = Color(0xFFFAF7F9);
  static const white = Colors.white;
  static const green = Color(0xFF4CAF50);
}

// MAIN DONATION FLOW — step-by-step wizard
class DonationPagesScreen extends StatefulWidget {
  const DonationPagesScreen({super.key});
  @override
  State<DonationPagesScreen> createState() => _DonationPagesScreenState();
}

class _DonationPagesScreenState extends State<DonationPagesScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 5;

  // Shared state across steps
  int _selectedType = -1;
  int _selectedGroup = -1;
  bool _contactVisible = true;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _stepLabels = [
    'Donation Type',
    'Type Details',
    'Guidelines',
    'Your Details',
    'Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await _authService.getUserProfile(user.uid);
    if (data != null && mounted) {
      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _emailCtrl.text = data['email'] ?? user.email ?? '';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _next() async {
    if (_currentStep == 3) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _selectedType >= 0) {
        final donationType = _types[_selectedType]['label'] as String;

        final updates = <String, dynamic>{};
        if (_nameCtrl.text.trim().isNotEmpty) {
          updates['name'] = _nameCtrl.text.trim();
        }
        if (_emailCtrl.text.trim().isNotEmpty) {
          updates['email'] = _emailCtrl.text.trim();
        }
        if (_selectedGroup >= 0) {
          updates['bloodType'] = _groups[_selectedGroup]['label']!
              .replaceAll('\n', ' ');
        }
        if (updates.isNotEmpty) {
          await _authService.updateUserProfile(user.uid, updates);
        }

        await _firestoreService.recordDonation(
          userId: user.uid,
          type: donationType,
          location: 'Scheduled — pending centre assignment',
        );
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: C.dark.withValues(alpha: 0.7)),
            onPressed: _back,
          ),
        ),
        title: Text(
          _stepLabels[_currentStep],
          style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: C.pink,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          const SizedBox(height: 8),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildTypePage(),
                _buildTypeDetailsPage(),
                _buildGuidelinesPage(),
                _buildDetailsPage(),
                _buildSuccessPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Progress Bar
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isCompleted = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? C.pink
                    : isCurrent
                        ? C.pink.withValues(alpha: 0.5)
                        : C.border,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 1: DONATION TYPE
  // ═══════════════════════════════════════════════════════════════════
  final _types = [
    {
      'icon': Icons.water_drop_outlined,
      'label': 'Whole Blood',
      'desc': 'Most common type\nused in emergencies',
      'duration': '~10 minutes',
      'frequency': 'Every 56 days',
      'detail': 'Whole blood is the most flexible donation type. It can be separated into red cells, platelets, and plasma to help up to 3 patients. It is the most needed donation and is used in surgeries, trauma care, and treating blood disorders.',
    },
    {
      'icon': Icons.water_drop,
      'label': 'Power Red',
      'desc': 'Double the red cells\nin a single donation',
      'duration': '~30 minutes',
      'frequency': 'Every 112 days',
      'detail': 'During a Power Red donation, a special machine collects two units of red blood cells and returns platelets and plasma back to you. Red cells are the most commonly transfused blood component and are used to treat trauma, surgery, and anemia.',
    },
    {
      'icon': Icons.grain_rounded,
      'label': 'Platelets',
      'desc': 'Helps cancer patients\nand organ transplants',
      'duration': '~2-3 hours',
      'frequency': 'Every 7 days',
      'detail': 'Platelets are tiny cells in your blood that help stop bleeding by forming clots. They are essential for cancer patients undergoing chemotherapy, organ transplant recipients, and those with blood disorders that prevent proper clotting.',
    },
    {
      'icon': Icons.biotech_rounded,
      'label': 'AB Plasma',
      'desc': 'Universal plasma\nfor burn & trauma care',
      'duration': '~45 minutes',
      'frequency': 'Every 28 days',
      'detail': 'AB Plasma is the universal donor plasma — it can be given to patients of any blood type. Plasma carries proteins and antibodies that help with clotting and immunity. It is critical for burn victims, patients in shock, and those with liver conditions.',
    },
  ];

  Widget _buildTypePage() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: Column(
        children: [
          // Hero banner
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFFFBCDD5), Color(0xFFF8A4B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(right: -25, top: -25,
                  child: _circle(100, C.white.withValues(alpha: 0.12))),
                Positioned(left: -15, bottom: -15,
                  child: _circle(60, C.white.withValues(alpha: 0.08))),
                Positioned(right: 30, bottom: 20,
                  child: _circle(40, C.white.withValues(alpha: 0.1))),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: C.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.volunteer_activism_rounded,
                            size: 50, color: C.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 10),
                      Text('Choose your donation type',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: C.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Type grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.05,
            ),
            itemCount: 4,
            itemBuilder: (_, i) {
              final t = _types[i];
              final sel = _selectedType == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? C.pinkLight : C.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel ? C.pink.withValues(alpha: 0.3) : C.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel
                              ? C.pink.withValues(alpha: 0.12)
                              : const Color(0xFFF5F0F2),
                        ),
                        child: Icon(t['icon'] as IconData, size: 26,
                            color: sel ? C.pink : C.muted),
                      ),
                      const SizedBox(height: 12),
                      Text(t['label'] as String,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: sel ? C.pink : C.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t['desc'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9.5,
                            color: C.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Next button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _selectedType >= 0 ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: C.pink,
                foregroundColor: C.white,
                disabledBackgroundColor: C.pink.withValues(alpha: 0.3),
                disabledForegroundColor: C.white.withValues(alpha: 0.6),
                elevation: _selectedType >= 0 ? 4 : 0,
                shadowColor: C.pink.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              ),
              child: const Text('Next',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 2: TYPE DETAILS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTypeDetailsPage() {
    if (_selectedType < 0) return const SizedBox();
    final t = _types[_selectedType];
    final label = t['label'] as String;
    final detail = t['detail'] as String;
    final duration = t['duration'] as String;
    final frequency = t['frequency'] as String;
    final icon = t['icon'] as IconData;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner with selected type
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBCDD5), Color(0xFFF8A4B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(right: -25, top: -30,
                        child: _circle(100, C.white.withValues(alpha: 0.1))),
                      Positioned(left: -20, bottom: -20,
                        child: _circle(70, C.white.withValues(alpha: 0.08))),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: C.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 52,
                                color: C.white.withValues(alpha: 0.9)),
                          ),
                          const SizedBox(height: 14),
                          Text(label,
                            style: TextStyle(fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: C.white.withValues(alpha: 0.95)),
                          ),
                          const SizedBox(height: 4),
                          Text('Donation',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: C.white.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick stats row
                Row(
                  children: [
                    Expanded(
                      child: _statChip(
                        Icons.timer_outlined, 'Duration', duration),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statChip(
                        Icons.repeat_rounded, 'Frequency', frequency),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // About section
                const Text('About this donation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: C.dark),
                ),
                const SizedBox(height: 12),
                Text(detail,
                  style: const TextStyle(fontSize: 14, color: C.muted,
                      height: 1.7),
                ),

                const SizedBox(height: 24),

                // What to expect
                const Text('What to expect',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: C.dark),
                ),
                const SizedBox(height: 16),

                _expectItem(
                  number: '1',
                  title: 'Registration',
                  desc: 'You will be asked to fill out a brief form and show your ID.',
                  color: C.pink,
                ),
                _expectItem(
                  number: '2',
                  title: 'Health Screening',
                  desc: 'A quick check of your temperature, pulse, blood pressure, and hemoglobin.',
                  color: C.blue,
                ),
                _expectItem(
                  number: '3',
                  title: 'The Donation',
                  desc: 'A trained staff member will collect your $label donation — takes about $duration.',
                  color: C.teal,
                ),
                _expectItem(
                  number: '4',
                  title: 'Refreshments',
                  desc: 'Relax, enjoy a snack and a drink. You should feel fine within minutes.',
                  color: const Color(0xFF7E57C2),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom buttons
        _buildBottomButtons(
          onBack: _back,
          onNext: _next,
          nextLabel: 'Continue',
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: C.pink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: C.pink),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(fontSize: 11, color: C.muted)),
                const SizedBox(height: 2),
                Text(value,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: C.dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expectItem({
    required String number,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(number,
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w800, color: color)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: C.dark)),
                const SizedBox(height: 4),
                Text(desc,
                  style: const TextStyle(fontSize: 13, color: C.muted,
                      height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // renumbered — STEP 3: GUIDELINES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGuidelinesPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chapter 1',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: C.pink.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 6),
                const Text('General Guidelines For Blood Donation',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                      color: C.dark, height: 1.3),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: C.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _bullet('Be in good general health and feeling well.',
                          C.green),
                      _bullet(
                        'Be at least 17 years old in most states (16 years old with parental consent in some states).',
                        C.dark.withValues(alpha: 0.5),
                      ),
                      _bullet(
                        'Weigh at least 110 pounds. Additional weight requirements apply for donors 18 years old and younger and all high school donors.',
                        C.dark.withValues(alpha: 0.5),
                      ),
                      _bullet(
                        'Have not donated blood in the last 56 days.',
                        C.dark.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text('How To Get Ready',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                      color: C.dark),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Donors must have proof of age to ensure they meet the minimum age requirements and present a primary form of ID or two secondary forms of ID.',
                  style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.65),
                ),

                const SizedBox(height: 22),

                // Step cards
                _buildStepCard(
                  step: 'Step 1',
                  title: 'Drink Extra Liquids',
                  desc: 'Drink an extra 16 oz. of water before your appointment',
                  icon: Icons.local_drink_rounded,
                  colors: [C.blue, C.blueMid],
                ),

                const SizedBox(height: 14),

                _buildStepCard(
                  step: 'Step 2',
                  title: 'Eat Iron-Rich Foods',
                  desc: 'Eat a healthy meal with iron-rich foods like spinach or red meat',
                  icon: Icons.restaurant_rounded,
                  colors: [C.teal, const Color(0xFF26A69A)],
                ),

                const SizedBox(height: 14),

                _buildStepCard(
                  step: 'Step 3',
                  title: 'Get a Good Night Sleep',
                  desc: 'Get at least 7-8 hours of sleep the night before',
                  icon: Icons.nightlight_round,
                  colors: [const Color(0xFF7E57C2), const Color(0xFF9575CD)],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Whatever your reason, the need for blood is constant and you will feel good knowing your donation can help save up to 3 lives.',
                  style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.65),
                ),
                const SizedBox(height: 20),

                // Medical disclaimer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.pinkBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.pink.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: C.pink.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'This app is a connection tool. All donations must be conducted at licensed medical facilities.',
                          style: TextStyle(fontSize: 12, color: C.dark, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom buttons
        _buildBottomButtons(
          onBack: _back,
          onNext: _next,
          nextLabel: 'I Understand, Continue',
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String desc,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: colors[0].withValues(alpha: 0.3),
              blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step,
                  style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: C.white.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 4),
                Text(title,
                  style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w700, color: C.white),
                ),
                const SizedBox(height: 10),
                Text(desc,
                  style: TextStyle(fontSize: 13,
                      color: C.white.withValues(alpha: 0.8), height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: C.white, size: 30),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 3: YOUR DETAILS
  // ═══════════════════════════════════════════════════════════════════
  final _groups = [
    {'short': 'A+', 'label': 'A Positive\n(A+)'},
    {'short': 'B+', 'label': 'B Positive\n(B+)'},
    {'short': 'O+', 'label': 'O Positive\n(O+)'},
    {'short': 'AB+', 'label': 'AB Positive\n(AB+)'},
  ];

  Widget _buildDetailsPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBCDD5), Color(0xFFF8A4B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(right: -20, bottom: -20,
                        child: _circle(100, C.white.withValues(alpha: 0.1))),
                      Positioned(left: 30, top: 25,
                        child: _circle(35, C.white.withValues(alpha: 0.12))),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: C.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.favorite_rounded, size: 44,
                                  color: C.white.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(height: 8),
                            Text('Almost there!',
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: C.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Name field
                _inputField(
                  icon: Icons.person_outline_rounded,
                  label: 'Full Name',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 14),

                // Email field
                _inputField(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  controller: _emailCtrl,
                ),

                const SizedBox(height: 28),

                const Text('Select Blood Group',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: C.dark),
                ),
                const SizedBox(height: 16),

                // Blood group selector
                Row(
                  children: List.generate(4, (i) {
                    final sel = _selectedGroup == i;
                    final g = _groups[i];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGroup = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? C.pink : C.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel ? C.pink : C.border, width: 1),
                            boxShadow: sel ? [
                              BoxShadow(color: C.pink.withValues(alpha: 0.25),
                                  blurRadius: 12, offset: const Offset(0, 4)),
                            ] : [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel
                                      ? C.white.withValues(alpha: 0.2)
                                      : C.pink.withValues(alpha: 0.08),
                                ),
                                child: Center(
                                  child: Text(g['short']!,
                                    style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w800,
                                      color: sel ? C.white : C.pink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(g['label']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5, fontWeight: FontWeight.w500,
                                  color: sel ? C.white.withValues(alpha: 0.85) : C.muted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 22),

                // Contact visibility toggle
                GestureDetector(
                  onTap: () => setState(() => _contactVisible = !_contactVisible),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _contactVisible
                              ? C.green : const Color(0xFFD5D5D5),
                        ),
                        child: _contactVisible
                            ? const Icon(Icons.check, size: 14, color: C.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Make my contact number visible to others who need blood',
                          style: TextStyle(fontSize: 13, color: C.muted,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Bottom buttons
        _buildBottomButtons(
          onBack: _back,
          onNext: _canSubmit() ? _next : null,
          nextLabel: 'Submit',
          nextColor: C.blue,
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _nameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.trim().isNotEmpty &&
        _selectedGroup >= 0;
  }

  Widget _inputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.pinkLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: C.pink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: C.pink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: C.dark,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: const TextStyle(fontSize: 12, color: C.muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 4: SUCCESS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSuccessPage() {
    final donationType = _selectedType >= 0
        ? _types[_selectedType]['label'] as String
        : '';
    final bloodGroup = _selectedGroup >= 0
        ? _groups[_selectedGroup]['short']!
        : '';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: C.green.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 60, color: C.white),
          ),

          const SizedBox(height: 28),

          const Text(
            'Thank You!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: C.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your donation registration has been submitted successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: C.muted,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: C.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Donation Summary',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: C.dark),
                ),
                const SizedBox(height: 18),
                _summaryRow(Icons.water_drop_outlined, 'Type', donationType),
                _summaryRow(Icons.bloodtype_outlined, 'Blood Group', bloodGroup),
                if (_nameCtrl.text.trim().isNotEmpty)
                  _summaryRow(Icons.person_outline_rounded, 'Name', _nameCtrl.text.trim()),
                if (_emailCtrl.text.trim().isNotEmpty)
                  _summaryRow(Icons.email_outlined, 'Email', _emailCtrl.text.trim()),
                _summaryRow(
                  Icons.visibility_outlined,
                  'Contact Visible',
                  _contactVisible ? 'Yes' : 'No',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: C.pinkBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.pink.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: C.pink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: C.pink, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'You will receive an email with the details of your nearest donation centre and appointment information.',
                    style: TextStyle(fontSize: 12.5, color: C.dark,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Go home button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: C.pink,
                foregroundColor: C.white,
                elevation: 4,
                shadowColor: C.pink.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              ),
              child: const Text('Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 14),

          TextButton(
            onPressed: () {},
            child: const Text(
              'Read more about who can give blood',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: C.pink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: C.pink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: C.pink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(fontSize: 11, color: C.muted)),
                const SizedBox(height: 2),
                Text(value,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: C.dark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBottomButtons({
    required VoidCallback onBack,
    required VoidCallback? onNext,
    required String nextLabel,
    Color nextColor = C.pink,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: C.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: C.dark.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text('Back',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: C.dark.withValues(alpha: 0.6))),
              ),
            ),
            const SizedBox(width: 12),
            // Next button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nextColor,
                    foregroundColor: C.white,
                    disabledBackgroundColor: nextColor.withValues(alpha: 0.3),
                    disabledForegroundColor: C.white.withValues(alpha: 0.6),
                    elevation: onNext != null ? 4 : 0,
                    shadowColor: nextColor.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text(nextLabel,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SHARED HELPERS
Widget _circle(double size, Color color) {
  return Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

Widget _bullet(String text, Color dotColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
            style: const TextStyle(fontSize: 13, color: C.dark, height: 1.55),
          ),
        ),
      ],
    ),
  );
}
