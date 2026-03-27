import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';

class PayableReport extends StatefulWidget {
  @override
  _PayableReportState createState() => _PayableReportState();
}

class _PayableReportState extends State<PayableReport> {
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

  @override
  void initState() {
    super.initState();
    _initializeDates();
    fetchCustomers();
  }

  void _initializeDates() {
    // Set default dates
    final now = DateTime.now();
    fromDateController.text = DateFormat('dd/MM/yyyy').format(now);
    toDateController.text = DateFormat('dd/MM/yyyy').format(now);
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
      lastDate: DateTime.now(), // Future dates disabled
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

        // Validate that to date is not before from date
        if (isFromDate && toDateController.text.isNotEmpty) {
          final fromDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(fromDateController.text);
          final toDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
          if (toDate.isBefore(fromDate)) {
            toDateController.text = fromDateController.text;
          }
        } else if (!isFromDate && fromDateController.text.isNotEmpty) {
          final fromDate = DateFormat(
            'dd/MM/yyyy',
          ).parse(fromDateController.text);
          final toDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
          if (toDate.isBefore(fromDate)) {
            fromDateController.text = toDateController.text;
          }
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
    fromDateController.text = DateFormat('dd/MM/yyyy').format(previousDate);

    // Update to date if needed
    final toDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    if (toDate.isBefore(previousDate)) {
      toDateController.text = fromDateController.text;
    }
    setState(() {});
  }

  void _nextFromDate() {
    final currentDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
    final nextDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    // Check if next date is not in future
    if (!nextDate.isAfter(DateTime.now())) {
      fromDateController.text = DateFormat('dd/MM/yyyy').format(nextDate);

      // Update to date if needed
      final toDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
      if (toDate.isBefore(nextDate)) {
        toDateController.text = fromDateController.text;
      }
      setState(() {});
    }
  }

  void _previousToDate() {
    final currentDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    final previousDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day - 1,
    );
    toDateController.text = DateFormat('dd/MM/yyyy').format(previousDate);

    // Validate from date is not after to date
    final fromDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
    if (fromDate.isAfter(previousDate)) {
      fromDateController.text = toDateController.text;
    }
    setState(() {});
  }

  void _nextToDate() {
    final currentDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    final nextDate = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + 1,
    );

    // Check if next date is not in future
    if (!nextDate.isAfter(DateTime.now())) {
      toDateController.text = DateFormat('dd/MM/yyyy').format(nextDate);

      // Validate from date is not after to date
      final fromDate = DateFormat('dd/MM/yyyy').parse(fromDateController.text);
      if (fromDate.isAfter(nextDate)) {
        fromDateController.text = toDateController.text;
      }
      setState(() {});
    }
  }

  String? _validateDateRange() {
    if (fromDateController.text.isEmpty || toDateController.text.isEmpty) {
      return 'Please select both dates';
    }

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

    return null;
  }

  Future<void> _viewReport() async {
    if (!_formKey.currentState!.validate()) return;

    final dateError = _validateDateRange();
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: Colors.red),
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
      // Format dates for API (YYYY-MM-DD)
      final fromDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yyyy').parse(fromDateController.text));
      final toDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yyyy').parse(toDateController.text));

      final data = {
        "coBrId": UserSession.coBrId ?? '',
        "ledgerKey": selectedCustomer?.key ?? '',
        "fromDate": fromDate,
        "toDate": toDate,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/GetPayableReport'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (mounted) {
        setState(() => _isLoadingReport = false);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          // Process and show report data
          _showReportDialog(responseData);
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

  void _showReportDialog(dynamic reportData) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Payable Report',
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
                    // Customer Details
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

                    // Report Data Display
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
    // Customize this based on your API response structure
    if (reportData == null) {
      return Center(child: Text('No data available'));
    }

    if (reportData is List && reportData.isEmpty) {
      return Center(child: Text('No transactions found for this period'));
    }

    // Example data display - adjust based on your actual API response
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
        title: const Text('Payable Report'),
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
              // Customer Dropdown
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

              // Date Range Selection
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

                      // From Date and To Date in same row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // From Date Section
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
                                      color: AppColors.slateBorder,
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
                                              () => _selectDate(
                                                fromDateController,
                                                true,
                                              ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              fromDateController.text,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize:
                                                    11, // Reduced font size
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
                          // To Date Section
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
                                      color: AppColors.slateBorder,
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
                                              () => _selectDate(
                                                toDateController,
                                                false,
                                              ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              toDateController.text,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize:
                                                    11, // Reduced font size
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // View Report Button
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
                child:
                    _isLoadingReport
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
