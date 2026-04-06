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
  late FocusNode _internalFocusNode;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode;
    _internalFocusNode.addListener(_handleFocusChange);
    _hasContent = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateHasContent);
  }

  @override
  void dispose() {
    _internalFocusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_updateHasContent);
    super.dispose();
  }

  void _updateHasContent() {
    final hasContent = widget.controller.text.isNotEmpty;
    if (_hasContent != hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
    }
  }

  void _handleFocusChange() {
    if (_internalFocusNode.hasFocus && widget.controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.controller.text.isNotEmpty) {
          widget.controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: widget.controller.text.length,
          );
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _internalFocusNode.hasFocus;
    final bool showLabel = isFocused || _hasContent;
    final Color borderColor = isFocused
        ? AppColors.primaryColor
        : (_hasContent ? AppColors.primaryColor.withOpacity(0.5) : Colors.grey.shade300);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _internalFocusNode,
        readOnly: widget.readOnly,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        onChanged: (value) {
          _updateHasContent();
          if (widget.onChanged != null) {
            widget.onChanged!(value);
          }
        },
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          labelText: widget.isRequired ? '${widget.label} *' : widget.label,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isFocused
                ? AppColors.primaryColor
                : (_hasContent
                    ? AppColors.primaryColor.withOpacity(0.7)
                    : Colors.grey.shade600),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
          suffixIcon: widget.onTap != null
              ? Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Colors.grey.shade600,
                )
              : null,
        ),
        onTap: widget.onTap,
      ),
    );
  }
}