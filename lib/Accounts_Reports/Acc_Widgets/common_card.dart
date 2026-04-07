import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CommonCard({
    super.key,
    required this.child,
    this.elevation = 2,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // ✅ full width
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12), // ✅ removed horizontal margin
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        color: backgroundColor ?? AppColors.white,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}