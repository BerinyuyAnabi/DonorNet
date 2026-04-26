import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

import 'my_profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'blood_request_screen.dart';
import 'blood_bank_screen.dart';
import 'blood_drives_screen.dart';
import 'donation_pages_screen.dart';
import 'emergency_sos_screen.dart';
import 'select_blood_group_screen.dart';
import 'donor_loader.dart';
import 'donor_data.dart';
import 'profile_screen.dart';

// App Colors
class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkLight = Color(0xFFFF6B8A);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color mintBg = Color(0xFFE0F7F0);
  static const Color mint = Color(0xFF7DD6B8);
  static const Color yellowBg = Color(0xFFFFF8E7);
  static const Color yellow = Color(0xFFFFD580);
  static const Color background = Color(0xFFF5F7FA);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentNavIndex == 0 &&
            (_nestedNavKey.currentState?.canPop() ?? false)) {
          _nestedNavKey.currentState!.pop();
        } else if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: _C.background,
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/select-blood':
        page = const SelectBloodGroupScreen();
        break;
      case '/nearby-donors':
        page = const NearbyDonorLoader();
        break;
      case '/all-donators':
        page = const AllDonatorsLoader();
        break;
      case '/profile':
        final args = settings.arguments;
        final donor = (args is DonorData) ? args : null;
        page = ProfileScreen(donor: donor);
        break;
      case '/donation-pages':
        page = const DonationPagesScreen();
        break;
      case '/blood-request':
        page = const BloodRequestScreen();
        break;
      case '/blood-bank':
        page = const BloodBankScreen();
        break;
      case '/blood-drives':
        page = const BloodDrivesScreen();
        break;
      case '/emergency-sos':
        page = const EmergencySOSScreen();
        break;
      default:
        page = const _UnifiedHomeFeed();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  void _navigateToFeature(String route) {
    if (_currentNavIndex != 0) {
      setState(() => _currentNavIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nestedNavKey.currentState?.pushNamed(route);
      });
    } else {
      _nestedNavKey.currentState?.pushNamed(route);
    }
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 1:
        return const MyProfileScreen();
      case 3:
        return const SettingsScreen();
      case 4:
        return const NotificationsScreen();
      default:
        return Navigator(
          key: _nestedNavKey,
          onGenerateRoute: _onGenerateRoute,
        );
    }
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 12,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              isActive: _currentNavIndex == 0,
              onTap: () {
                if (_currentNavIndex == 0) {
                  _nestedNavKey.currentState
                      ?.popUntil((route) => route.isFirst);
                } else {
                  setState(() => _currentNavIndex = 0);
                }
              },
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              isActive: _currentNavIndex == 1,
              onTap: () => setState(() => _currentNavIndex = 1),
            ),
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              isActive: _currentNavIndex == 3,
              onTap: () => setState(() => _currentNavIndex = 3),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final hasUnread = (snapshot.data?.docs.length ?? 0) > 0;
                return _NavItem(
                  icon: Icons.notifications_none,
                  activeIcon: Icons.notifications,
                  isActive: _currentNavIndex == 4,
                  showBadge: hasUnread,
                  onTap: () => setState(() => _currentNavIndex = 4),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B8A), Color(0xFFE8446A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _C.pink.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showActionSheet(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, MediaQuery.of(ctx).padding.bottom + 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _C.greyText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('What would you like to do?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: _C.darkText)),
            const SizedBox(height: 20),
            _actionTile(
              icon: Icons.water_drop_rounded,
              title: 'Donate Blood',
              subtitle: 'Start the donation process',
              color: _C.pink,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToFeature('/donation-pages');
              },
            ),
            const SizedBox(height: 12),
            _actionTile(
              icon: Icons.search_rounded,
              title: 'Find a Donor',
              subtitle: 'Search for blood donors nearby',
              color: _C.blue,
              onTap: () {
                Navigator.pop(ctx);
                _navigateToFeature('/select-blood');
              },
            ),
            const SizedBox(height: 12),
            _actionTile(
              icon: Icons.add_circle_outline_rounded,
              title: 'Request Blood',
              subtitle: 'Post an urgent blood request',
              color: const Color(0xFFFF9B50),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToFeature('/blood-request');
              },
            ),
            const SizedBox(height: 12),
            _actionTile(
              icon: Icons.emergency_rounded,
              title: 'Emergency SOS',
              subtitle: 'Broadcast an urgent alert to nearby donors',
              color: const Color(0xFFE53935),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToFeature('/emergency-sos');
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, color: _C.darkText)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12,
                      color: _C.greyText.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// SHARED WIDGETS

Widget _buildTopBar(BuildContext context, String location) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: _C.pink, size: 22),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            location,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: _C.pink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
      ],
    ),
  );
}

