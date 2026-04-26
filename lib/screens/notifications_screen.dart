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
  static const Color border = Color(0xFFEDE8EB);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color blueBg = Color(0xFFE3F2FD);
  static const Color orange = Color(0xFFFF9B50);
  static const Color orangeBg = Color(0xFFFFF3E8);
  static const Color red = Color(0xFFE53935);
  static const Color redBg = Color(0xFFFFEBEE);
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    return SafeArea(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
              child: Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _C.darkText,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    /// MARK ALL READ:
                    /// Gets all unread notifications for this user and
                    /// updates them in a batch (one network call).
                    onPressed: () async {
                      if (user == null) return;
                      await firestoreService.markAllNotificationsRead(user.uid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('All marked as read'),
                            backgroundColor: _C.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Mark all read',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w500, color: _C.pink)),
                  ),
                ],
              ),
            ),

            // Notifications list from Firestore
            Expanded(
              child: user == null
                  ? const Center(child: Text('Please sign in'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: firestoreService.getNotifications(user.uid),
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
                                Text('Could not load notifications',
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
                                Icon(Icons.notifications_off_outlined,
                                    size: 48,
                                    color: _C.greyText.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _C.greyText.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You\'ll see updates here when you\ndonate or receive blood requests',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _C.greyText.withValues(alpha: 0.5),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Group by date
                        final grouped = _groupByDate(docs);

                        return ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: grouped.length,
                          itemBuilder: (_, i) {
                            final group = grouped[i];
                            if (group is String) {
                              return _dateHeader(group);
                            }
                            final doc = group as QueryDocumentSnapshot;
                            final data = doc.data() as Map<String, dynamic>;
                            return _notifCard(data);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      );
  }

  /// Groups notifications into sections: Today, Yesterday, Earlier.
  /// Returns a mixed list of String headers and QueryDocumentSnapshot items.
  List<dynamic> _groupByDate(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final result = <dynamic>[];
    bool addedToday = false;
    bool addedYesterday = false;
    bool addedEarlier = false;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp == null) {
        if (!addedEarlier) { result.add('Earlier'); addedEarlier = true; }
        result.add(doc);
        continue;
      }

      final date = timestamp.toDate();
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        if (!addedToday) { result.add('Today'); addedToday = true; }
      } else if (dateOnly == yesterday) {
        if (!addedYesterday) { result.add('Yesterday'); addedYesterday = true; }
      } else {
        if (!addedEarlier) { result.add('Earlier'); addedEarlier = true; }
      }
      result.add(doc);
    }

    return result;
  }

  Widget _dateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _C.greyText.withValues(alpha: 0.7),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Maps notification type to icon and colors.
  /// This keeps the UI consistent with the notification's purpose.
  ({IconData icon, Color iconBg, Color iconColor}) _typeStyle(String type) {
    switch (type) {
      case 'urgent':
        return (icon: Icons.bloodtype_rounded, iconBg: _C.redBg, iconColor: _C.red);
      case 'donation':
        return (icon: Icons.check_circle_outline_rounded, iconBg: _C.greenBg, iconColor: _C.green);
      case 'reminder':
        return (icon: Icons.timer_outlined, iconBg: _C.orangeBg, iconColor: _C.orange);
      case 'event':
        return (icon: Icons.campaign_outlined, iconBg: _C.pinkBg, iconColor: _C.pink);
      default:
        return (icon: Icons.info_outline_rounded, iconBg: _C.blueBg, iconColor: _C.blue);
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final d = timestamp.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _notifCard(Map<String, dynamic> data) {
    final type = data['type'] ?? 'info';
    final isUnread = data['isRead'] != true;
    final style = _typeStyle(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? _C.pinkBg.withValues(alpha: 0.4)
              : _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? _C.pink.withValues(alpha: 0.12)
                : _C.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: style.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, size: 20, color: style.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(data['title'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700 : FontWeight.w600,
                            color: _C.darkText,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _C.pink,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data['body'] ?? '',
                    style: const TextStyle(fontSize: 13, color: _C.greyText,
                        height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(data['createdAt'] as Timestamp?),
                    style: TextStyle(fontSize: 11,
                        color: _C.greyText.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
