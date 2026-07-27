import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  FcmTokenService._privateConstructor();
  static final FcmTokenService instance = FcmTokenService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;

  /// Initializes FCM token handling. Requests permission and starts listening
  /// to token refresh events and authentication state changes.
  void initialize() {
    // Listen to authentication changes so we know when to store/refresh tokens
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _requestPermissionAndSaveToken(user.uid);
      } else {
        _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = null;
      }
    });
  }

  /// Requests notification permissions and fetches/saves the FCM token if granted.
  Future<void> _requestPermissionAndSaveToken(String uid) async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Permission granted, get token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(uid, token);
        }

        // Setup token refresh listener
        _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid == uid) {
            await _saveTokenToFirestore(currentUser.uid, newToken);
          }
        });
      } else {
        print('⚠️ Notification permission denied or not determined');
      }
    } catch (e) {
      print('⚠️ Error in _requestPermissionAndSaveToken: $e');
    }
  }

  /// Updates only the `fcmToken` field in the user's Firestore document.
  Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcmToken': token,
      });
      print('✅ FCM Token successfully updated in Firestore for user $uid');
    } catch (e) {
      // In case the document doesn't exist yet, we can catch it or log it.
      // The user specifically asked to use update() so no other fields are overwritten.
      print('⚠️ Error updating fcmToken in Firestore: $e');
    }
  }

  /// Clean up subscriptions if needed.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _authSubscription?.cancel();
  }
}
