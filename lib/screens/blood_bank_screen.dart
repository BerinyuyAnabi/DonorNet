import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';

/// URL LAUNCHER:
/// We use the url_launcher package to open the phone dialer and maps app.
/// - `tel:+233...` opens the phone dialer with the number pre-filled
/// - `geo:0,0?q=address` opens Google Maps with a search for that address
/// We need to add this package to pubspec.yaml.

class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color mint = Color(0xFF7DD6B8);
  static const Color mintBg = Color(0xFFE0F7F0);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color red = Color(0xFFE53935);
}

class BloodBankScreen extends StatefulWidget {
  const BloodBankScreen({super.key});

  @override
  State<BloodBankScreen> createState() => _BloodBankScreenState();
}

class _BloodBankScreenState extends State<BloodBankScreen> {
  final _firestoreService = FirestoreService();
  int _selectedFilter = 0;
  final _filters = ['All', 'Nearby', 'Open Now'];

  @override
  Widget build(BuildContext context) {
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
          'Blood Banks',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _C.mint,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header banner — now shows real count from Firestore
          _buildHeader(),

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
                      color: selected ? _C.mint : _C.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _C.mint
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

          /// STREAMBUILDER FOR BLOOD BANKS:
          /// Same pattern as blood requests — listen to the "blood_banks"
          /// collection and rebuild whenever data changes.
          /// We apply filters client-side after fetching all banks.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getBloodBanks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _C.mint),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 40,
                            color: Colors.grey.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Could not load blood banks',
                            style: TextStyle(fontSize: 14,
                                color: Colors.grey.withValues(alpha: 0.6))),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Apply filters client-side
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  switch (_selectedFilter) {
                    case 1: // Nearby — within 5km
                      final dist = double.tryParse(
                        (data['distance'] ?? '99 km')
                            .toString()
                            .replaceAll(' km', ''),
                      ) ?? 99;
                      return dist <= 5;
                    case 2: // Open Now
                      return data['isOpen'] == true;
                    default:
                      return true;
                  }
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text('No blood banks found',
                        style: TextStyle(
                            color: _C.greyText.withValues(alpha: 0.6))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _buildBankCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getBloodBanks(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF7DD6B8), Color(0xFF5BB89E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.mint.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20, top: -20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -15, bottom: -15,
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on_rounded,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$count blood banks near you',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accra, Ghana',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final address = data['address'] ?? '';
    final distance = data['distance'] ?? '';
    final isOpen = data['isOpen'] ?? false;
    final openHours = data['openHours'] ?? '';
    final phone = data['phone'] ?? '';
    // Firestore stores lists as List<dynamic>, so we cast each item
    final availableTypes = List<String>.from(data['availableTypes'] ?? []);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _C.mintBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital_rounded,
                    color: _C.mint, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: _C.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(address,
                        style: const TextStyle(
                            fontSize: 12, color: _C.greyText)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? _C.greenBg : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: isOpen ? _C.green : _C.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: _C.greyText.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(openHours,
                style: TextStyle(fontSize: 12,
                    color: _C.greyText.withValues(alpha: 0.8)),
              ),
              const Spacer(),
              Icon(Icons.directions_walk_rounded,
                  size: 14, color: _C.greyText.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(distance,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: _C.darkText.withValues(alpha: 0.7)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Available blood types
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('Available: ',
                style: TextStyle(fontSize: 12,
                    color: _C.greyText.withValues(alpha: 0.7)),
              ),
              ...availableTypes.map((type) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.pinkBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(type,
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _C.pink,
                  ),
                ),
              )),
            ],
          ),

          const SizedBox(height: 14),

          /// CALL & DIRECTIONS BUTTONS — now functional!
          /// url_launcher opens the phone dialer or maps app.
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(phone),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text('Call',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.mint,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(address),
                    icon: Icon(Icons.directions_rounded,
                        size: 16, color: _C.mint),
                    label: Text('Directions',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: _C.mint)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _C.mint),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens the phone dialer with the blood bank's number.
  /// `tel:` is a URI scheme that Android/iOS recognise.
  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Opens Google Maps (or Apple Maps on iOS) with directions
  /// to the blood bank's address.
  Future<void> _openDirections(String address) async {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
