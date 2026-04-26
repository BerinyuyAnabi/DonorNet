import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/blood_compatibility.dart';
import '../theme/app_theme.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  final _hospitalController = TextEditingController();

  String _selectedBloodType = '';
  String _locationName = 'Detecting...';
  double _latitude = 0;
  double _longitude = 0;
  bool _locationReady = false;
  bool _sending = false;
  bool _sent = false;
  int _compatibleCount = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _detectLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await _authService.getUserProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        _selectedBloodType = profile['bloodType'] ?? '';
      });
    }
  }

  Future<void> _detectLocation() async {
    final result = await _locationService.getCurrentPositionWithStatus();
    if (result.position != null && mounted) {
      final address = await _locationService.getAddressFromCoordinates(
        result.position!.latitude, result.position!.longitude,
      );
      setState(() {
        _latitude = result.position!.latitude;
        _longitude = result.position!.longitude;
        _locationName = address;
        _locationReady = true;
      });
    } else if (mounted) {
      setState(() {
        _locationName = result.error ?? 'Could not detect location';
        _locationReady = false;
      });
      if (result.error != null) {
        _showSnackBar(result.error!);
      }
    }
  }

  Future<void> _sendSOS() async {
    if (_selectedBloodType.isEmpty) {
      _showSnackBar('Please select your blood type');
      return;
    }
    if (_hospitalController.text.trim().isEmpty) {
      _showSnackBar('Please enter the hospital or location name');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppThemeColors.red, size: 28),
            const SizedBox(width: 10),
            const Text('Confirm Emergency',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Text(
          'This will broadcast an emergency alert to all compatible donors nearby.\n\nOnly use this for genuine emergencies.',
          style: TextStyle(color: AppThemeColors.greyText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Send SOS',
                style: TextStyle(
                    color: AppThemeColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _sending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = await _authService.getUserProfile(uid);
      final name = profile?['name'] ?? 'Someone';
      final compatibleTypes =
          BloodCompatibility.compatibleDonors(_selectedBloodType);

      await _firestoreService.sendEmergencySOS(
        userId: uid,
        name: name,
        bloodType: _selectedBloodType,
        hospital: _hospitalController.text.trim(),
        location: _locationName,
        latitude: _latitude,
        longitude: _longitude,
        compatibleTypes: compatibleTypes,
      );

      setState(() {
        _sent = true;
        _sending = false;
        _compatibleCount = compatibleTypes.length;
      });
    } catch (e) {
      setState(() => _sending = false);
      _showSnackBar('Failed to send SOS. Please try again.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppThemeColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppThemeColors.darkBackground : AppThemeColors.background;
    final cardBg = isDark ? AppThemeColors.darkCard : Colors.white;
    final textColor = isDark ? AppThemeColors.lightText : AppThemeColors.darkText;
    final subtextColor = isDark ? AppThemeColors.lightGreyText : AppThemeColors.greyText;

    if (_sent) return _buildSuccessScreen(isDark, bg, textColor, subtextColor);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: textColor),
                  ),
                  const Spacer(),
                  Text('Emergency SOS',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppThemeColors.red)),
                  const Spacer(),
                  const SizedBox(width: 20),
                ],
              ),

              const SizedBox(height: 28),

              Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppThemeColors.red,
                          AppThemeColors.red.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeColors.red.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emergency_rounded,
                        size: 48, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Request Emergency Blood',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'This will alert all compatible donors nearby',
                  style: TextStyle(fontSize: 14, color: subtextColor),
                ),
              ),

              const SizedBox(height: 28),

              /// Location
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppThemeColors.darkBorder : AppThemeColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppThemeColors.orangeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_on_rounded,
                          color: AppThemeColors.orange, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Location',
                              style: TextStyle(
                                  fontSize: 12, color: subtextColor)),
                          const SizedBox(height: 2),
                          Text(
                            _locationName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_locationReady)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppThemeColors.pink,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// Hospital input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppThemeColors.darkBorder : AppThemeColors.border,
                  ),
                ),
                child: TextField(
                  controller: _hospitalController,
                  style: TextStyle(color: textColor, fontSize: 15),
                  decoration: InputDecoration(
                    icon: Icon(Icons.local_hospital_rounded,
                        color: AppThemeColors.red, size: 22),
                    hintText: 'Hospital or location name',
                    hintStyle: TextStyle(color: subtextColor),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Blood type selector
              Text('Blood Type Needed',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor)),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: BloodCompatibility.allTypes.map((type) {
                  final selected = _selectedBloodType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBloodType = type),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppThemeColors.red
                            : (isDark ? AppThemeColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppThemeColors.red
                              : (isDark
                                  ? AppThemeColors.darkBorder
                                  : AppThemeColors.border),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppThemeColors.red.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : (isDark
                                    ? AppThemeColors.lightText
                                    : AppThemeColors.darkText),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_selectedBloodType.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppThemeColors.blueBg.withValues(alpha: isDark ? 0.15 : 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppThemeColors.blue, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Compatible donors: ${BloodCompatibility.compatibleDonors(_selectedBloodType).join(", ")}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppThemeColors.lightGreyText
                                : AppThemeColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              /// Send SOS button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeColors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppThemeColors.red.withValues(alpha: 0.4),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emergency_rounded, size: 22),
                            SizedBox(width: 10),
                            Text('SEND EMERGENCY SOS',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Only use for genuine medical emergencies',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(
      bool isDark, Color bg, Color textColor, Color subtextColor) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppThemeColors.greenBg,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 52, color: AppThemeColors.green),
                ),
                const SizedBox(height: 24),
                Text('SOS Sent!',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 12),
                Text(
                  'Your emergency request for $_selectedBloodType blood has been broadcast to compatible donors ($_compatibleCount blood types).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: subtextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll be notified when a donor responds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppThemeColors.pink),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeColors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Back to Home',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
