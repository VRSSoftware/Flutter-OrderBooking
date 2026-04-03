import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CustomDateField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isRequired;
  final String? errorText;
  final DateTime? minDate;
  final DateTime? maxDate;
  final DateTime? fromDate; // For validation: date cannot be before this
  final DateTime? toDate;   // For validation: date cannot be after this
  final Function(DateTime)? onDateChanged;
  final Function(String?)? onValidationError;

  const CustomDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.isRequired = false,
    this.errorText,
    this.minDate,
    this.maxDate,
    this.fromDate,
    this.toDate,
    this.onDateChanged,
    this.onValidationError,
  });

  @override
  State<CustomDateField> createState() => _CustomDateFieldState();
}

class _CustomDateFieldState extends State<CustomDateField> {
  late DateTime _currentDate;
  String? _localErrorText;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    // Initialize from controller if exists
    if (widget.controller.text.isNotEmpty) {
      final parsedDate = _parseDate(widget.controller.text);
      if (parsedDate != null) {
        _currentDate = parsedDate;
      }
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _validateDate(DateTime date) {
    String? error;
    
    // Check min date
    if (widget.minDate != null && date.isBefore(widget.minDate!)) {
      error = 'Date cannot be before ${_formatDate(widget.minDate!)}';
    }
    // Check max date
    else if (widget.maxDate != null && date.isAfter(widget.maxDate!)) {
      error = 'Date cannot be after ${_formatDate(widget.maxDate!)}';
    }
    // Check from date (date should be after or equal to from date)
    else if (widget.fromDate != null && date.isBefore(widget.fromDate!)) {
      error = '${widget.label} cannot be before ${_formatDate(widget.fromDate!)}';
    }
    // Check to date (date should be before or equal to to date)
    else if (widget.toDate != null && date.isAfter(widget.toDate!)) {
      error = '${widget.label} cannot be after ${_formatDate(widget.toDate!)}';
    }
    
    setState(() {
      _localErrorText = error;
    });
    
    widget.onValidationError?.call(error);
    
    if (error == null) {
      widget.onDateChanged?.call(date);
    }
  }

  void _updateDate(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
      widget.controller.text = _formatDate(newDate);
    });
    _validateDate(newDate);
  }

  void _previousDate() {
    final newDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day - 1);
    _updateDate(newDate);
  }

  void _nextDate() {
    final newDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day + 1);
    _updateDate(newDate);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: widget.minDate ?? DateTime(2000),
      lastDate: widget.maxDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      _updateDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayError = widget.errorText ?? _localErrorText;
    
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
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: displayError != null
                    ? Colors.red.shade400
                    : widget.focusNode.hasFocus
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                width: displayError != null ? 1.5 : (widget.focusNode.hasFocus ? 2 : 1),
              ),
            ),
            child: Row(
              children: [
                // Previous Date Arrow
                InkWell(
                  onTap: _previousDate,
                  child: Container(
                    width: 36,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                // Date Display (Clickable)
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.controller.text.isEmpty 
                            ? 'Select' 
                            : widget.controller.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.controller.text.isEmpty 
                              ? Colors.grey.shade500 
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                // Next Date Arrow
                InkWell(
                  onTap: _nextDate,
                  child: Container(
                    width: 36,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (displayError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 12, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      displayError,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}