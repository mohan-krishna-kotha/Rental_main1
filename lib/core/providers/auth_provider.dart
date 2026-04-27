import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'items_provider.dart'; // for firestoreServiceProvider
import '../models/kyc_model.dart';
import '../models/user_model.dart';

// Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Current user stream
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Current user model stream (Real-time profile updates + Subscription Data)
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);

  final firestoreService = ref.watch(firestoreServiceProvider);

  // Create a merged stream manually
  final userStream = firestoreService.getUserStream(currentUser.uid);
  final subStream = firestoreService.getSubscriptionStream(currentUser.uid);

  // Directly combine the streams
  return _combineLatest(userStream, subStream);
});

// Current user KYC status stream
final userKycProvider = StreamProvider<KycModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(null);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getKycStatus(currentUser.uid);
});

// Helper to merge streams
Stream<UserModel?> _combineLatest(
  Stream<UserModel?> userAbs,
  Stream<Map<String, dynamic>?> subAbs,
) {
  final controller = StreamController<UserModel?>();
  UserModel? lastUser;
  // Initialize with null/empty if needed, but here we wait for first user
  Map<String, dynamic>? lastSub;

  // Track if we have received at least one event from user stream
  // (Subscription is optional, so we can emit without it initially if needed,
  // but ideally we wait for both or handle nulls)

  // Actually, standard behavior: Wait for User. Subscription can be null.

  void update() {
    if (lastUser == null) {
      // If explicitly null (logged out or not found), emit null
      // But if just waiting, we don't emit yet?
      // userAbs emits nullable UserModel.
      controller.add(null);
      return;
    }

    // We have a user. Merge sub if available.
    if (lastSub != null) {
      controller.add(
        lastUser!.copyWith(
          subscriptionTier: lastSub!['subscriptionTier'],
          subscriptionStatus: lastSub!['subscriptionStatus'],
          subscriptionExpiry: (lastSub!['subscriptionExpiry'] as Timestamp?)
              ?.toDate(),
        ),
      );
    } else {
      // No sub data yet (or none exists). Emit user as is.
      controller.add(lastUser);
    }
  }

  // Manage subscriptions
  final userSub = userAbs.listen((u) {
    lastUser = u;
    update();
  });

  final subSub = subAbs.listen((s) {
    lastSub = s;
    update();
  });

  controller.onCancel = () {
    userSub.cancel();
    subSub.cancel();
  };

  return controller.stream;
}

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService(this._auth);

  // Email/Password Sign Up
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email/Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign In failed: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update Display Name
  Future<void> updateDisplayName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user logged in.',
        );
      }

      await user.updateDisplayName(newName);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Re-authenticate User
  Future<void> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user logged in.',
        );
      }

      // Create credential with email and password
      // Note: This assumes email/password auth. For Google, we'd need a different flow.
      // But for "Change Password", we typically only need this for email/password users.
      // Google users manage password via Google.
      if (user.email == null) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'User has no email.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user logged in.',
        );
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPhoneOtp({
    required String tenDigitPhone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in.';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(tenDigitPhone)) {
      throw 'Phone number must be exactly 10 digits.';
    }

    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$tenDigitPhone',
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _linkOrUpdatePhoneCredential(credential);
          if (!completer.isCompleted) {
            completer.complete();
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        final mapped = _handleAuthException(e);
        final message = '$mapped [${e.code}] ${e.message ?? ''}'.trim();
        if (!completer.isCompleted) {
          completer.completeError(message);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No-op: user can still enter OTP manually.
      },
    );

    return completer.future;
  }

  Future<void> verifyOtpAndLinkPhone({
    required String verificationId,
    required String smsCode,
    required String tenDigitPhone,
  }) async {
    if (!RegExp(r'^\d{10}$').hasMatch(tenDigitPhone)) {
      throw 'Phone number must be exactly 10 digits.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(smsCode)) {
      throw 'OTP must be exactly 6 digits.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _linkOrUpdatePhoneCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> _linkOrUpdatePhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in.';
    }

    try {
      if ((user.phoneNumber ?? '').isEmpty) {
        await user.linkWithCredential(credential);
      } else {
        await user.updatePhoneNumber(credential);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        await user.updatePhoneNumber(credential);
      } else {
        rethrow;
      }
    }

    await user.reload();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'For security, please log in again before changing your password.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled in Firebase. Enable Phone provider in Firebase Auth settings.';
      case 'invalid-phone-number':
        return 'The phone number is invalid. Enter a valid 10-digit mobile number.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please retry and complete the verification challenge.';
      case 'invalid-app-credential':
        return 'App verification failed. Add SHA-1/SHA-256 in Firebase project settings and use the latest google-services configuration.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase Phone Auth. Check package name, SHA certificates, and Firebase app configuration.';
      case 'missing-client-identifier':
        return 'Missing app client identifier for verification. Verify Firebase app registration and configuration files.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later or use Firebase test phone numbers during development.';
      default:
        return 'Authentication error (${e.code}): ${e.message ?? 'Unknown error'}';
    }
  }
}
