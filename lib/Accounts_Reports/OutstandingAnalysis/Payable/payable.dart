import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_widgets.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_filter_page.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/AccountReport_Services.dart';

class PayablePage extends StatefulWidget {
  const PayablePage({super.key});

  @override
  State<PayablePage> createState() => _PayablePageState();
}

class _PayablePageState extends State<PayablePage> {
  final _formKey = GlobalKey<FormState>();

  // Date Controllers
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  // Selected Filters
  List<KeyName> selectedLedgers = [];
  String selectedReportType = 'summary'; // 'summary' or 'detail'
  bool isOverdueOnly = false;
  bool isAgeWise = false;

  // Lists
  List<KeyName> ledgers = [];

  // Loading
  bool _isLoadingLedgers = false;
  bool _isLoadingReport = false;

  String? _dateRangeError;

  int get _filterCount {
    int count = 0;
    if (selectedLedgers.isNotEmpty) count++;
    if (selectedReportType != 'summary') count++;
    if (isOverdueOnly) count++;
    if (isAgeWise) count++;
    return count;
  }

  bool get _hasFilters => _filterCount > 0;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    fetchLedgers();
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
          final fromDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
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

  Future<void> fetchLedgers() async {
    setState(() => _isLoadingLedgers = true);
    try {
      final data = await AccountReportService.fetchPayablesLedgers();
      setState(() => ledgers = data);
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _isLoadingLedgers = false);
    }
  }

  void _showError(e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }

  String _getSubtitle() {
    List<String> parts = [];
    
    if (selectedLedgers.isNotEmpty) {
      parts.add('${selectedLedgers.length} Ledger(s)');
    }
    if (selectedReportType == 'detail') {
      parts.add('Detailed');
    }
    if (isOverdueOnly) {
      parts.add('Overdue Only');
    }
    if (isAgeWise) {
      parts.add('Age Wise');
    }
    
    if (parts.isEmpty) {
      return 'All Payables';
    }
    return parts.join(' • ');
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
    // Get all selected ledger keys
    final ledgerKeys = selectedLedgers.map((e) => e.key).toList();

    debugPrint('From Date: ${fromDateController.text}');
    debugPrint('To Date: ${toDateController.text}');
    debugPrint('Ledger Keys: $ledgerKeys');
    debugPrint('Report Type: $selectedReportType');
    debugPrint('Overdue Only: $isOverdueOnly');
    debugPrint('Age Wise: $isAgeWise');

    final pdfBytes = await AccountReportService.generatePayableReport(
      fromDate: fromDateController.text,
      toDate: toDateController.text,
      ledgerKeys: ledgerKeys,
      reportType: selectedReportType,
      isOverdueOnly: isOverdueOnly,
      isAgeWise: isAgeWise,
    );

    if (pdfBytes != null && mounted) {
      final path = await AccountReportService.savePdfToTemp(
        pdfBytes,
        'Payable_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      // Directly open PDF without navigation
      await _openPdfDirectly(path);
    }
  } catch (e) {
    _showError(e);
  } finally {
    setState(() => _isLoadingReport = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: CommonAppBar(
        title: 'Payable',
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
                      builder: (_) => CommonFilterPage(
                        title: 'Payable Filters',
                        reportType: 'Payable',
                        ledgers: ledgers,
                        initialLedgers: selectedLedgers,
                        initialReportType: selectedReportType,
                        initialShowOverdueOnly: isOverdueOnly,
                        initialShowAgeWise: isAgeWise,
                        onLedgersChanged: (v) => setState(() => selectedLedgers = v ?? []),
                        onReportTypeChanged: (v) => setState(() => selectedReportType = v ?? 'summary'),
                        onOverdueOnlyChanged: (v) => setState(() => isOverdueOnly = v ?? false),
                        onAgeWiseChanged: (v) => setState(() => isAgeWise = v ?? false),
                        onApply: () {},
                        onClear: () {
                          setState(() {
                            selectedLedgers = [];
                            selectedReportType = 'summary';
                            isOverdueOnly = false;
                            isAgeWise = false;
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
                    const SizedBox(height: 16),
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
                                    color: _dateRangeError != null
                                        ? Colors.red
                                        : AppColors.slateBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
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
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectDate(fromDateController),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 4,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              fromDateController.text,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
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
                                    color: _dateRangeError != null
                                        ? Colors.red
                                        : AppColors.slateBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
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
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _selectDate(toDateController),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 4,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              toDateController.text,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
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
                          padding: const EdgeInsets.symmetric(
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
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
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
                ),
              ),

              const SizedBox(height: 12),

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