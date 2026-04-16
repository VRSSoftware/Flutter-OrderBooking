import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_widgets.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_filter_page.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/AccountReport_Services.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:path_provider/path_provider.dart';   

class DayBookPage extends StatefulWidget {
  const DayBookPage({super.key});

  @override
  State<DayBookPage> createState() => _DayBookPageState();
}

class _DayBookPageState extends State<DayBookPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  // Selected values for Day Book
  String selectedReportType = 'summary'; // 'summary' or 'detail'
  bool showNarration = false;
  bool showBillWise = false;

  // Loading states
  bool _isLoadingReport = false;

  // Validation error message
  String? _dateRangeError;

  // Get filter count
  int get _filterCount {
    int count = 0;
    if (selectedReportType != 'summary') count++;
    if (showNarration) count++;
    if (showBillWise) count++;
    return count;
  }

  bool get _hasFilters => _filterCount > 0;

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
    fromDateController.text = DateFormat('dd/MM/yyyy').format(now);
    toDateController.text = DateFormat('dd/MM/yyyy').format(now);
    _dateRangeError = null;
  }

  void _validateDateRange() {
    setState(() {
      if (fromDateController.text.isNotEmpty &&
          toDateController.text.isNotEmpty) {
        try {
          final fromDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(fromDateController.text);
          final toDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);

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
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
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
    final currentDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
    final previousDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - 1,
    );

    setState(() {
      fromDateController.text = DateFormat('dd/MM/yyyy').format(previousDate);
      _validateDateRange();
    });
  }

  void _nextFromDate() {
    final currentDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
    final nextDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    if (!nextDate.isAfter(DateTime.now())) {
      setState(() {
        fromDateController.text = DateFormat('dd/MM/yyyy').format(nextDate);
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
    final currentDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    final previousDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - 1,
    );

    setState(() {
      toDateController.text = DateFormat('dd/MM/yyyy').format(previousDate);
      _validateDateRange();
    });
  }

  void _nextToDate() {
    final currentDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    final nextDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    if (!nextDate.isAfter(DateTime.now())) {
      setState(() {
        toDateController.text = DateFormat('dd/MM/yyyy').format(nextDate);
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

  String? _validateFormDateRange() {
    if (fromDateController.text.isEmpty || toDateController.text.isEmpty) {
      return 'Please select both dates';
    }

    try {
      final fromDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
      final toDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);

      if (toDate.isBefore(fromDate)) {
        return 'To date cannot be before from date';
      }

      if (toDate.isAfter(DateTime.now())) {
        return 'To date cannot be in the future';
      }

      if (fromDate.isAfter(DateTime.now())) {
        return 'From date cannot be in the future';
      }
    } catch (e) {
      return 'Invalid date format';
    }

    return null;
  }

  Future<void> _openPdfDirectly(String pdfPath) async {
  try {
    final file = File(pdfPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF file not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await OpenFile.open(pdfPath);

    if (!mounted) return;

    if (result.type == ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening PDF...'),
          duration: Duration(seconds: 1),
        ),
      );
    } else if (result.type == ResultType.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No PDF viewer app found on your device'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint('Error opening PDF: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _viewReport() async {
  setState(() {
    _dateRangeError = null;
  });

  if (!_formKey.currentState!.validate()) return;

  final dateError = _validateFormDateRange();
  if (dateError != null) {
    setState(() {
      _dateRangeError = dateError;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(dateError), backgroundColor: Colors.red),
    );
    return;
  }

  setState(() => _isLoadingReport = true);

  try {
    // Determine report type based on showBillWise
    String reportType;
    if (showBillWise) {
      reportType = 'daybook_billWise';
    } else {
      reportType = 'daybook';
    }

    // Prepare additional parameters for Day Book
    final Map<String, dynamic> additionalParams = {
      "report_type": selectedReportType,
      "showNarration": showNarration,
    };

    // Use the common service to generate report
    final pdfBytes = await AccountReportService.generateDayBookReport(
      reportType: reportType,
      fromDate: fromDateController.text,
      toDate: toDateController.text,
      additionalParams: additionalParams,
    );

    if (mounted && pdfBytes != null) {
      final fileName =
          'DayBook_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = await AccountReportService.savePdfToTemp(
        pdfBytes,
        fileName,
      );

      // Directly open PDF without navigation
      await _openPdfDirectly(filePath);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoadingReport = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CommonAppBar(
        title: 'Day Book',
        showBackButton: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CommonFilterPage(
                            title: 'Day Book Filters',
                            reportType: 'DayBook',
                            initialReportType: selectedReportType,
                            initialShowNarration: showNarration,
                            initialShowBillWise: showBillWise,
                            onReportTypeChanged: (value) {
                              setState(() {
                                selectedReportType = value ?? 'summary';
                              });
                            },
                            onNarrationChanged: (value) {
                              setState(() {
                                showNarration = value ?? false;
                              });
                            },
                            onBillWiseChanged: (value) {
                              setState(() {
                                showBillWise = value ?? false;
                              });
                            },
                            onApply: () {
                              // Optional: show snackbar
                            },
                            onClear: () {
                              setState(() {
                                selectedReportType = 'summary';
                                showNarration = false;
                                showBillWise = false;
                              });
                            },
                          ),
                    ),
                  );
                },
              ),
              if (_hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_filterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Range Section
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
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
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        _dateRangeError != null &&
                                                _dateRangeError!.contains(
                                                  'From',
                                                )
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
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 40,
                                        ),
                                        splashRadius: 20,
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap:
                                            () =>
                                                _selectDate(fromDateController),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            fromDateController.text,
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
                                        constraints: BoxConstraints(
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
                        SizedBox(width: 16),
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
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        _dateRangeError != null &&
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
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 40,
                                        ),
                                        splashRadius: 20,
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap:
                                            () => _selectDate(toDateController),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            toDateController.text,
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
                                        constraints: BoxConstraints(
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              SizedBox(width: 8),
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
                ),
              ),

              SizedBox(height: 24),

              // View Report Button
              CommonButton(
                text: 'View Report',
                onPressed: _viewReport,
                isLoading: _isLoadingReport,
                icon: Icons.picture_as_pdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
