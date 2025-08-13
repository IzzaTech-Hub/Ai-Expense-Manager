import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  String _name = '';
  String _email = '';
  bool _isLoading = false;
  String? _error;
  bool _notificationsEnabled = true;

  String get name => _name;
  String get email => _email;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get notificationsEnabled => _notificationsEnabled;

  final ProfileService _profileService = ProfileService();

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _profileService.getProfile();
      if (data != null) {
        _name = data['name'] ?? '';
        _email = data['email'] ?? '';
        _notificationsEnabled = data['notificationsEnabled'] ?? true;
      }
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
      await _profileService.updateProfile(name, email);
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
      await _profileService.updatePassword(newPassword);
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
      await _profileService.setNotificationPreference(enabled);
      _notificationsEnabled = enabled;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 