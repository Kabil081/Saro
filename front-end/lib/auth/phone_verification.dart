import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        onCodeSent: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
            _secondsRemaining = 60;
          });
          _startTimer();
        },
        onVerificationFailed: (String errorMessage) {
          setState(() {
            _isLoading = false;
            _errorMessage = errorMessage;
          });
        },
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
        
        if (status) {
          _navigateToHome();
        } else {
          setState(() {
            _errorMessage = "Failed to verify code. Please try again.";
          });
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
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
                  
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 8,
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 8,
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 8,
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App Title
                  Text(
                    "SARO Secure",
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 32,
                      color: AppTheme.accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    _codeSent ? "Enter Verification Code" : "Verify Your Phone",
                    style: AppTheme.headingStyle.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    _codeSent
                        ? "We have sent a verification code to ${_phoneController.text}"
                        : "We'll send a verification code to complete the 2-factor authentication",
                    style: AppTheme.bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!.replaceAll(RegExp(r'\[.*\]'), '').trim(),
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Phone Input Form
                  if (!_codeSent)
                    Form(
                      key: _phoneFormKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            hintText: "Phone Number (e.g. +1234567890)",
                            prefixIcon: Icons.phone_outlined,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
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
                            hintText: "Enter 6-digit code",
                            prefixIcon: Icons.security_outlined,
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            validator: _validateCode,
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
                            label: "Complete Verification",
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