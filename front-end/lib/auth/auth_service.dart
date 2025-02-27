import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  successful,
  emailInUse,
  emailVerified,
  invalidEmail,
  weakPassword,
  unknown,
  invalidCredentials,
  phoneVerified,
  phoneVerificationFailed,
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if phone is verified
  Future<bool> isPhoneVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Reload user data to get the latest info
    await user.reload();
    
    // Check if phone number is linked
    final providerData = _auth.currentUser?.providerData;
    if (providerData == null) return false;
    
    // Check if the user has a phone provider
    return providerData.any((provider) => provider.providerId == 'phone');
  }

  // Sign in with email and password
  Future<AuthStatus> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthStatus.successful;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return AuthStatus.invalidCredentials;
      }
      return AuthStatus.unknown;
    } catch (e) {
      return AuthStatus.unknown;
    }
  }

  // Sign up with email and password
  Future<AuthStatus> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthStatus.successful;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return AuthStatus.emailInUse;
      } else if (e.code == 'invalid-email') {
        return AuthStatus.invalidEmail;
      } else if (e.code == 'weak-password') {
        return AuthStatus.weakPassword;
      }
      return AuthStatus.unknown;
    } catch (e) {
      return AuthStatus.unknown;
    }
  }

  // Sign in with Google
  Future<AuthStatus> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthStatus.unknown;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return AuthStatus.successful;
    } catch (e) {
      return AuthStatus.unknown;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Phone verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  // Verify phone code
  Future<AuthStatus> verifyPhoneCode(String verificationId, String smsCode) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // If user is already signed in, link the phone credential
      if (currentUser != null) {
        await currentUser!.linkWithCredential(credential);
      } else {
        // Otherwise sign in with the phone credential
        await _auth.signInWithCredential(credential);
      }
      
      return AuthStatus.phoneVerified;
    } catch (e) {
      return AuthStatus.phoneVerificationFailed;
    }
  }
}