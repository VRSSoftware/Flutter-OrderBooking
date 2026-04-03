import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final bool isRequired;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final String? hintText;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.readOnly = false,
    this.isRequired = false,
    this.keyboardType,
    this.onTap,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 44, // Fixed height to match dropdown field
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focusNode.hasFocus ? AppColors.primaryColor : Colors.grey.shade300,
                  width: focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                readOnly: readOnly,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: InputBorder.none,
                  hintText: hintText ?? label,
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  suffixIcon: onTap != null
                      ? Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600)
                      : null,
                ),
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}