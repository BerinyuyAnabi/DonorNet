import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color border = Color(0xFFEDE8EB);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _notifications = true;
  bool _locationServices = true;
  bool _darkMode = false;
  bool _biometric = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: _C.darkText,
                  ),
                ),
              ),

              // Account section
              _sectionHeader('Account'),
              _settingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {},
              ),
              _settingsTile(
                icon: Icons.bloodtype_outlined,
                title: 'Blood Type',
                subtitle: 'A Positive (A+)',
                onTap: () {},
              ),

              const SizedBox(height: 8),

              // Preferences section
              _sectionHeader('Preferences'),
              _toggleTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Blood requests, reminders',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              _toggleTile(
                icon: Icons.location_on_outlined,
                title: 'Location Services',
                subtitle: 'Find nearby blood banks',
                value: _locationServices,
                onChanged: (v) => setState(() => _locationServices = v),
              ),
              _toggleTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch to dark theme',
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              _toggleTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Login',
                subtitle: 'Use Face ID or fingerprint',
                value: _biometric,
                onChanged: (v) => setState(() => _biometric = v),
              ),

              const SizedBox(height: 8),

              // Support section
              _sectionHeader('Support'),
              _settingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Help Centre',
                subtitle: 'FAQs and support articles',
                onTap: () {},
              ),
              _settingsTile(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () => _showPolicySheet(context, 'Privacy Policy', _privacyText),
              ),
              _settingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Our terms and conditions',
                onTap: () => _showPolicySheet(context, 'Terms of Service', _termsText),
              ),
              _settingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About DonorNet',
                subtitle: 'Version 1.0.0',
                onTap: () => _showPolicySheet(context, 'About DonorNet', _aboutText),
              ),

              const SizedBox(height: 16),

              // Log out
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      // Clear the entire navigation stack and go to auth landing.
                      // pushNamedAndRemoveUntil removes ALL routes (including
                      // HomeScreen) and places /login as the only route.
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 20,
                        color: _C.pink),
                    label: const Text('Log Out',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600, color: _C.pink)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _C.pink.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.greyText.withValues(alpha: 0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _C.pinkBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: _C.pink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600, color: _C.darkText)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: _C.greyText)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: _C.greyText.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _C.pinkBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _C.pink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w600, color: _C.darkText)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: _C.greyText)),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: _C.pink.withValues(alpha: 0.5),
              activeThumbColor: _C.pink,
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicySheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _C.greyText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: _C.darkText)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Text(content,
                  style: const TextStyle(fontSize: 14, color: _C.greyText,
                      height: 1.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _privacyText = '''
DonorNet Privacy Policy

Last updated: April 2026

1. Information We Collect
We collect your name, email address, phone number, blood type, date of birth, and location when you create an account. If you upload a profile photo, it is stored securely.

2. How We Use Your Information
Your information is used to:
• Match blood donors with those in need
• Display your profile to other users seeking donors
• Send notifications about blood requests and donation events
• Improve the app experience

3. Data Storage
Your data is stored securely using Firebase (Google Cloud). We use industry-standard encryption for data in transit and at rest.

4. Data Sharing
We do NOT sell, trade, or share your personal data with third parties. Your information is only visible to other DonorNet users as needed for blood donation matching.

5. Your Rights
You can update or delete your profile data at any time through the app. To delete your account entirely, contact us through the Help Centre.

6. Contact
For privacy concerns, reach us at privacy@donornet.app
''';

  static const _termsText = '''
DonorNet Terms of Service

Last updated: April 2026

1. Acceptance of Terms
By using DonorNet, you agree to these terms. If you do not agree, please do not use the app.

2. Eligibility
You must be at least 17 years old to create an account. By registering, you confirm that you meet this requirement.

MEDICAL DISCLAIMER

DonorNet is a CONNECTION PLATFORM ONLY. It does NOT provide medical advice, diagnosis, or treatment.

• All blood donations MUST be conducted at licensed blood banks or medical facilities.
• DonorNet does NOT verify blood types or medical eligibility of donors.
• Users are solely responsible for ensuring they meet ALL medical requirements before donating blood.
• Always consult a qualified healthcare professional before donating or receiving blood.
• DonorNet is NOT responsible for any adverse health outcomes resulting from blood donation or transfusion.

3. User Responsibilities
• Provide accurate information about your blood type and health status
• Do not create false or misleading blood requests
• Report any suspicious activity or fake profiles
• Follow all local laws and medical regulations regarding blood donation

4. Limitation of Liability
DonorNet provides a platform for connecting donors and recipients. We are not liable for:
• The accuracy of user-provided blood type information
• Medical outcomes from donations arranged through the app
• Delays in finding donors or fulfilling requests

5. Account Termination
We reserve the right to suspend or terminate accounts that violate these terms or post fraudulent requests.

6. Contact
For questions about these terms, reach us at support@donornet.app
''';

  static const _aboutText = '''
DonorNet — Blood Donation Network

Version 1.0.0

DonorNet connects blood donors with people who need blood, quickly and safely. Our mission is to ensure no one has to wait for the blood they need.

How it works:
• Donors register with their blood type and location
• People in need post blood requests
• Donors get notified when their blood type is needed nearby
• Blood banks and donation events are listed for easy access

Every donation can save up to 3 lives.

Built with love in Accra, Ghana.
''';
}
