import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, UserModel> _users = {};
  bool _isLoading = false;
  String _errorMessage = '';

  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<UserModel?> getUser(String userId) async {
    if (_users.containsKey(userId)) {
      return _users[userId];
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        _users[userId] = user;
        notifyListeners();
        return user;
      }
      return null;
    } catch (e) {
      _setError('Failed to get user: ${e.toString()}');
      return null;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      _setLoading(true);
      _clearError();

      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();

      // Cache users
      for (final user in users) {
        _users[user.uid] = user;
      }

      _setLoading(false);
      return users;
    } catch (e) {
      _setError('Failed to search users: ${e.toString()}');
      _setLoading(false);
      return [];
    }
  }

  Future<bool> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      });

      // Update cached user
      if (_users.containsKey(userId)) {
        _users[userId] = _users[userId]!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update online status: ${e.toString()}');
      return false;
    }
  }

  String getOnlineStatus(String userId) {
    final user = _users[userId];
    if (user == null) return 'Unknown';
    
    if (user.isOnline) {
      return 'Online';
    } else if (user.lastSeen != null) {
      final diff = DateTime.now().difference(user.lastSeen!);
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    }
    
    return 'Offline';
  }

  void clearCache() {
    _users.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}