import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateProfile(String name, String email) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    // Update email in FirebaseAuth
    if (email != user.email) {
      await user.updateEmail(email);
    }
    // Update Firestore profile
    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'email': email,
    });
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await user.updatePassword(newPassword);
  }

  Future<bool> getNotificationPreference() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()!.containsKey('notificationsEnabled')) {
      return doc['notificationsEnabled'] == true;
    }
    return true; // Default to enabled
  }

  Future<void> setNotificationPreference(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    await _firestore.collection('users').doc(user.uid).update({
      'notificationsEnabled': enabled,
    });
  }
} 