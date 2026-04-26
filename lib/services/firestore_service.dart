import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'blood_compatibility.dart';

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

  /// Notifies all compatible donors who can donate to the requested blood type.
  Future<void> _notifyMatchingDonors({
    required String excludeUserId,
    required String bloodType,
    required String hospital,
    required String urgency,
  }) async {
    try {
      final compatibleTypes = BloodCompatibility.compatibleDonors(
          BloodCompatibility.normalize(bloodType));

      if (compatibleTypes.isEmpty) return;

      final batch = _db.batch();

      for (final type in compatibleTypes) {
        final snapshot = await _db
            .collection('users')
            .where('bloodType', isEqualTo: type)
            .get();

        for (final doc in snapshot.docs) {
          if (doc.id == excludeUserId) continue;

          final notifRef = _db.collection('notifications').doc();
          batch.set(notifRef, {
            'userId': doc.id,
            'title': urgency == 'Urgent'
                ? 'Urgent: $bloodType Blood Needed!'
                : '$bloodType Blood Request Nearby',
            'body':
                '$hospital needs $bloodType donors. Your blood type ($type) is compatible. Can you help?',
            'type': urgency == 'Urgent' ? 'urgent' : 'info',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (_) {}
  }

  /// Records a donor's response to a blood request.
  /// Saves who responded, their blood type, phone, and chosen arrival time.
  /// Marks the request as fulfilled and notifies the requester.
  Future<void> respondToBloodRequest({
    required String requestId,
    required String donorId,
    required String donorName,
    required String donorBloodType,
    required String donorPhone,
    required DateTime arrivalTime,
  }) async {
    final doc = await _db.collection('blood_requests').doc(requestId).get();
    final data = doc.data();
    if (data == null) return;

    final hour = arrivalTime.hour;
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final arrivalStr = '$displayHour:$minute $period';

    // Save the donor response on the request document
    await _db.collection('blood_requests').doc(requestId).update({
      'urgency': 'Fulfilled',
      'status': 'fulfilled',
      'respondedBy': donorId,
      'respondedByName': donorName,
      'respondedByBloodType': donorBloodType,
      'respondedByPhone': donorPhone,
      'arrivalTime': arrivalStr,
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // Notify the requester with donor details
    final requesterId = data['userId'] as String?;
    final bloodType = data['bloodType'] ?? '';
    final hospital = data['hospital'] ?? '';
    if (requesterId != null) {
      await createNotification(
        userId: requesterId,
        title: 'Donor Found!',
        body:
            '$donorName ($donorBloodType) has responded to your $bloodType request at $hospital. '
            'They will arrive at $arrivalStr. '
            'Contact: $donorPhone',
        type: 'donation',
      );
    }

    // Confirm to the donor
    await createNotification(
      userId: donorId,
      title: 'Response Confirmed',
      body:
          'You\'ve pledged to donate $donorBloodType at $hospital by $arrivalStr. '
          'Thank you for saving a life!',
      type: 'donation',
    );
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
        .get();

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
      }
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

  /// EMERGENCY SOS

  /// Broadcasts an emergency blood request to all compatible donors.
  /// Uses blood compatibility to notify donors with matching types.
  Future<void> sendEmergencySOS({
    required String userId,
    required String name,
    required String bloodType,
    required String hospital,
    required String location,
    required double latitude,
    required double longitude,
    required List<String> compatibleTypes,
  }) async {
    await _db.collection('blood_requests').add({
      'userId': userId,
      'name': name,
      'bloodType': bloodType,
      'hospital': hospital,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'urgency': 'Emergency',
      'unitsNeeded': 1,
      'status': 'active',
      'isEmergency': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      userId: userId,
      title: 'Emergency SOS Sent',
      body: 'Your emergency $bloodType request has been broadcast to nearby compatible donors.',
      type: 'urgent',
    );

    try {
      final batch = _db.batch();
      for (final type in compatibleTypes) {
        final donors = await _db
            .collection('users')
            .where('bloodType', isEqualTo: type)
            .get();

        for (final doc in donors.docs) {
          if (doc.id == userId) continue;
          final notifRef = _db.collection('notifications').doc();
          batch.set(notifRef, {
            'userId': doc.id,
            'title': 'EMERGENCY: $bloodType Blood Needed!',
            'body': '$name needs $bloodType blood urgently at $hospital, $location. Tap to respond.',
            'type': 'urgent',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  /// GPS / LOCATION

  /// Updates a user's location coordinates.
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    await _db.collection('users').doc(userId).set({
      'latitude': latitude,
      'longitude': longitude,
      'location': locationName,
    }, SetOptions(merge: true));
  }

  /// Fetches donors who have location data.
  Future<List<QueryDocumentSnapshot>> getNearbyDonors({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final snapshot = await _db
        .collection('users')
        .where('bloodType', isNotEqualTo: '')
        .get();

    final donors = <QueryDocumentSnapshot>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      if (lat == null || lng == null) continue;

      final distance = _haversine(latitude, longitude, lat, lng);
      if (distance <= radiusKm) {
        donors.add(doc);
      }
    }
    return donors;
  }

  /// Haversine formula — calculates distance between two GPS points in km.
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * (3.141592653589793 / 180);

  /// DONATION STREAKS

  /// Gets the donation count for a user in the current year.
  Future<int> getDonationCountThisYear(String userId) async {
    final startOfYear = DateTime(DateTime.now().year, 1, 1);
    final snapshot = await _db
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .get();
    return snapshot.docs.length;
  }

  /// Gets the total donation count for a user (all time).
  Future<int> getTotalDonationCount(String userId) async {
    final snapshot = await _db
        .collection('donations')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }
}
