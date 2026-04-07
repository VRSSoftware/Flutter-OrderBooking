import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';


class CommonLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const CommonLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}