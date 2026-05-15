import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_widgets.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_filter_page.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/AccountReport_Services.dart';

class CustomerLedgerPage extends StatefulWidget {
  const CustomerLedgerPage({super.key});

  @override
  State<CustomerLedgerPage> createState() => _CustomerLedgerPageState();
}

class _CustomerLedgerPageState extends State<CustomerLedgerPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  // Selected values - OPTIONAL FILTERS
  List<KeyName> selectedStates = [];   // Optional - if empty, all states
  List<KeyName> selectedCities = [];   // Optional - if empty, all cities
  List<KeyName> selectedLedgers = [];  // Optional - if empty, all ledgers

  // Lists for dropdowns
  List<KeyName> states = [];
  List<KeyName> cities = [];
  List<KeyName> ledgers = [];

  // Loading states
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isLoadingLedgers = false;
  bool _isLoadingReport = false;

  // Validation error message
  String? _dateRangeError;

  int get _filterCount {
    int count = 0;
    if (selectedStates.isNotEmpty) count++;
    if (selectedCities.isNotEmpty) count++;
    if (selectedLedgers.isNotEmpty) count++;
    return count;
  }

  bool get _hasFilters => _filterCount > 0;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchDropdownData();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  void _initializeDates() {
    final now = DateTime.now();
     int fyYear = int.tryParse(UserSession.userFcYr ?? '') ?? now.year % 100;
   int fullYear = 2000 + fyYear;
   DateTime financialYearStart = DateTime(fullYear, 4, 1);
   fromDateController.text = DateFormat( 'dd/MM/yyyy',).format(financialYearStart);
    toDateController.text = DateFormat('dd/MM/yyyy').format(now);
    _dateRangeError = null;
  }

  Future<void> _fetchDropdownData() async {
    await Future.wait([
      fetchStates(),
      fetchCities(),
      fetchCustomerLedgers(),
    ]);
  }

  Future<void> fetchStates() async {
    setState(() => _isLoadingStates = true);
    try {
      final fetchedStates = await AccountReportService.fetchStates();
      if (mounted) {
        setState(() {
          states = fetchedStates;
          _isLoadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStates = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load states: $e')),
        );
      }
    }
  }

  Future<void> fetchCities() async {
    setState(() => _isLoadingCities = true);
    try {
      final fetchedCities = await AccountReportService.fetchCities();
      if (mounted) {
        setState(() {
          cities = fetchedCities;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: $e')),
        );
      }
    }
  }

  Future<void> fetchCustomerLedgers() async {
    setState(() => _isLoadingLedgers = true);
    try {
      final fetchedLedgers = await AccountReportService.fetchCustomerLedgers();
      if (mounted) {
        setState(() {
          ledgers = fetchedLedgers;
          _isLoadingLedgers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLedgers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load customer ledgers: $e')),
        );
      }
    }
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

  String _getSubtitle() {
    List<String> filters = [];
    
    if (selectedStates.isNotEmpty) {
      if (selectedStates.length == 1) {
        filters.add('State: ${selectedStates.first.name}');
      } else {
        filters.add('${selectedStates.length} States');
      }
    }
    
    if (selectedCities.isNotEmpty) {
      if (selectedCities.length == 1) {
        filters.add('City: ${selectedCities.first.name}');
      } else {
        filters.add('${selectedCities.length} Cities');
      }
    }
    
    if (selectedLedgers.isNotEmpty) {
      if (selectedLedgers.length == 1) {
        filters.add('Ledger: ${selectedLedgers.first.name}');
      } else {
        filters.add('${selectedLedgers.length} Ledgers');
      }
    }
    
    if (filters.isEmpty) {
      return 'All Customer Ledgers';
    }
    
    return filters.join(' • ');
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
    // Get all selected filter keys
    final stateKeys = selectedStates.map((e) => e.key).toList();
    final cityKeys = selectedCities.map((e) => e.key).toList();
    final ledgerKeys = selectedLedgers.map((e) => e.key).toList();

    final pdfBytes = await AccountReportService.generateCustomerLedgerReport(
      fromDate: fromDateController.text,
      toDate: toDateController.text,
      stateKeys: stateKeys,
      cityKeys: cityKeys,
      ledgerKeys: ledgerKeys,
    );

    if (mounted && pdfBytes != null) {
      final fileName = 'Customer_Ledger_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = await AccountReportService.savePdfToTemp(pdfBytes, fileName);

      if (mounted) {
        // Directly open PDF without navigation
        await _openPdfDirectly(filePath);
      }
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
        title: 'Customer Ledger',
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
                      builder: (context) => CommonFilterPage(
                        title: 'Customer Ledger Filters',
                        reportType: 'CustomerLedger',
                        states: states,
                        cities: cities,
                        ledgers: ledgers,
                        initialStates: selectedStates,
                        initialCities: selectedCities,
                        initialLedgers: selectedLedgers,
                        onStatesChanged: (value) {
                          setState(() {
                            selectedStates = value ?? [];
                          });
                        },
                        onCitiesChanged: (value) {
                          setState(() {
                            selectedCities = value ?? [];
                          });
                        },
                        onLedgersChanged: (value) {
                          setState(() {
                            selectedLedgers = value ?? [];
                          });
                        },
                        onApply: () {},
                        onClear: () {
                          setState(() {
                            selectedStates = [];
                            selectedCities = [];
                            selectedLedgers = [];
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
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Range Card
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

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 14,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}