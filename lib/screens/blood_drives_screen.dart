import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class _C {
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color blueBg = Color(0xFFE3F2FD);
}

class BloodDrivesScreen extends StatelessWidget {
  const BloodDrivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

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
          'Blood Drives',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _C.pink,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getBloodDrives(),
        builder: (context, snapshot) {
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
                  Text('Could not load events',
                      style: TextStyle(fontSize: 14,
                          color: _C.greyText.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_rounded, size: 48,
                      color: _C.greyText.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No upcoming blood drives',
                      style: TextStyle(fontSize: 15,
                          color: _C.greyText.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final attendees = List<String>.from(data['attendees'] ?? []);
              final isRsvped = user != null && attendees.contains(user.uid);
              final slots = data['slots'] as int? ?? 0;
              final spotsLeft = slots - attendees.length;
              final date = (data['date'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _C.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with date
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.pink.withValues(alpha: 0.08),
                            _C.blue.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _C.pink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  date != null ? '${date.day}' : '--',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _C.pink,
                                  ),
                                ),
                                Text(
                                  date != null ? _monthShort(date.month) : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _C.pink.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'Blood Drive',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _C.darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['organizer'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _C.greyText.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16,
                                  color: _C.greyText.withValues(alpha: 0.7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data['location'] ?? '',
                                  style: TextStyle(fontSize: 13,
                                      color: _C.greyText.withValues(alpha: 0.8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _C.greyText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer with RSVP
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          // Spots left
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: spotsLeft > 10
                                  ? _C.greenBg : _C.pinkBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              spotsLeft > 0
                                  ? '$spotsLeft spots left'
                                  : 'Full',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: spotsLeft > 10
                                    ? _C.green : _C.pink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Attendee count
                          Text(
                            '${attendees.length} going',
                            style: TextStyle(
                              fontSize: 12,
                              color: _C.greyText.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          // RSVP button
                          SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: user == null || spotsLeft <= 0 && !isRsvped
                                  ? null
                                  : () async {
                                      if (isRsvped) {
                                        await firestoreService
                                            .cancelRsvpBloodDrive(doc.id, user.uid);
                                      } else {
                                        await firestoreService
                                            .rsvpBloodDrive(doc.id, user.uid);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isRsvped ? _C.green : _C.pink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isRsvped ? 'Going' : 'RSVP',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _monthShort(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}
