import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/blood_compatibility.dart';

class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkLight = Color(0xFFFF6B8A);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color orange = Color(0xFFFF9B50);
  static const Color orangeBg = Color(0xFFFFF3E8);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFE53935);
  static const Color redBg = Color(0xFFFFEBEE);
}

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  int _selectedFilter = 0;
  final _filters = ['All', 'Urgent', 'Normal', 'Fulfilled'];

  @override
  Widget build(BuildContext context) {
    // Always fetch all requests and filter client-side to avoid
    // needing a composite Firestore index on (urgency, createdAt).
    final stream = _firestoreService.getBloodRequests();

    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _C.darkText.withValues(alpha: 0.7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Blood Requests',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _C.pink,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats banner
          _buildStatsBanner(),

          const SizedBox(height: 20),

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final selected = _selectedFilter == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: selected ? _C.pink : _C.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _C.pink
                            : _C.greyText.withValues(alpha: 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _C.greyText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Request list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.pink),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 40,
                            color: _C.greyText.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Something went wrong',
                            style: TextStyle(fontSize: 14,
                                color: _C.greyText.withValues(alpha: 0.6))),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                // Apply client-side filter
                if (_selectedFilter != 0) {
                  final filterValue = _filters[_selectedFilter];
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['urgency'] == filterValue;
                  }).toList();
                }

                // Empty state
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 48,
                            color: _C.greyText.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'No requests found',
                          style: TextStyle(
                            fontSize: 15,
                            color: _C.greyText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRequestSheet(context),
        backgroundColor: _C.pink,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Request',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getBloodRequests(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs
              .where((d) => (d.data() as Map)['urgency'] != 'Fulfilled')
              .length ?? 0;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Requests',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'People need blood right now',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'just now';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildRequestCard(String docId, Map<String, dynamic> data) {
    final urgency = data['urgency'] ?? 'Normal';
    Color urgencyColor;
    Color urgencyBg;
    switch (urgency) {
      case 'Urgent':
        urgencyColor = _C.red;
        urgencyBg = _C.redBg;
        break;
      case 'Fulfilled':
        urgencyColor = _C.green;
        urgencyBg = _C.greenBg;
        break;
      default:
        urgencyColor = _C.orange;
        urgencyBg = _C.orangeBg;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _C.pinkBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    data['bloodType'] ?? '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.pink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _C.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['hospital'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  urgency,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: _C.greyText.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data['location'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: _C.greyText.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.water_drop_outlined,
                  size: 14, color: _C.greyText.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                '${data['unitsNeeded'] ?? 0} units',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.greyText.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _timeAgo(data['createdAt'] as Timestamp?),
                style: TextStyle(
                  fontSize: 11,
                  color: _C.greyText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (urgency != 'Fulfilled') ...[
            // Don't show respond button to the person who created the request
            if (data['userId'] == FirebaseAuth.instance.currentUser?.uid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: Color(0xFF5BA8E0)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is your request. Waiting for a donor to respond.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5BA8E0)),
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // Show who responded if already has a donor
            else if (data['respondedByName'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: _C.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data['respondedByName']} (${data['respondedByBloodType']}) — arriving ${data['arrivalTime']}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _C.green),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () =>
                      _showRespondSheet(context, docId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        urgency == 'Urgent' ? _C.pink : _C.pinkLight,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    urgency == 'Urgent' ? 'Respond Now' : 'I Can Help',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showRespondSheet(
      BuildContext context, String docId, Map<String, dynamic> requestData) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final requestedType = requestData['bloodType'] ?? '';
    TimeOfDay selectedTime = TimeOfDay.now();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _authService.getUserProfile(user.uid),
              builder: (ctx, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: _C.pink),
                    ),
                  );
                }

                final profile = profileSnapshot.data;
                final donorName = profile?['name'] ?? 'Anonymous';
                final donorBloodType = profile?['bloodType'] ?? '';
                final donorPhone = profile?['phone'] ?? '';
                final isCompatible = BloodCompatibility.canDonate(
                    from: donorBloodType, to: requestedType);

                return Container(
                  padding: EdgeInsets.fromLTRB(
                      20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 20),
                        const Text(
                          'Respond to Request',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _C.darkText,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Request summary
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _C.pinkBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _C.pink,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    requestedType,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      requestData['name'] ?? 'Someone',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _C.darkText,
                                      ),
                                    ),
                                    Text(
                                      '${requestData['hospital']} · ${requestData['unitsNeeded'] ?? 1} units',
                                      style: const TextStyle(
                                          fontSize: 12, color: _C.greyText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Compatibility check
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCompatible ? _C.greenBg : _C.redBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCompatible
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color:
                                    isCompatible ? _C.green : _C.red,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCompatible
                                          ? 'You are compatible!'
                                          : 'Not compatible',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isCompatible
                                            ? _C.green
                                            : _C.red,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      donorBloodType.isEmpty
                                          ? 'Please set your blood type in your profile first.'
                                          : isCompatible
                                              ? 'Your blood type ($donorBloodType) can donate to $requestedType.'
                                              : 'Your blood type ($donorBloodType) cannot donate to $requestedType.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCompatible
                                            ? _C.green
                                            : _C.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isCompatible) ...[
                          const SizedBox(height: 20),

                          // Your info
                          const Text('Your Details',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _C.darkText)),
                          const SizedBox(height: 10),
                          _respondInfoRow(
                              Icons.person_outline, 'Name', donorName),
                          const SizedBox(height: 8),
                          _respondInfoRow(Icons.bloodtype_outlined,
                              'Blood Type', donorBloodType),
                          const SizedBox(height: 8),
                          _respondInfoRow(
                            Icons.phone_outlined,
                            'Phone',
                            donorPhone.isNotEmpty
                                ? donorPhone
                                : 'Not set — add in Profile',
                          ),

                          const SizedBox(height: 20),

                          // Arrival time picker
                          const Text('When can you arrive?',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _C.darkText)),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime,
                                helpText: 'Select your arrival time',
                              );
                              if (picked != null) {
                                setSheetState(
                                    () => selectedTime = picked);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: _C.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      _C.greyText.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      color: _C.pink, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedTime.format(ctx),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _C.darkText,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Tap to change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _C.greyText
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loading
                                  ? null
                                  : () async {
                                      if (donorPhone.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Please add your phone number in your profile first.'),
                                            backgroundColor: _C.pink,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12)),
                                          ),
                                        );
                                        return;
                                      }

                                      setSheetState(
                                          () => loading = true);

                                      final now = DateTime.now();
                                      final arrivalDateTime = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      );

                                      await _firestoreService
                                          .respondToBloodRequest(
                                        requestId: docId,
                                        donorId: user.uid,
                                        donorName: donorName,
                                        donorBloodType: donorBloodType,
                                        donorPhone: donorPhone,
                                        arrivalTime: arrivalDateTime,
                                      );

                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Thank you! The requester has been notified.'),
                                            backgroundColor: _C.green,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12)),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.pink,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor:
                                    _C.pink.withValues(alpha: 0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : const Text('Confirm & Notify Requester',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _respondInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.greyText.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.pink),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 12, color: _C.greyText)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.darkText)),
        ],
      ),
    );
  }

  void _showCreateRequestSheet(BuildContext context) {
    String selectedBloodType = 'O+';
    String urgency = 'Normal';
    final hospitalCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: '1');
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 20),
                    const Text(
                      'Create Blood Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _C.darkText,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hospital field
                    TextField(
                      controller: hospitalCtrl,
                      decoration: InputDecoration(
                        labelText: 'Hospital Name',
                        labelStyle: const TextStyle(fontSize: 13, color: _C.greyText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _C.greyText.withValues(alpha: 0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Location field
                    TextField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: const TextStyle(fontSize: 13, color: _C.greyText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _C.greyText.withValues(alpha: 0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Units needed
                    TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Units Needed',
                        labelStyle: const TextStyle(fontSize: 13, color: _C.greyText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _C.greyText.withValues(alpha: 0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Blood type selector
                    const Text('Blood Type Needed',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.darkText)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bloodTypes.map((type) {
                        final sel = selectedBloodType == type;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedBloodType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 40,
                            decoration: BoxDecoration(
                              color: sel ? _C.pink : _C.pinkBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : _C.pink,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Urgency toggle
                    const Text('Urgency',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.darkText)),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Normal', 'Urgent'].map((u) {
                        final sel = urgency == u;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(() => urgency = u),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.only(
                                  right: u == 'Normal' ? 8 : 0,
                                  left: u == 'Urgent' ? 8 : 0),
                              height: 44,
                              decoration: BoxDecoration(
                                color: sel
                                    ? (u == 'Urgent' ? _C.red : _C.orange)
                                    : _C.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel
                                      ? Colors.transparent
                                      : _C.greyText.withValues(alpha: 0.2),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                u,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : _C.greyText,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final profile = await _authService.getUserProfile(user.uid);
                          final userName = profile?['name'] ?? 'Anonymous';

                          await _firestoreService.createBloodRequest(
                            userId: user.uid,
                            name: userName,
                            bloodType: selectedBloodType,
                            hospital: hospitalCtrl.text.trim().isNotEmpty
                                ? hospitalCtrl.text.trim()
                                : 'Not specified',
                            location: locationCtrl.text.trim().isNotEmpty
                                ? locationCtrl.text.trim()
                                : 'Accra',
                            urgency: urgency,
                            unitsNeeded: int.tryParse(unitsCtrl.text) ?? 1,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Blood request submitted!'),
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
                        child: const Text('Submit Request',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
