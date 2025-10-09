import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/firebase_manager.dart';
import '../../../core/helper/secure_storage.dart';
import 'security_service.dart';

/// Apple Sign-In Integration Service
class AppleSignInService {
  static final AppleSignInService _instance = AppleSignInService._internal();
  factory AppleSignInService() => _instance;
  AppleSignInService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecurityService _security = SecurityService();

  // Storage keys
  static const String _appleUserKey = 'apple_user_data';
  static const String _appleCredentialKey = 'apple_credential';

  /// Check if Apple Sign-In is available on this device
  Future<bool> isAppleSignInAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Check Apple Sign-In availability failed');
      return false;
    }
  }

  /// Generate secure nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Create SHA256 hash of nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign in with Apple
  Future<AppleSignInResult> signInWithApple({
    List<AppleIDAuthorizationScopes> scopes = const [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
  }) async {
    try {
      // Check rate limiting
      final rateLimitResult = await _security.checkRateLimit(
        identifier: 'apple_signin',
        maxAttempts: 3,
        timeWindow: const Duration(minutes: 15),
      );

      if (!rateLimitResult.isAllowed) {
        await _security.logSecurityEvent(
          SecurityEventType.rateLimitExceeded,
          'Apple Sign-In rate limit exceeded',
          metadata: {
            'remaining_time': rateLimitResult.blockedDuration?.inMinutes,
          },
        );
        
        return AppleSignInResult.rateLimited(rateLimitResult.blockedDuration!);
      }

      // Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: scopes,
        nonce: nonce,
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        await _security.recordAuthAttempt(
          identifier: 'apple_signin',
          success: false,
          metadata: {'error': 'User is null after Apple Sign-In'},
        );
        
        return AppleSignInResult.error('Authentication failed: User is null');
      }

      // Store Apple user data
      await _storeAppleUserData(appleCredential, user);

      // Record successful authentication
      await _security.recordAuthAttempt(
        identifier: 'apple_signin',
        success: true,
        metadata: {
          'user_id': user.uid,
          'email': user.email,
          'provider': 'apple.com',
        },
      );

      // Create secure session
      final sessionToken = await _security.createSession(
        userId: user.uid,
        metadata: {
          'auth_provider': 'apple',
          'email': user.email,
          'display_name': user.displayName,
        },
      );

      // Log successful sign-in
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Apple Sign-In successful',
        metadata: {
          'user_id': user.uid,
          'email': user.email,
          'session_token_hash': sessionToken.substring(0, 16),
        },
      );

      // Track analytics
      AnalyticsHelper.trackUserAction('apple_signin_success', parameters: {
        'user_id': user.uid,
        'email': user.email,
        'is_new_user': userCredential.additionalUserInfo?.isNewUser ?? false,
      });

      return AppleSignInResult.success(
        user: user,
        appleCredential: appleCredential,
        sessionToken: sessionToken,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );

    } on SignInWithAppleAuthorizationException catch (e) {
      await _handleAppleSignInError(e);
      return AppleSignInResult.error(_getAppleErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      await _handleFirebaseAuthError(e);
      return AppleSignInResult.error(_getFirebaseErrorMessage(e));
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Apple Sign-In failed');
      
      await _security.recordAuthAttempt(
        identifier: 'apple_signin',
        success: false,
        metadata: {'error': e.toString()},
      );

      return AppleSignInResult.error('Sign-in failed: ${e.toString()}');
    }
  }

  /// Store Apple user data securely
  Future<void> _storeAppleUserData(
    AuthorizationCredentialAppleID credential,
    User firebaseUser,
  ) async {
    try {
      final userData = AppleUserData(
        appleId: credential.userIdentifier,
        email: credential.email ?? firebaseUser.email,
        fullName: _formatAppleName(credential.givenName, credential.familyName),
        authorizationCode: credential.authorizationCode,
        identityToken: credential.identityToken,
        state: credential.state,
        firebaseUid: firebaseUser.uid,
        createdAt: DateTime.now(),
        lastSignIn: DateTime.now(),
      );

      // Store user data
      await SecureStorage.writeSecureStorage(_appleUserKey, jsonEncode(userData.toJson()));

      // Store credential info (without sensitive data)
      final credentialInfo = {
        'apple_id': credential.userIdentifier,
        'email': credential.email ?? firebaseUser.email,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'firebase_uid': firebaseUser.uid,
      };
      
      await SecureStorage.writeSecureStorage(_appleCredentialKey, jsonEncode(credentialInfo));

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Store Apple user data failed');
    }
  }

  /// Format Apple name from given and family names
  String? _formatAppleName(String? givenName, String? familyName) {
    if (givenName == null && familyName == null) return null;
    if (givenName == null) return familyName;
    if (familyName == null) return givenName;
    return '$givenName $familyName';
  }

  /// Handle Apple Sign-In specific errors
  Future<void> _handleAppleSignInError(SignInWithAppleAuthorizationException error) async {
    await _security.recordAuthAttempt(
      identifier: 'apple_signin',
      success: false,
      metadata: {
        'error_code': error.code.toString(),
        'error_message': error.message,
      },
    );

    await _security.logSecurityEvent(
      SecurityEventType.authFailure,
      'Apple Sign-In error: ${error.code}',
      metadata: {
        'error_code': error.code.toString(),
        'error_message': error.message,
      },
    );

    // Track analytics
    AnalyticsHelper.trackUserAction('apple_signin_error', parameters: {
      'error_code': error.code.toString(),
      'error_message': error.message,
    });
  }

  /// Handle Firebase Auth errors
  Future<void> _handleFirebaseAuthError(FirebaseAuthException error) async {
    await _security.recordAuthAttempt(
      identifier: 'apple_signin',
      success: false,
      metadata: {
        'firebase_error_code': error.code,
        'firebase_error_message': error.message,
      },
    );

    await _security.logSecurityEvent(
      SecurityEventType.authFailure,
      'Firebase Auth error during Apple Sign-In: ${error.code}',
      metadata: {
        'firebase_error_code': error.code,
        'firebase_error_message': error.message,
      },
    );

    // Track analytics
    AnalyticsHelper.trackUserAction('apple_signin_firebase_error', parameters: {
      'error_code': error.code,
      'error_message': error.message,
    });
  }

  /// Get user-friendly Apple error message
  String _getAppleErrorMessage(SignInWithAppleAuthorizationException error) {
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        return 'Sign-in was canceled';
      case AuthorizationErrorCode.failed:
        return 'Sign-in failed. Please try again';
      case AuthorizationErrorCode.invalidResponse:
        return 'Invalid response from Apple. Please try again';
      case AuthorizationErrorCode.notHandled:
        return 'Sign-in not handled. Please try again';
      case AuthorizationErrorCode.unknown:
        return 'Unknown error occurred. Please try again';
      default:
        return 'Apple Sign-In failed. Please try again';
    }
  }

  /// Get user-friendly Firebase error message
  String _getFirebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again';
      case 'operation-not-allowed':
        return 'Apple Sign-In is not enabled. Please contact support';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support';
      case 'user-not-found':
        return 'No account found. Please sign up first';
      case 'wrong-password':
        return 'Incorrect password. Please try again';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  /// Get stored Apple user data
  Future<AppleUserData?> getAppleUserData() async {
    try {
      final userDataStr = await SecureStorage.readSecureStorage(_appleUserKey);
      if (userDataStr == null || userDataStr == 'ND') return null;

      final userData = AppleUserData.fromJson(jsonDecode(userDataStr));
      return userData;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get Apple user data failed');
      return null;
    }
  }

  /// Update last sign-in time
  Future<void> updateLastSignIn() async {
    try {
      final userData = await getAppleUserData();
      if (userData == null) return;

      userData.lastSignIn = DateTime.now();
      await SecureStorage.writeSecureStorage(_appleUserKey, jsonEncode(userData.toJson()));
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Update last sign-in failed');
    }
  }

  /// Link Apple account to existing Firebase user
  Future<AppleLinkResult> linkAppleAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return AppleLinkResult.error('No user signed in');
      }

      // Check if user already has Apple provider
      final providerData = currentUser.providerData;
      final hasAppleProvider = providerData.any((provider) => provider.providerId == 'apple.com');
      
      if (hasAppleProvider) {
        return AppleLinkResult.error('Apple account is already linked');
      }

      // Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      // Create OAuth credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Link credential to current user
      final userCredential = await currentUser.linkWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user == null) {
        return AppleLinkResult.error('Failed to link Apple account');
      }

      // Store Apple user data
      await _storeAppleUserData(appleCredential, user);

      // Log successful linking
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Apple account linked successfully',
        metadata: {
          'user_id': user.uid,
          'apple_id': appleCredential.userIdentifier,
        },
      );

      // Track analytics
      AnalyticsHelper.trackUserAction('apple_account_linked', parameters: {
        'user_id': user.uid,
        'apple_id': appleCredential.userIdentifier,
      });

      return AppleLinkResult.success(user, appleCredential);

    } on SignInWithAppleAuthorizationException catch (e) {
      await _handleAppleSignInError(e);
      return AppleLinkResult.error(_getAppleErrorMessage(e));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return AppleLinkResult.error('This Apple account is already linked to another user');
      } else if (e.code == 'email-already-in-use') {
        return AppleLinkResult.error('The email associated with this Apple account is already in use');
      }
      
      await _handleFirebaseAuthError(e);
      return AppleLinkResult.error(_getFirebaseErrorMessage(e));
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Link Apple account failed');
      return AppleLinkResult.error('Failed to link Apple account: ${e.toString()}');
    }
  }

  /// Unlink Apple account from current Firebase user
  Future<bool> unlinkAppleAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if user has Apple provider
      final providerData = currentUser.providerData;
      final hasAppleProvider = providerData.any((provider) => provider.providerId == 'apple.com');
      
      if (!hasAppleProvider) return false;

      // Unlink Apple provider
      await currentUser.unlink('apple.com');

      // Clear stored Apple user data
      await SecureStorage.deleteSecureStorage(_appleUserKey);
      await SecureStorage.deleteSecureStorage(_appleCredentialKey);

      // Log successful unlinking
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Apple account unlinked successfully',
        metadata: {
          'user_id': currentUser.uid,
        },
      );

      // Track analytics
      AnalyticsHelper.trackUserAction('apple_account_unlinked', parameters: {
        'user_id': currentUser.uid,
      });

      return true;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Unlink Apple account failed');
      return false;
    }
  }

  /// Revoke Apple authorization (iOS 13.4+)
  Future<bool> revokeAppleAuthorization() async {
    try {
      final userData = await getAppleUserData();
      if (userData?.authorizationCode == null) return false;

      // This would require server-side implementation to revoke the token
      // For now, we'll just clear local data
      await SecureStorage.deleteSecureStorage(_appleUserKey);
      await SecureStorage.deleteSecureStorage(_appleCredentialKey);

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Apple authorization revoked',
        metadata: {
          'apple_id': userData?.appleId,
        },
      );

      return true;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Revoke Apple authorization failed');
      return false;
    }
  }

  /// Clear Apple authentication data
  Future<void> clearAppleData() async {
    try {
      await SecureStorage.deleteSecureStorage(_appleUserKey);
      await SecureStorage.deleteSecureStorage(_appleCredentialKey);
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Clear Apple data failed');
    }
  }
}

