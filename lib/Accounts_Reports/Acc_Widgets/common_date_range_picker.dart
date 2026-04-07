import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CommonDateRangePicker extends StatefulWidget {
  final TextEditingController fromDateController;
  final TextEditingController toDateController;
  final Function(String?, String?)? onDateRangeChanged;
  final Function(String?)? onValidationError;

  const CommonDateRangePicker({
    super.key,
    required this.fromDateController,
    required this.toDateController,
    this.onDateRangeChanged,
    this.onValidationError,
  });

  @override
  State<CommonDateRangePicker> createState() => _CommonDateRangePickerState();
}

class _CommonDateRangePickerState extends State<CommonDateRangePicker> {
  String? _dateRangeError;

  void _validateDateRange() {
    setState(() {
      if (widget.fromDateController.text.isNotEmpty &&
          widget.toDateController.text.isNotEmpty) {
        try {
          final fromDate = DateFormat('dd/MM/yyyy')
              .parse(widget.fromDateController.text);
          final toDate = DateFormat('dd/MM/yyyy')
              .parse(widget.toDateController.text);

          if (toDate.isBefore(fromDate)) {
            _dateRangeError = 'To date cannot be before from date';
          } else if (toDate.isAfter(DateTime.now())) {
            _dateRangeError = 'To date cannot be in the future';
          } else if (fromDate.isAfter(DateTime.now())) {
            _dateRangeError = 'From date cannot be in the future';
          } else {
            _dateRangeError = null;
          }
        } catch (e) {
          _dateRangeError = 'Invalid date format';
        }
      } else {
        _dateRangeError = null;
      }

      if (widget.onDateRangeChanged != null) {
        widget.onDateRangeChanged!(
          widget.fromDateController.text,
          widget.toDateController.text,
        );
      }

      if (widget.onValidationError != null && _dateRangeError != null) {
        widget.onValidationError!(_dateRangeError);
      }
    });
  }

  Future<void> _selectDate(
    TextEditingController controller,
    bool isFromDate,
  ) async {
    DateTime initialDate = DateTime.now();
    try {
      if (controller.text.isNotEmpty) {
        initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
      }
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
        _validateDateRange();
      });
    }
  }

  void _previousFromDate() {
    final currentDate = DateFormat('dd/MM/yyyy')
        .parse(widget.fromDateController.text);
    final previousDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - 1,
    );

    setState(() {
      widget.fromDateController.text =
          DateFormat('dd/MM/yyyy').format(previousDate);
      _validateDateRange();
    });
  }

  void _nextFromDate() {
    final currentDate = DateFormat('dd/MM/yyyy')
        .parse(widget.fromDateController.text);
    final nextDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    if (!nextDate.isAfter(DateTime.now())) {
      setState(() {
        widget.fromDateController.text =
            DateFormat('dd/MM/yyyy').format(nextDate);
        _validateDateRange();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select a future date'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousToDate() {
    final currentDate = DateFormat('dd/MM/yyyy')
        .parse(widget.toDateController.text);
    final previousDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - 1,
    );

    setState(() {
      widget.toDateController.text =
          DateFormat('dd/MM/yyyy').format(previousDate);
      _validateDateRange();
    });
  }

  void _nextToDate() {
    final currentDate =
        DateFormat('dd/MM/yyyy').parse(widget.toDateController.text);
    final nextDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    if (!nextDate.isAfter(DateTime.now())) {
      setState(() {
        widget.toDateController.text =
            DateFormat('dd/MM/yyyy').format(nextDate);
        _validateDateRange();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select a future date'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();
    widget.fromDateController.text = DateFormat('dd/MM/yyyy').format(now);
    widget.toDateController.text = DateFormat('dd/MM/yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _dateRangeError != null &&
                                _dateRangeError!.contains('From')
                            ? Colors.red
                            : AppColors.slateBorder,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            onPressed: _previousFromDate,
                            icon: Icon(
                              Icons.chevron_left,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 40,
                            ),
                            splashRadius: 20,
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _selectDate(widget.fromDateController, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              child: Text(
                                widget.fromDateController.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            onPressed: _nextFromDate,
                            icon: Icon(
                              Icons.chevron_right,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 40,
                            ),
                            splashRadius: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _dateRangeError != null &&
                                _dateRangeError!.contains('To')
                            ? Colors.red
                            : AppColors.slateBorder,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            onPressed: _previousToDate,
                            icon: Icon(
                              Icons.chevron_left,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 40,
                            ),
                            splashRadius: 20,
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _selectDate(widget.toDateController, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              child: Text(
                                widget.toDateController.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: IconButton(
                            onPressed: _nextToDate,
                            icon: Icon(
                              Icons.chevron_right,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 40,
                            ),
                            splashRadius: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_dateRangeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateRangeError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}