import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;
  final bool isRequired;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final String? hintText;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

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
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  void initState() {
    super.initState();
    // Add listener for focus changes
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    // Remove listener to prevent memory leaks
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus && widget.controller.text.isNotEmpty) {
      // Schedule selection after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: widget.controller.text.length,
          );
        }
      });
    }
  }

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
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (widget.isRequired)
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
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      widget.focusNode.hasFocus
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                  width: widget.focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                readOnly: widget.readOnly,
                keyboardType: widget.keyboardType,
                maxLines: widget.maxLines,
                onChanged: widget.onChanged,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: InputBorder.none,
                  hintText: widget.hintText ?? widget.label,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  suffixIcon:
                      widget.onTap != null
                          ? Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: Colors.grey.shade600,
                          )
                          : null,
                ),
                onTap: widget.onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
