import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saro_app/auth/auth_service.dart';
import 'package:saro_app/auth/login_screen.dart';
import 'package:saro_app/auth/signup_screen.dart';
import 'package:saro_app/auth/phone_verification.dart';
import 'package:saro_app/home_screen.dart';
import 'package:saro_app/theme_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SARO Secure',
      theme: AppTheme.themeData,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/phone_verification': (context) => const PhoneVerificationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          
          if (user == null) {
            return const LoginScreen();
          }
          
          // Check if phone verification is completed
          return FutureBuilder<bool>(
            future: authService.isPhoneVerified(),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState == ConnectionState.done) {
                if (verificationSnapshot.data == true) {
                  return const HomeScreen();
                } else {
                  return const PhoneVerificationScreen();
                }
              }
              
              // Show loading while checking phone verification
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          );
        }
        
        // Show loading indicator while initializing
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}