/// Apple user data class
class AppleUserData {
  final String appleId;
  final String? email;
  final String? fullName;
  final String? authorizationCode;
  final String? identityToken;
  final String? state;
  final String firebaseUid;
  final DateTime createdAt;
  DateTime lastSignIn;

  AppleUserData({
    required this.appleId,
    this.email,
    this.fullName,
    this.authorizationCode,
    this.identityToken,
    this.state,
    required this.firebaseUid,
    required this.createdAt,
    required this.lastSignIn,
  });

  factory AppleUserData.fromJson(Map<String, dynamic> json) {
    return AppleUserData(
      appleId: json['apple_id'],
      email: json['email'],
      fullName: json['full_name'],
      authorizationCode: json['authorization_code'],
      identityToken: json['identity_token'],
      state: json['state'],
      firebaseUid: json['firebase_uid'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      lastSignIn: DateTime.fromMillisecondsSinceEpoch(json['last_sign_in']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apple_id': appleId,
      'email': email,
      'full_name': fullName,
      'authorization_code': authorizationCode,
      'identity_token': identityToken,
      'state': state,
      'firebase_uid': firebaseUid,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_sign_in': lastSignIn.millisecondsSinceEpoch,
    };
  }
}

/// Apple Sign-In result
class AppleSignInResult {
  final bool isSuccess;
  final User? user;
  final AuthorizationCredentialAppleID? appleCredential;
  final String? sessionToken;
  final bool isNewUser;
  final String? error;
  final Duration? rateLimitDuration;

  AppleSignInResult._({
    required this.isSuccess,
    this.user,
    this.appleCredential,
    this.sessionToken,
    this.isNewUser = false,
    this.error,
    this.rateLimitDuration,
  });

  factory AppleSignInResult.success({
    required User user,
    required AuthorizationCredentialAppleID appleCredential,
    required String sessionToken,
    required bool isNewUser,
  }) {
    return AppleSignInResult._(
      isSuccess: true,
      user: user,
      appleCredential: appleCredential,
      sessionToken: sessionToken,
      isNewUser: isNewUser,
    );
  }

  factory AppleSignInResult.error(String error) {
    return AppleSignInResult._(
      isSuccess: false,
      error: error,
    );
  }

  factory AppleSignInResult.rateLimited(Duration duration) {
    return AppleSignInResult._(
      isSuccess: false,
      error: 'Too many attempts. Please try again later.',
      rateLimitDuration: duration,
    );
  }
}

/// Apple link result
class AppleLinkResult {
  final bool isSuccess;
  final User? user;
  final AuthorizationCredentialAppleID? appleCredential;
  final String? error;

  AppleLinkResult._({
    required this.isSuccess,
    this.user,
    this.appleCredential,
    this.error,
  });

  factory AppleLinkResult.success(User user, AuthorizationCredentialAppleID credential) {
    return AppleLinkResult._(
      isSuccess: true,
      user: user,
      appleCredential: credential,
    );
  }

  factory AppleLinkResult.error(String error) {
    return AppleLinkResult._(
      isSuccess: false,
      error: error,
    );
  }
}