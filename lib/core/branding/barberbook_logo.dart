import 'package:flutter/material.dart';

/// BarberBook mark: the official logo image.
class BarberBookLogo extends StatelessWidget {
  /// Creates the logo at [size]×[size] logical pixels.
  const BarberBookLogo({
    super.key,
    this.size = 96,
  });

  /// Shortest side of the square logo.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
