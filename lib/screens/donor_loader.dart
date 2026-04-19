import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donor_data.dart';
import 'nearby_donor_screen.dart';
import 'all_donators_screen.dart';

class NearbyDonorLoader extends StatelessWidget {
  const NearbyDonorLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('bloodType', isNotEqualTo: '')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D6D)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48,
                      color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Something went wrong',
                      style: TextStyle(fontSize: 15,
                          color: Colors.grey.withValues(alpha: 0.6))),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final donors = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return DonorData(
            name: data['name'] ?? 'Unknown',
            location: data['location'] ?? 'Nearby',
            bloodType: data['bloodType'] ?? '',
            distance: '${(docs.indexOf(doc) + 1) * 2}km',
          );
        }).toList();

        // If no donors in the database yet, show at least a message
        if (donors.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
              child: Text('No donors registered yet',
                style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E))),
            ),
          );
        }

        return NearbyDonorScreen(nearbyDonors: donors);
      },
    );
  }
}

class AllDonatorsLoader extends StatelessWidget {
  const AllDonatorsLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('bloodType', isNotEqualTo: '')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D6D)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48,
                      color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Something went wrong',
                      style: TextStyle(fontSize: 15,
                          color: Colors.grey.withValues(alpha: 0.6))),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final donors = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return DonorData(
            name: data['name'] ?? 'Unknown',
            location: data['location'] ?? 'Nearby',
            bloodType: data['bloodType'] ?? '',
            distance: '${(docs.indexOf(doc) + 1) * 2}km',
          );
        }).toList();

        return AllDonatorsScreen(
          bloodTypeLabel: 'All Types',
          bloodTypeShort: 'All',
          badgeText: 'All',
          requestCount: donors.length,
          donors: donors,
        );
      },
    );
  }
}
