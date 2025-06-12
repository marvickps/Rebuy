import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserData();
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
        // Update online status
        await updateOnlineStatus(true);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load user data: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final userModel = UserModel(
          uid: result.user!.uid,
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap());

        _userModel = userModel;
        _setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    }
    
    _setLoading(false);
    return false;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    }
    
    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    try {
      if (_user != null) {
        await updateOnlineStatus(false);
      }
      await _auth.signOut();
      _userModel = null;
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (_user == null || _userModel == null) return;

    try {
      _setLoading(true);
      
      final updatedUser = _userModel!.copyWith(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());

      _userModel = updatedUser;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently handle online status errors
    }
  }

  Future<void> addToFavorites(String productId) async {
    if (_userModel == null) return;

    try {
      final favorites = List<String>.from(_userModel!.favorites);
      if (!favorites.contains(productId)) {
        favorites.add(productId);
        
        await _firestore.collection('users').doc(_user!.uid).update({
          'favorites': favorites,
        });

        _userModel = _userModel!.copyWith(favorites: favorites);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to add to favorites: ${e.toString()}');
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    if (_userModel == null) return;

    try {
      final favorites = List<String>.from(_userModel!.favorites);
      if (favorites.contains(productId)) {
        favorites.remove(productId);
        
        await _firestore.collection('users').doc(_user!.uid).update({
          'favorites': favorites,
        });

        _userModel = _userModel!.copyWith(favorites: favorites);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to remove from favorites: ${e.toString()}');
    }
  }

  bool isFavorite(String productId) {
    return _userModel?.favorites.contains(productId) ?? false;
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

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}