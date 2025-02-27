import 'package:flutter/material.dart';
import '../theme_constants.dart'; // Import your theme file

// Custom text field widget
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: AppTheme.bodyStyle,
      decoration: AppTheme.textFieldDecoration(label, hint).copyWith(
        prefixIcon: prefixIcon,
      ),
      validator: validator,
    );
  }
}

// Custom button widget
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;
  final Widget? icon;

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonWidget = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: isSecondary ? AppTheme.accentColor : Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: AppTheme.buttonTextStyle.copyWith(
                  color: isSecondary ? AppTheme.accentColor : Colors.white,
                ),
              );

    if (isSecondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: AppTheme.secondaryButtonStyle,
        child: buttonWidget,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: AppTheme.primaryButtonStyle,
      child: buttonWidget,
    );
  }
}

// Custom card widget
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: AppTheme.cardDecoration,
      child: child,
    );
  }
}

// Social sign-in button
class SocialSignInButton extends StatelessWidget {
  final String label;
  final String logoAsset;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialSignInButton({
    Key? key,
    required this.label,
    required this.logoAsset,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black12),
        ),
        elevation: 1,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2.5,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  logoAsset,
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
    );
  }
}

// App title with logo
class AppTitle extends StatelessWidget {
  final double fontSize;

  const AppTitle({
    Key? key,
    this.fontSize = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "SARO",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.accentColor,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Secure",
          style: TextStyle(
            fontSize: fontSize * 0.6,
            fontWeight: FontWeight.w400,
            color: AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }
}

// Custom divider with text
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Colors.black26,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Colors.black26,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}