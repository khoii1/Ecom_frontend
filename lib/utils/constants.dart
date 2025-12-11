import 'package:flutter/material.dart';

// ============================================
// THEME COLORS - Modern E-commerce Theme
// ============================================

// Primary Colors - Gradient Tones
const Color kPrimaryColor = Color(0xFF6366F1);  // Indigo-500
const Color kPrimaryLight = Color(0xFF818CF8);  // Indigo-400
const Color kPrimaryDark = Color(0xFF4F46E5);   // Indigo-600

// Secondary/Accent Colors
const Color kAccentColor = Color(0xFFF59E0B);   // Amber-500
const Color kAccentLight = Color(0xFFFBBF24);   // Amber-400

// Background Colors
const Color kBackgroundColor = Color(0xFFF8FAFC);  // Slate-50
const Color kOffWhiteColor = Color(0xFFF1F5F9);    // Slate-100
const Color kCardColor = Colors.white;

// Text Colors
const Color kTextColor = Color(0xFF1E293B);         // Slate-800
const Color kSecondaryTextColor = Color(0xFF64748B); // Slate-500
const Color kLightTextColor = Color(0xFF94A3B8);     // Slate-400

// Status Colors
const Color kSuccessColor = Color(0xFF10B981);  // Emerald-500
const Color kErrorColor = Color(0xFFEF4444);    // Red-500
const Color kWarningColor = Color(0xFFF59E0B);  // Amber-500
const Color kInfoColor = Color(0xFF3B82F6);     // Blue-500

// Special Colors
const Color kHeartColor = Color(0xFFEC4899);    // Pink-500
const Color kStarColor = Color(0xFFFBBF24);     // Amber-400

// Legacy colors (for backward compatibility)
const Color kBrownLight = Color(0xFFBCAAA4);
const Color kBrownDark = Color(0xFF5D4037);
const Color kBrownPrimary = Color(0xFF8D6E63);

// ============================================
// SPACING & SIZING
// ============================================
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kMediumPadding = 12.0;
const double kLargePadding = 24.0;
const double kXLargePadding = 32.0;

const double kBorderRadius = 16.0;
const double kSmallBorderRadius = 8.0;
const double kMediumBorderRadius = 12.0;
const double kLargeBorderRadius = 24.0;

// ============================================
// SHADOWS
// ============================================
List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 12,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  ),
];

List<BoxShadow> kCardShadowHover = [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 16,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  ),
];

List<BoxShadow> kButtonShadow = [
  BoxShadow(
    color: kPrimaryColor.withOpacity(0.25),
    blurRadius: 8,
    spreadRadius: 0,
    offset: const Offset(0, 2),
  ),
];

List<BoxShadow> kElevatedShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  ),
];

// ============================================
// GRADIENTS
// ============================================
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [kPrimaryLight, kPrimaryDark],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kAccentGradient = LinearGradient(
  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kCardGradient = LinearGradient(
  colors: [Colors.white, Color(0xFFF8FAFC)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ============================================
// TEXT STYLES
// ============================================
const TextStyle kHeadingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kTextColor,
  letterSpacing: -0.5,
);

const TextStyle kSubheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const TextStyle kBodyStyle = TextStyle(
  fontSize: 14,
  color: kSecondaryTextColor,
  height: 1.5,
);

const TextStyle kPriceStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: kPrimaryColor,
);

const TextStyle kSmallTextStyle = TextStyle(
  fontSize: 12,
  color: kSecondaryTextColor,
  height: 1.4,
);

const TextStyle kMediumTextStyle = TextStyle(
  fontSize: 14,
  color: kTextColor,
  height: 1.5,
);

const TextStyle kLargeTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: kTextColor,
  height: 1.4,
);

// ============================================
// DECORATIONS
// ============================================
BoxDecoration kCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(kBorderRadius),
  boxShadow: kCardShadow,
);

InputDecoration kInputDecoration(String hint, {IconData? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kLightTextColor),
    prefixIcon: prefixIcon != null 
        ? Icon(prefixIcon, color: kSecondaryTextColor) 
        : null,
    filled: true,
    fillColor: kOffWhiteColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
    ),
  );
}
