import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// BLOOD REQUESTS

  /// Fetches all blood requests, newest first.
  Stream<QuerySnapshot> getBloodRequests() {
    return _db
        .collection('blood_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Fetches blood requests filtered by urgency.
  Stream<QuerySnapshot> getBloodRequestsByUrgency(String urgency) {
    return _db
        .collection('blood_requests')
        .where('urgency', isEqualTo: urgency)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Creates a new blood request and notifies relevant users.
  Future<void> createBloodRequest({
    required String userId,
    required String name,
    required String bloodType,
    required String hospital,
    required String location,
    required String urgency,
    required int unitsNeeded,
  }) async {
    await _db.collection('blood_requests').add({
      'userId': userId,
      'name': name,
      'bloodType': bloodType,
      'hospital': hospital,
      'location': location,
      'urgency': urgency,
      'unitsNeeded': unitsNeeded,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    /// Notify the requester
    await createNotification(
      userId: userId,
      title: urgency == 'Urgent'
          ? 'Urgent Request Submitted'
          : 'Request Submitted',
      body:
          '$bloodType blood request at $hospital has been posted. You\'ll be notified when a donor responds.',
      type: urgency == 'Urgent' ? 'urgent' : 'info',
    );

    /// Notify matching donors
    await _notifyMatchingDonors(
      excludeUserId: userId,
      bloodType: bloodType,
      hospital: hospital,
      urgency: urgency,
    );
  }

  /// Notifies donors with a matching blood type.
  Future<void> _notifyMatchingDonors({
    required String excludeUserId,
    required String bloodType,
    required String hospital,
    required String urgency,
  }) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('bloodType', isEqualTo: bloodType)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        /// Don't notify the person who created the request
        if (doc.id == excludeUserId) continue;

        final notifRef = _db.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': doc.id,
          'title': urgency == 'Urgent'
              ? 'Urgent: $bloodType Blood Needed!'
              : '$bloodType Blood Request Nearby',
          'body': '$hospital needs $bloodType donors. Can you help?',
          'type': urgency == 'Urgent' ? 'urgent' : 'info',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Marks a blood request as fulfilled and notifies the requester.
  Future<void> fulfillBloodRequest(String requestId) async {
    final doc = await _db.collection('blood_requests').doc(requestId).get();
    final data = doc.data();

    await _db.collection('blood_requests').doc(requestId).update({
      'urgency': 'Fulfilled',
      'status': 'fulfilled',
    });

    if (data != null) {
      try {
        final userId = data['userId'] as String?;
        final bloodType = data['bloodType'] ?? '';
        final hospital = data['hospital'] ?? '';
        if (userId != null) {
          await createNotification(
            userId: userId,
            title: 'Donor Found!',
            body:
                'A donor has responded to your $bloodType request at $hospital. Your request has been fulfilled!',
            type: 'donation',
          );
        }
      } catch (_) {}
    }
  }

  /// DONORS

  /// Fetches all registered donors.
  Stream<QuerySnapshot> getDonors() {
    return _db
        .collection('users')
        .where('bloodType', isNotEqualTo: '')
        .snapshots();
  }

  /// Fetches donors with a specific blood type.
  Future<QuerySnapshot> getDonorsByBloodType(String bloodType) {
    return _db
        .collection('users')
        .where('bloodType', isEqualTo: bloodType)
        .get();
  }

  /// Fetches blood requests matching a specific blood type.
  Stream<QuerySnapshot> getRequestsForBloodType(String bloodType) {
    return _db
        .collection('blood_requests')
        .where('bloodType', isEqualTo: bloodType)
        .where('urgency', isNotEqualTo: 'Fulfilled')
        .orderBy('urgency')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Fetches blood requests posted by a specific user.
  Stream<QuerySnapshot> getMyRequests(String userId) {
    return _db
        .collection('blood_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// BLOOD BANKS

  /// Fetches all blood banks.
  Stream<QuerySnapshot> getBloodBanks() {
    return _db.collection('blood_banks').snapshots();
  }

  /// Seeds initial blood bank data (run once).
  Future<void> seedBloodBanks() async {
    final collection = _db.collection('blood_banks');
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final banks = [
      {
        'name': 'National Blood Service',
        'address': '37 Korle Bu, Accra',
        'distance': '1.2 km',
        'isOpen': true,
        'openHours': '8:00 AM - 6:00 PM',
        'phone': '+233 30 266 5401',
        'availableTypes': ['A+', 'A-', 'B+', 'O+', 'O-'],
      },
      {
        'name': 'Accra Blood Centre',
        'address': 'Ridge Hospital Road, Accra',
        'distance': '2.5 km',
        'isOpen': true,
        'openHours': '7:30 AM - 5:00 PM',
        'phone': '+233 30 277 1234',
        'availableTypes': ['A+', 'B+', 'AB+', 'O+'],
      },
      {
        'name': '37 Military Hospital Blood Bank',
        'address': '37 Military Hospital, Accra',
        'distance': '3.8 km',
        'isOpen': false,
        'openHours': '8:00 AM - 4:00 PM',
        'phone': '+233 30 277 6111',
        'availableTypes': ['A+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
      },
      {
        'name': 'Tema General Blood Bank',
        'address': 'Tema General Hospital',
        'distance': '12.4 km',
        'isOpen': true,
        'openHours': '8:00 AM - 5:00 PM',
        'phone': '+233 30 320 2345',
        'availableTypes': ['A+', 'B+', 'O+'],
      },
      {
        'name': 'University of Ghana Medical Centre',
        'address': 'Legon, Accra',
        'distance': '6.1 km',
        'isOpen': true,
        'openHours': '7:00 AM - 7:00 PM',
        'phone': '+233 30 250 0000',
        'availableTypes': ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+'],
      },
    ];

    final batch = _db.batch();
    for (final bank in banks) {
      batch.set(collection.doc(), bank);
    }
    await batch.commit();
  }

  /// DONATIONS

  /// Records a completed donation.
  Future<void> recordDonation({
    required String userId,
    required String type,
    required String location,
  }) async {
    await _db.collection('donations').add({
      'userId': userId,
      'type': type,
      'location': location,
      'status': 'Completed',
      'date': FieldValue.serverTimestamp(),
    });

    await createNotification(
      userId: userId,
      title: 'Donation Registered',
      body:
          'Your $type donation has been registered successfully. Thank you for saving lives!',
      type: 'donation',
    );
  }

  /// Fetches a user's donation history, newest first.
  Stream<QuerySnapshot> getDonationHistory(String userId) {
    return _db
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  /// NOTIFICATIONS

  /// Fetches notifications for a specific user, newest first.
  Stream<QuerySnapshot> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Creates an in-app notification for a user.
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks all notifications for a user as read.
  Future<void> markAllNotificationsRead(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// BLOOD TYPE VERIFICATION

  /// Marks a user's blood type as verified.
  Future<void> verifyBloodType(String userId) async {
    await _db.collection('users').doc(userId).set({
      'bloodTypeVerified': true,
    }, SetOptions(merge: true));
  }

  /// BLOOD DRIVES / EVENTS

  /// Fetches upcoming blood drive events, sorted by date.
  Stream<QuerySnapshot> getBloodDrives() {
    return _db
        .collection('blood_drives')
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date')
        .snapshots();
  }

  /// RSVP to a blood drive.
  Future<void> rsvpBloodDrive(String driveId, String userId) async {
    await _db.collection('blood_drives').doc(driveId).update({
      'attendees': FieldValue.arrayUnion([userId]),
    });

    await createNotification(
      userId: userId,
      title: 'RSVP Confirmed',
      body:
          'You\'re signed up for the blood drive! We\'ll remind you before the event.',
      type: 'event',
    );
  }

  /// Cancel RSVP for a blood drive.
  Future<void> cancelRsvpBloodDrive(String driveId, String userId) async {
    await _db.collection('blood_drives').doc(driveId).update({
      'attendees': FieldValue.arrayRemove([userId]),
    });
  }

  /// Seeds sample blood drive events (run once).
  Future<void> seedBloodDrives() async {
    final collection = _db.collection('blood_drives');
    final snapshot = await collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final now = DateTime.now();
    final drives = [
      {
        'title': 'University of Ghana Blood Drive',
        'location': 'Great Hall, Legon Campus',
        'date': Timestamp.fromDate(now.add(const Duration(days: 7))),
        'organizer': 'National Blood Service',
        'description':
            'Join us for a community blood drive. Free health screening for all donors. Refreshments provided.',
        'slots': 50,
        'attendees': <String>[],
      },
      {
        'title': 'Accra Mall Donation Day',
        'location': 'Accra Mall, Ground Floor',
        'date': Timestamp.fromDate(now.add(const Duration(days: 14))),
        'organizer': 'Accra Blood Centre',
        'description':
            'Walk-in blood donation event. All blood types welcome. Each donor receives a free health check.',
        'slots': 30,
        'attendees': <String>[],
      },
      {
        'title': 'World Blood Donor Day',
        'location': 'Korle Bu Teaching Hospital',
        'date': Timestamp.fromDate(now.add(const Duration(days: 21))),
        'organizer': 'Ghana Health Service',
        'description':
            'Celebrate World Blood Donor Day by giving the gift of life. Music, food, and community.',
        'slots': 100,
        'attendees': <String>[],
      },
    ];

    final batch = _db.batch();
    for (final drive in drives) {
      batch.set(collection.doc(), drive);
    }
    await batch.commit();
  }

  /// APPOINTMENT SCHEDULING

  /// Schedules a donation appointment at a blood bank.
  Future<void> scheduleAppointment({
    required String userId,
    required String bloodBankName,
    required DateTime dateTime,
    required String donationType,
  }) async {
    await _db.collection('appointments').add({
      'userId': userId,
      'bloodBank': bloodBankName,
      'dateTime': Timestamp.fromDate(dateTime),
      'donationType': donationType,
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      userId: userId,
      title: 'Appointment Scheduled',
      body:
          '$donationType donation at $bloodBankName on ${dateTime.day}/${dateTime.month}/${dateTime.year}',
      type: 'reminder',
    );
  }

  /// Fetches a user's upcoming appointments.
  Stream<QuerySnapshot> getAppointments(String userId) {
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('dateTime')
        .snapshots();
  }
}
