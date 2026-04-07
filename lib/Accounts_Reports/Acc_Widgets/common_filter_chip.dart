import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';


class CommonFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  final Color? backgroundColor;

  const CommonFilterChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor ?? AppColors.veryLightGray,
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      deleteIconColor: AppColors.slate600,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }
}