import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saro_app/auth/auth_service.dart';
import 'package:saro_app/auth/signup_screen.dart';
import 'package:saro_app/auth/phone_verification.dart';
import 'package:saro_app/widgets/custom_widgets.dart';
import 'package:saro_app/theme_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
  
  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Login with email/password
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final status = await _auth.signInWithEmailAndPassword(
        _email.text.trim(),
        _password.text.trim(),
      );
      
      if (status == AuthStatus.emailVerified) {
        _navigateToPhoneVerification();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Google sign in
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    
    try {
      final status = await _auth.signInWithGoogle();
      
      if (status == AuthStatus.emailVerified) {
        _navigateToPhoneVerification();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }
  
  void _navigateToPhoneVerification() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PhoneVerificationScreen()),
    );
  }

  void _navigateToSignup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  const AppTitle(),
                  const SizedBox(height: 20),
                  const Text(
                    "Welcome back",
                    style: AppTheme.subheadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!.replaceAll(RegExp(r'\[.*\]'), '').trim(),
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: "Email",
                          hint: "Enter your email",
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: "Password",
                          hint: "Enter your password",
                          controller: _password,
                          isPassword: true,
                          validator: _validatePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ],
                    ),
                  ),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Implement forgot password functionality
                      },
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login button
                  CustomButton(
                    label: "Login",
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Divider
                  const DividerWithText(text: "OR"),
                  
                  const SizedBox(height: 24),
                  
                  // Google sign in button
                  SocialSignInButton(
                    label: "Continue with Google",
                    logoAsset: "assets/images/google_logo.png", // Add this to assets
                    onPressed: _signInWithGoogle,
                    isLoading: _isGoogleLoading,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: AppTheme.bodyStyle,
                      ),
                      GestureDetector(
                        onTap: _navigateToSignup,
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}