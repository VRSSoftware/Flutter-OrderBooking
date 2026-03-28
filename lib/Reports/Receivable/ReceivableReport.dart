import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class ReceivableReport extends StatefulWidget {
  @override
  _ReceivableReportState createState() => _ReceivableReportState();
}

class _ReceivableReportState extends State<ReceivableReport> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  // Selected values
  KeyName? selectedCustomer;

  // Lists
  List<KeyName> customers = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingReport = false;

  // Validation error message
  String? _dateRangeError;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    fetchCustomers();
  }

  void _initializeDates() {
    final now = DateTime.now();
    fromDateController.text = DateFormat('dd/MM/yyyy').format(now);
    toDateController.text = DateFormat('dd/MM/yyyy').format(now);
    _dateRangeError = null;
  }

  Future<void> fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.fetchLedgers(
        ledCat: 'W',
        coBrId: UserSession.coBrId ?? '',
      );

      if (mounted) {
        setState(() {
          customers = List<KeyName>.from(result['result']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load customers: $e')));
      }
    }
  }

  void _validateDateRange() {
    setState(() {
      if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
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
        
        if (_dateRangeError != null && _dateRangeError!.contains('To date cannot be before from date')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_dateRangeError!),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
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
          duration: Duration(seconds: 2),
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
      
      if (_dateRangeError != null && _dateRangeError!.contains('To date cannot be before from date')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_dateRangeError!),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
        
        if (_dateRangeError != null && _dateRangeError!.contains('To date cannot be before from date')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_dateRangeError!),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot select a future date'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
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
        SnackBar(
          content: Text(dateError),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoadingReport = true);

    try {
      final dateRange = "${fromDateController.text} to ${toDateController.text}";
      
      final data = {
        "date_range": dateRange,
        "ledKey": selectedCustomer?.key ?? '',
        "report": "recievable",
      };

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (mounted) {
        setState(() => _isLoadingReport = false);

        if (response.statusCode == 200) {
          final contentType = response.headers['content-type'];
          
          if (contentType != null && contentType.contains('application/pdf')) {
            await _saveAndViewPdf(response.bodyBytes);
          } else {
            final responseData = jsonDecode(response.body);
            _showReportDialog(responseData);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load report: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReport = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAndViewPdf(Uint8List pdfBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = 'Receivable_Report_${selectedCustomer?.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfPath: file.path,
            customerName: selectedCustomer?.name ?? '',
            fromDate: fromDateController.text,
            toDate: toDateController.text,
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog(dynamic reportData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Receivable Report',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Container(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.veryLightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer: ${selectedCustomer?.name ?? ''}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Period: ${fromDateController.text} to ${toDateController.text}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildReportData(reportData),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildReportData(dynamic reportData) {
    if (reportData == null) {
      return Center(child: Text('No data available'));
    }

    if (reportData is List && reportData.isEmpty) {
      return Center(child: Text('No transactions found for this period'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        if (reportData is List)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: reportData.length > 10 ? 10 : reportData.length,
            itemBuilder: (context, index) {
              final transaction = reportData[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${transaction['date'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                          Text(
                            'Amount: ${transaction['amount'] ?? 0}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (transaction['description'] != null)
                        Text(
                          transaction['description'],
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          Text(jsonEncode(reportData)),

        if (reportData is List && reportData.length > 10)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Showing 10 of ${reportData.length} records',
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        title: const Text('Receivable Report'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCustomerDropdown(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                                      color: _dateRangeError != null && _dateRangeError!.contains('From') 
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
                                          onTap: () => _selectDate(fromDateController, true),
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
                                      color: _dateRangeError != null && _dateRangeError!.contains('To') 
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
                                          onTap: () => _selectDate(toDateController, false),
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
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 16),
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
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoadingReport ? null : _viewReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoadingReport
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'View Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownSearch<KeyName>(
      items: customers,
      selectedItem: selectedCustomer,
      onChanged: (KeyName? value) {
        setState(() {
          selectedCustomer = value;
        });
      },
      enabled: !_isLoading,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search Customer",
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
        itemBuilder: (context, item, isSelected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(item.name, style: const TextStyle(fontSize: 14)),
          );
        },
        constraints: const BoxConstraints(maxHeight: 300),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: "Select Customer",
          hintText: "Choose a customer",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.slateBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          labelStyle: const TextStyle(color: AppColors.slate600, fontSize: 14),
        ),
      ),
      dropdownButtonProps: const DropdownButtonProps(
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
      ),
      dropdownBuilder: (context, selectedItem) {
        if (selectedItem == null) {
          return Text(
            "Select Customer",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          );
        }
        return Text(selectedItem.name, style: const TextStyle(fontSize: 14));
      },
      filterFn: (item, filter) {
        if (filter.isEmpty) return true;
        final searchTerm = filter.toLowerCase();
        return item.name.toLowerCase().contains(searchTerm) ||
            item.key.toLowerCase().contains(searchTerm);
      },
      compareFn: (item, selectedItem) => item.key == selectedItem?.key,
      validator: (value) {
        if (value == null) {
          return 'Please select a customer';
        }
        return null;
      },
    );
  }
}

// PDF Viewer Screen with corrected types
class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String customerName;
  final String fromDate;
  final String toDate;

  PdfViewerScreen({
    required this.pdfPath,
    required this.customerName,
    required this.fromDate,
    required this.toDate,
  });

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receivable Report - ${widget.customerName}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              _savePdfPermanently();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Period: ${widget.fromDate} to ${widget.toDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (!_isLoading)
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0; // Handle null by providing default value
                _isLoading = false;
              });
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = (page ?? 0) + 1;
                if (total != null) {
                  _totalPages = total;
                }
              });
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading PDF: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _savePdfPermanently() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to save PDF'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Receivable_Report_${widget.customerName}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final permanentFile = File('${directory.path}/$fileName');
      
      final tempFile = File(widget.pdfPath);
      await tempFile.copy(permanentFile.path);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved successfully to Documents'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}