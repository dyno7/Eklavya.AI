import 'package:flutter/material.dart';

/// Corner radii tokens.
abstract class AppRadii {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(16));
  static const lg = BorderRadius.all(Radius.circular(24));
  static const xl = BorderRadius.all(Radius.circular(32));
  static const pill = BorderRadius.all(Radius.circular(40));
  static const circle = BorderRadius.all(Radius.circular(999));
}
