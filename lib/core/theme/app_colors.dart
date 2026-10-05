import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const navy = Color(
    0xFF102A43,
  ); // logo, header, navigation, important text
  static const coral = Color(
    0xFFF26B5E,
  ); // create, like, save, make-it-mine, active buttons
  static const sand = Color(
    0xFFF4E7D3,
  ); // trip cards, itinerary sections, empty states
  static const offWhite = Color(0xFFFAF9F6); // main background
  static const charcoal = Color(0xFF17202A); // body text
  static const success = Color(0xFF3E8E68);

  // Text on a coral button. White looks right but is ~3:1 contrast;
  // set this to navy for ~4.9:1 if you want it fully AA.
  static const onCoral = Colors.white;

  // Derived (not in your palette)
  static const mist = Color(0xFF5F6B76); // secondary text
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(
    0xFFDC2626,
  ); // kept distinct from coral on purpose
  static const darkBackground = Color(0xFF0B1E30); // dark mode surface
}
