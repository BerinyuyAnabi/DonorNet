import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/firestore_service.dart';
import 'services/push_notification_service.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_page.dart';
import 'screens/auth_landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/select_blood_group_screen.dart';
import 'screens/donor_loader.dart';
import 'screens/donor_data.dart';
import 'screens/profile_screen.dart';
import 'screens/donation_pages_screen.dart';
import 'screens/blood_request_screen.dart';
import 'screens/blood_bank_screen.dart';
import 'screens/blood_drives_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService().initialize();

  await FirestoreService().seedBloodBanks();
  await FirestoreService().seedBloodDrives();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DonorNet',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      home: const _RootRouter(),
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const AuthLandingScreen(),
        '/home': (context) => const HomeScreen(),
        '/select-blood': (context) => const SelectBloodGroupScreen(),
        '/nearby-donors': (context) => const NearbyDonorLoader(),
        '/all-donators': (context) => const AllDonatorsLoader(),
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final donor = (args is DonorData) ? args : null;
          return ProfileScreen(donor: donor);
        },
        '/donation-pages': (context) => const DonationPagesScreen(),
        '/blood-request': (context) => const BloodRequestScreen(),
        '/blood-bank': (context) => const BloodBankScreen(),
        '/blood-drives': (context) => const BloodDrivesScreen(),
      },
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _wasLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (authSnapshot.hasData) {
          _wasLoggedIn = true;
          return const HomeScreen();
        }

        if (_wasLoggedIn) {
          return const AuthLandingScreen();
        }

        return const SplashScreen();
      },
    );
  }
}
