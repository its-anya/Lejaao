import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> fetchUserData() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    await setUser(firebaseUser);
  }

  Future<void> setUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      UserModel? userModel = await _firestoreService.getUser(firebaseUser.uid);

      if (userModel == null) {
        // Create user document if it doesn't exist
        userModel = UserModel(
          uid: firebaseUser.uid,
          displayName: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          address: '',
        );
        await _firestoreService.createUser(userModel);
      }

      _user = userModel;
    } catch (e) {
      print('Error setting user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddress(String address) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateUserAddress(_user!.uid, address);
      _user = _user!.copyWith(address: address);
    } catch (e) {
      print('Error updating address: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
} 