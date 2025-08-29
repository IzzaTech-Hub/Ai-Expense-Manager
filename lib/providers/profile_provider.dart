import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  String _name = 'User';
  String _email = 'user@example.com';
  bool _isLoading = false;
  String? _error;
  bool _notificationsEnabled = true;

  String get name => _name;
  String get email => _email;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // For now, use default values since we're not using Firebase
      _name = 'User';
      _email = 'user@example.com';
      _notificationsEnabled = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Update local values
      _name = name;
      _email = email;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // For now, just simulate success
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setNotificationPreference(bool enabled) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _notificationsEnabled = enabled;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 