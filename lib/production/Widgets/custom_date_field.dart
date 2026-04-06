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
  bool _hasContent = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    widget.focusNode.addListener(_onFocusChange);
    
    // Initialize from controller if exists
    if (widget.controller.text.isNotEmpty) {
      final parsedDate = _parseDate(widget.controller.text);
      if (parsedDate != null) {
        _currentDate = parsedDate;
        _hasContent = true;
      }
    } else {
      // Set today's date as default if controller is empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateDate(DateTime.now());
      });
    }
    
    widget.controller.addListener(_updateHasContent);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  void _updateHasContent() {
    final hasContent = widget.controller.text.isNotEmpty;
    if (_hasContent != hasContent) {
      setState(() {
        _hasContent = hasContent;
      });
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
    // Prevent updating if date is same
    if (_currentDate.year == newDate.year && 
        _currentDate.month == newDate.month && 
        _currentDate.day == newDate.day) {
      return;
    }
    
    setState(() {
      _currentDate = newDate;
      widget.controller.text = _formatDate(newDate);
      _hasContent = true;
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
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_updateHasContent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showLabel = _isFocused || _hasContent;
    final Color borderColor = _localErrorText != null || widget.errorText != null
        ? Colors.red.shade400
        : (_isFocused
            ? AppColors.primaryColor
            : (_hasContent ? AppColors.primaryColor.withOpacity(0.5) : Colors.grey.shade300));
    final double borderWidth = _localErrorText != null || widget.errorText != null
        ? 1.5
        : (_isFocused ? 1.5 : 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main content
                Row(
                  children: [
                    // Previous Date Arrow
                    InkWell(
                      onTap: _previousDate,
                      child: Container(
                        width: 36,
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          child: Text(
                            widget.controller.text.isEmpty 
                                ? '' 
                                : widget.controller.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                
                // Floating label
                if (showLabel)
                  Positioned(
                    left: 12,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      color: Colors.white,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _localErrorText != null || widget.errorText != null
                                  ? Colors.red.shade400
                                  : (_isFocused
                                      ? AppColors.primaryColor
                                      : (_hasContent
                                          ? AppColors.primaryColor.withOpacity(0.7)
                                          : Colors.grey.shade600)),
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
                  ),
                  
                // Placeholder text when no selection and label not shown
                if (!showLabel && widget.controller.text.isEmpty)
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_localErrorText != null || widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 12, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _localErrorText ?? widget.errorText!,
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