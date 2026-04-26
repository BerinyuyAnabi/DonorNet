import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color border = Color(0xFFEDE8EB);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color blueBg = Color(0xFFE3F2FD);
}

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String _name = '';
  String _email = '';
  String _phone = '';
  String _location = '';
  String _dob = '';
  String _bloodType = '';
  String _photoUrl = '';
  bool _bloodTypeVerified = false;
  bool _loading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = await _authService.getUserProfile(user.uid);
    if (data != null && mounted) {
      setState(() {
        _name = data['name'] ?? '';
        _email = data['email'] ?? user.email ?? '';
        _phone = data['phone'] ?? '';
        _location = data['location'] ?? '';
        _dob = data['dob'] ?? '';
        _bloodType = data['bloodType'] ?? '';
        _photoUrl = data['photoUrl'] ?? '';
        _bloodTypeVerified = data['bloodTypeVerified'] ?? false;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      // Upload to Firebase Storage under users/{uid}/profile.jpg
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      // Save URL to Firestore
      await _authService.updateUserProfile(user.uid, {'photoUrl': url});
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not upload photo: $e'),
            backgroundColor: _C.pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D6D)));
    }
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
              const SizedBox(height: 16),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _C.darkText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Avatar + name card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B8A), Color(0xFFE8446A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _C.pink.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with photo + tap to change
                    GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 3,
                              ),
                              image: _photoUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(_photoUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _uploadingPhoto
                                ? const Center(
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                    ),
                                  )
                                : _photoUrl.isEmpty
                                    ? const Center(
                                        child: Icon(Icons.person_rounded,
                                            size: 38, color: Colors.white),
                                      )
                                    : null,
                          ),
                          // Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 14, color: _C.pink),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Blood type pill with verified badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _bloodType.isNotEmpty ? _bloodType : 'Not set',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_bloodTypeVerified) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded,
                                          size: 14, color: Colors.white),
                                    ],
                                  ],
                                ),
                              ),
                              if (!_bloodTypeVerified && _bloodType.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text('Unverified',
                                  style: TextStyle(fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.5))),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEditSheet(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Personal info section
              _sectionHeader('Personal Information'),
              _infoTile(Icons.person_outline_rounded, 'Full Name', _name),
              _infoTile(Icons.email_outlined, 'Email', _email),
              _infoTile(Icons.phone_outlined, 'Phone', _phone),
              _infoTile(Icons.location_on_outlined, 'Location', _location),
              _infoTile(Icons.cake_outlined, 'Date of Birth', _dob),
              _infoTile(Icons.bloodtype_outlined, 'Blood Type', _bloodType),

              const SizedBox(height: 16),

              _sectionHeader('Recent Donations'),
              _buildDonationHistory(),

              const SizedBox(height: 16),

              // Next eligible — calculated from last donation (56 days)
              _buildNextEligible(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      );
  }

  // Edit Profile Bottom Sheet
  void _showEditSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final phoneCtrl = TextEditingController(text: _phone);
    final locationCtrl = TextEditingController(text: _location);

    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final bloodLabels = {
      'A+': 'A Positive (A+)',
      'A-': 'A Negative (A-)',
      'B+': 'B Positive (B+)',
      'B-': 'B Negative (B-)',
      'AB+': 'AB Positive (AB+)',
      'AB-': 'AB Negative (AB-)',
      'O+': 'O Positive (O+)',
      'O-': 'O Negative (O-)',
    };

    // Find the current short code from the label
    String selectedBlood = bloodLabels.entries
        .firstWhere((e) => e.value == _bloodType,
            orElse: () => const MapEntry('A+', 'A Positive (A+)'))
        .key;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _C.greyText.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _C.darkText,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _C.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: _C.greyText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fields
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _editField(
                            icon: Icons.person_outline_rounded,
                            label: 'Full Name',
                            controller: nameCtrl,
                          ),
                          const SizedBox(height: 14),
                          _editField(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _editField(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _editField(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            controller: locationCtrl,
                          ),
                          const SizedBox(height: 22),

                          // Blood type selector
                          const Text('Blood Type',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _C.darkText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: bloodTypes.map((type) {
                              final sel = selectedBlood == type;
                              return GestureDetector(
                                onTap: () =>
                                    setSheetState(() => selectedBlood = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: sel ? _C.pink : _C.pinkBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : _C.pink,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        final newEmail = emailCtrl.text.trim();
                        final newPhone = phoneCtrl.text.trim();
                        final newLocation = locationCtrl.text.trim();
                        final newBlood = bloodLabels[selectedBlood]!;

                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await _authService.updateUserProfile(user.uid, {
                            'name': newName,
                            'email': newEmail,
                            'phone': newPhone,
                            'location': newLocation,
                            'bloodType': newBlood,
                          });
                        }

                        setState(() {
                          _name = newName;
                          _email = newEmail;
                          _phone = newPhone;
                          _location = newLocation;
                          _bloodType = newBlood;
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Profile updated!'),
                              backgroundColor: _C.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.pink,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _C.pink.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _editField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _C.pink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _C.pink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                  fontSize: 14,
                  color: _C.darkText,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: label,
                labelStyle: const TextStyle(fontSize: 12, color: _C.greyText),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Live Firestore Widgets

  /// Calculates "next eligible donation" as 56 days from the most recent donation.
  Widget _buildNextEligible() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getDonationHistory(user.uid),
      builder: (context, snapshot) {
        String message = 'You are eligible to donate now!';

        final docs = snapshot.data?.docs ?? [];
        if (docs.isNotEmpty) {
          final lastDonation = docs.first; // newest first
          final timestamp = (lastDonation.data() as Map<String, dynamic>)['date'] as Timestamp?;
          if (timestamp != null) {
            final lastDate = timestamp.toDate();
            final nextDate = lastDate.add(const Duration(days: 56));
            if (nextDate.isAfter(DateTime.now())) {
              message = 'You can donate again on ${_formatDate(nextDate)}';
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _C.blueBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.blue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: _C.blue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Eligible Donation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          color: _C.greyText.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDonationHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getDonationHistory(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: _C.pink)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('Could not load donation history',
                style: TextStyle(fontSize: 13,
                    color: _C.greyText.withValues(alpha: 0.7))),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'No donations yet. Start your journey!',
              style: TextStyle(
                  fontSize: 13, color: _C.greyText.withValues(alpha: 0.7)),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['date'] as Timestamp?;
            final dateStr = timestamp != null
                ? _formatDate(timestamp.toDate())
                : 'Pending';

            return _donationTile(
              date: dateStr,
              type: data['type'] ?? 'Blood',
              location: data['location'] ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.greyText.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _C.pinkBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: _C.pink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontSize: 11, color: _C.greyText)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.darkText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _donationTile({
    required String date,
    required String type,
    required String location,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.greenBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 22, color: _C.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _C.darkText)),
                  const SizedBox(height: 2),
                  Text(location,
                      style:
                          const TextStyle(fontSize: 12, color: _C.greyText)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(date,
                    style: TextStyle(
                        fontSize: 11,
                        color: _C.greyText.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _C.greenBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _C.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