Widget _buildStatCards() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('blood_requests')
                .where('urgency', isNotEqualTo: 'Fulfilled')
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasError ? 0 : (snapshot.data?.docs.length ?? 0);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B8A), Color(0xFFE8446A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _C.pink.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'New Blood\nRequested',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donations')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final donations = snapshot.hasError ? 0 : (snapshot.data?.docs.length ?? 0);
              final livesSaved = donations * 3;
              final display = livesSaved >= 1000
                  ? '${(livesSaved / 1000).toStringAsFixed(1)}K'
                  : '$livesSaved';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: _C.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      display,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: _C.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Lives Saved',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _C.greyText,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

// UNIFIED HOME FEED
// Shows: hero, stats, 4 feature cards, live request feed,
// and the user's own posted requests
class _UnifiedHomeFeed extends StatefulWidget {
  const _UnifiedHomeFeed();

  @override
  State<_UnifiedHomeFeed> createState() => _UnifiedHomeFeedState();
}

class _UnifiedHomeFeedState extends State<_UnifiedHomeFeed> {
  String _location = 'Detecting...';
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    final result = await _locationService.getCurrentPositionWithStatus();
    if (result.position != null) {
      final address = await _locationService.getAddressFromCoordinates(
        result.position!.latitude,
        result.position!.longitude,
      );
      if (mounted) {
        setState(() => _location = address);
        // Save location to Firestore so nearby donors feature works
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          _firestoreService.updateUserLocation(
            userId: uid,
            latitude: result.position!.latitude,
            longitude: result.position!.longitude,
            locationName: address,
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _location = 'Location unavailable');
        if (result.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error!),
              backgroundColor: _C.pink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context, _location),
            // Hero
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'GIVE THE GIFT OF LIFE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _C.darkText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Donate ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _C.pinkLight,
                          ),
                        ),
                        TextSpan(
                          text: 'Blood',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _C.pink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildStatCards(),
            const SizedBox(height: 12),
            Center(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: _C.greyText),
                  children: [
                    TextSpan(text: 'Each Donation can help save up to '),
                    TextSpan(
                      text: '3 lives!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _C.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Feature grid — all features available to everyone
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.search_rounded,
                          iconBgColor: _C.pinkBg,
                          iconColor: _C.pink,
                          title: 'Find Donor',
                          badge: 'Search',
                          badgeColor: _C.pink,
                          onTap: () => Navigator.pushNamed(context, '/select-blood'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.notification_important_rounded,
                          iconBgColor: _C.yellowBg,
                          iconColor: _C.yellow,
                          title: 'Requests',
                          badge: 'Help',
                          badgeColor: const Color(0xFFFF9B50),
                          onTap: () => Navigator.pushNamed(context, '/blood-request'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.water_drop_rounded,
                          iconBgColor: const Color(0xFFFFEBEE),
                          iconColor: _C.pink,
                          title: 'Donate',
                          badge: 'Give',
                          badgeColor: _C.pinkLight,
                          onTap: () => Navigator.pushNamed(context, '/donation-pages'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.shield_outlined,
                          iconBgColor: _C.mintBg,
                          iconColor: _C.mint,
                          title: 'Blood Bank',
                          badge: 'Map',
                          badgeColor: _C.mint,
                          onTap: () => Navigator.pushNamed(context, '/blood-bank'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.event_rounded,
                          iconBgColor: const Color(0xFFE3F2FD),
                          iconColor: _C.blue,
                          title: 'Blood Drives',
                          badge: 'Events',
                          badgeColor: _C.blue,
                          onTap: () => Navigator.pushNamed(context, '/blood-drives'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.emergency_rounded,
                          iconBgColor: const Color(0xFFFFEBEE),
                          iconColor: const Color(0xFFE53935),
                          title: 'Emergency',
                          badge: 'SOS',
                          badgeColor: const Color(0xFFE53935),
                          onTap: () => Navigator.pushNamed(context, '/emergency-sos'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // My Requests section
            if (user != null)
              _buildMyRequestsSection(context, user),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequestsSection(BuildContext context, User user) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('My Requests',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                    color: _C.darkText)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/blood-request'),
                child: Text('See all',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _C.pink.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService().getMyRequests(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox();
            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFF5BA8E0), size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No blood requests yet. Use the + button to post a request or donate blood.',
                          style: TextStyle(fontSize: 13,
                              color: _C.darkText, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final show = docs.take(3).toList();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: show.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final urgency = data['urgency'] ?? 'Normal';
                  final isFulfilled = urgency == 'Fulfilled';
                  final isUrgent = urgency == 'Urgent';

                  Color statusColor;
                  Color statusBg;
                  if (isFulfilled) {
                    statusColor = const Color(0xFF4CAF50);
                    statusBg = const Color(0xFFE8F5E9);
                  } else if (isUrgent) {
                    statusColor = const Color(0xFFE53935);
                    statusBg = const Color(0xFFFFEBEE);
                  } else {
                    statusColor = const Color(0xFFFF9B50);
                    statusBg = const Color(0xFFFFF3E8);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFulfilled
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                            : const Color(0xFFEDE8EB),
                      ),
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
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Icon(
                              isFulfilled ? Icons.check_circle_rounded
                                  : Icons.water_drop_rounded,
                              size: 22, color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data['bloodType'] ?? '?'} — ${data['hospital'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _C.darkText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data['unitsNeeded'] ?? 1} units · ${data['location'] ?? ''}',
                                style: TextStyle(fontSize: 12,
                                    color: _C.greyText.withValues(alpha: 0.8)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isFulfilled ? 'Fulfilled' : urgency,
                            style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Feature Card
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom Nav Item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? _C.pink : _C.greyText,
                size: 26,
              ),
            ),
            if (showBadge)
              Positioned(
                right: 8,
                top: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _C.pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

