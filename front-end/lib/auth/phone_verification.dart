import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saro_app/auth/auth_service.dart';
import 'package:saro_app/home_screen.dart';
import 'package:saro_app/widgets/custom_widgets.dart';
import 'package:saro_app/theme_constants.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _auth = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _codeFormKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  String? _errorMessage;
  int _resendToken = 0;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Phone number validation
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+[0-9]{10,15}$').hasMatch(value)) {
      return 'Enter a valid phone number with country code (e.g. +1234567890)';
    }
    return null;
  }

  // OTP code validation
  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Verification code is required';
    }
    if (value.length < 6) {
      return 'Code must be 6 digits';
    }
    return null;
  }

  // Start phone verification process
  Future<void> _verifyPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Verify code entered by user
  Future<void> _verifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_verificationId != null) {
        final status = await _auth.verifyPhoneCode(
          _verificationId!,
          _codeController.text.trim(),
        );
        
        if (status == AuthStatus.phoneVerified) {
          _navigateToHome();
        }
      } else {
        throw Exception("Verification ID is null. Please try again.");
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

  // Callbacks for Firebase phone auth
  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.linkWithCredential(credential);
        _navigateToHome();
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

  void _onVerificationFailed(FirebaseAuthException exception) {
    setState(() {
      _isLoading = false;
      _errorMessage = exception.message;
    });
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    setState(() {
      _verificationId = verificationId;
      if (resendToken != null) {
        _resendToken = resendToken;
      }
      _codeSent = true;
      _isLoading = false;
      _secondsRemaining = 60;
    });
    
    _startTimer();
  }

  void _onCodeAutoRetrievalTimeout(String verificationId) {
    setState(() {
      _verificationId = verificationId;
    });
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                  const SizedBox(height: 40),
                  const AppTitle(),
                  const SizedBox(height: 20),
                  Text(
                    _codeSent ? "Enter Verification Code" : "Verify Your Phone Number",
                    style: AppTheme.subheadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _codeSent
                        ? "We have sent a verification code to ${_phoneController.text}"
                        : "We'll send a verification code to your phone to complete the 2-factor authentication.",
                    style: AppTheme.bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
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
                  
                  // Phone Input Form
                  if (!_codeSent)
                    Form(
                      key: _phoneFormKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: "Phone Number",
                            hint: "e.g. +1234567890",
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: "Send Verification Code",
                            onPressed: _verifyPhone,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  
                  // OTP Input Form
                  if (_codeSent)
                    Form(
                      key: _codeFormKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: "Verification Code",
                            hint: "Enter 6-digit code",
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            validator: _validateCode,
                            prefixIcon: const Icon(Icons.security_outlined),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_secondsRemaining > 0)
                                Text(
                                  "Resend code in $_secondsRemaining seconds",
                                  style: const TextStyle(
                                    color: AppTheme.secondaryColor,
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: _verifyPhone,
                                  child: const Text("Resend Code"),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: "Verify",
                            onPressed: _verifyCode,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}