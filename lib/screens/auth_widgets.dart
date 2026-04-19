import 'package:flutter/material.dart';

// App colors
class AppColors {
  static const Color pink = Color(0xFFFF6B8A);
  static const Color blue = Color(0xFF5BA8E0);
  static const Color background = Color(0xFFF5F7FA);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE8ECF0);
  static const Color inputIconBg = Color(0xFFF0F4F8);
}

// Top bar with back arrow & menu
class AuthTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const AuthTopBar({super.key, this.onBack, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back, color: AppColors.darkText, size: 24),
          ),
          if (onMenu != null)
            GestureDetector(
              onTap: onMenu,
              child: const Icon(Icons.menu, color: AppColors.darkText, size: 24),
            )
          else
            const SizedBox(width: 24),
        ],
      ),
    );
  }
}

// DonorNET logo (blood drops + text)
class DonorNetLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const DonorNetLogo({
    super.key,
    this.iconSize = 80,
    this.fontSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    final smallSize = iconSize * 0.56;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize * 1.5,
          height: iconSize * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Small drop — top-left
              Positioned(
                top: 0,
                left: iconSize * 0.25,
                child: Icon(
                  Icons.water_drop,
                  size: smallSize,
                  color: AppColors.pink.withValues(alpha: 0.7),
                ),
              ),
              // Small drop — top-right
              Positioned(
                top: 0,
                right: iconSize * 0.25,
                child: Icon(
                  Icons.water_drop,
                  size: smallSize,
                  color: AppColors.pink.withValues(alpha: 0.7),
                ),
              ),
              // Large drop — center bottom
              Positioned(
                bottom: 0,
                child: Icon(
                  Icons.water_drop,
                  size: iconSize,
                  color: AppColors.pink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DonorNET',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.pink,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// Styled text input field
class AuthInputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const AuthInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 72,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.inputBorder, width: 1),
              ),
            ),
            child: Center(
              child: Icon(icon, color: AppColors.pink.withValues(alpha: 0.6), size: 22),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.darkText,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: AppColors.greyText.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.only(top: 2, bottom: 4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Primary filled button (blue) ��─
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Text(text),
      ),
    );
  }
}

// Outlined button (for Sign Up on landing)
class OutlinedActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const OutlinedActionButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.blue, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        child: Text(text),
      ),
    );
  }
}
