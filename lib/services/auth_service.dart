import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': '',
      'location': '',
      'dob': '',
      'bloodType': '',
      'bloodTypeVerified': false,
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<String?> getUserRole(String uid) async {
    final profile = await getUserProfile(uid);
    final role = profile?['role'] as String?;
    return (role != null && role.isNotEmpty) ? role : null;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}
