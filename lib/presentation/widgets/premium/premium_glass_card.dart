import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.blur = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.55),
                Colors.black.withOpacity(0.30),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

