import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

// Create a User class to match your application's user model
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  
  User({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
  });
  
  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }
}

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  
  // Convert Firebase User to our User model
  User? _userFromFirebase(firebase_auth.User? user) {
    if (user == null) {
      return null;
    }
    return User.fromFirebaseUser(user);
  }
  
  // Auth state changes stream
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }
  
  // Get current user
  User? get currentUser {
    return _userFromFirebase(_firebaseAuth.currentUser);
  }
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(credential.user);
    } catch (e) {
      rethrow;
    }
  }
  
  // Register with email and password
  Future<User?> createUserWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(displayName);
      
      // Refresh user to get updated info
      await credential.user?.reload();
      
      return _userFromFirebase(_firebaseAuth.currentUser);
    } catch (e) {
      rethrow;
    }
  }
  
  // Send phone verification code
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String errorMessage) onVerificationFailed,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
        // Auto-verification completed (not applicable for most cases)
        await _firebaseAuth.currentUser?.updatePhoneNumber(credential);
        await _setPhoneVerified(true);
      },
      verificationFailed: (firebase_auth.FirebaseAuthException e) {
        onVerificationFailed(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }
  
  // Verify phone with code
  Future<bool> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      firebase_auth.PhoneAuthCredential credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      await _firebaseAuth.currentUser?.updatePhoneNumber(credential);
      await _setPhoneVerified(true);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Check if phone is verified
  Future<bool> isPhoneVerified() async {
    // First check if the user has a phone number
    if (_firebaseAuth.currentUser?.phoneNumber != null) {
      return true;
    }
    
    // If not, check our local storage flag
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('phone_verified') ?? false;
  }
  
  // Set phone verified status in local storage
  Future<void> _setPhoneVerified(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('phone_verified', value);
  }
  
  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}