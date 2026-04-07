import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';


class CommonDatePicker extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final Function(DateTime)? onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  const CommonDatePicker({
    super.key,
    required this.controller,
    required this.label,
    this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  @override
  State<CommonDatePicker> createState() => _CommonDatePickerState();
}

class _CommonDatePickerState extends State<CommonDatePicker> {
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    try {
      if (widget.controller.text.isNotEmpty) {
        initialDate = DateFormat('dd/MM/yyyy').parse(widget.controller.text);
      }
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime.now(),
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
        widget.controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.slate600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.enabled ? () => _selectDate(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.slateBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.controller.text.isEmpty
                      ? 'Select Date'
                      : widget.controller.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.controller.text.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}