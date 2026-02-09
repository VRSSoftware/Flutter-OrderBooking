import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';

class RegisterFilterPage extends StatefulWidget {
  final List<KeyName> ledgerList;
  final List<KeyName> salespersonList;
  final Function({
    KeyName? selectedLedger,
    KeyName? selectedSalesperson,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? deliveryFromDate,
    DateTime? deliveryToDate,
    String? selectedOrderStatus,
    String? selectedDateRange,
  })
  onApplyFilters;

  const RegisterFilterPage({
    Key? key,
    required this.ledgerList,
    required this.salespersonList,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<RegisterFilterPage> createState() => _RegisterFilterPageState();
}

class _RegisterFilterPageState extends State<RegisterFilterPage> {
  List<KeyName> ledgerList = [];
  List<KeyName> salespersonList = [];

  KeyName? selectedLedger;
  KeyName? selectedSalesperson;

  String? selectedOrderStatus;
  DateTime? fromDate;
  DateTime? toDate;
  DateTime? deliveryFromDate;
  DateTime? deliveryToDate;
  String? selectedDateRange;

  final List<String> dateRangeOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'Last Week',
    'This Month',
    'Last Month',
    'Custom',
  ];

  final List<String> orderStatusOptions = [
    'All',
    'Draft',
    'Approved',
    'Dispatched',
    'Cancelled',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      ledgerList = List<KeyName>.from(args['ledgerList'] ?? widget.ledgerList);
      salespersonList = List<KeyName>.from(
        args['salespersonList'] ?? widget.salespersonList,
      );
    } else {
      ledgerList = widget.ledgerList;
      salespersonList = widget.salespersonList;
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    bool isFromDate,
    bool isDeliveryDate,
  ) async {
    final initialDate = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate
              ? (isDeliveryDate
                  ? deliveryFromDate ?? initialDate
                  : fromDate ?? initialDate)
              : (isDeliveryDate
                  ? deliveryToDate ?? initialDate
                  : toDate ?? initialDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isDeliveryDate) {
          if (isFromDate) {
            deliveryFromDate = picked;
            // Ensure deliveryToDate is not before deliveryFromDate
            if (deliveryToDate != null && deliveryToDate!.isBefore(picked)) {
              deliveryToDate = picked;
            }
          } else {
            deliveryToDate = picked;
          }
        } else {
          if (isFromDate) {
            fromDate = picked;
            // Ensure toDate is not before fromDate
            if (toDate != null && toDate!.isBefore(picked)) {
              toDate = picked;
            }
          } else {
            toDate = picked;
          }
        }
        // If a date is manually picked, set range to Custom
        selectedDateRange = 'Custom';
      });
    }
  }

  void _setDateRange(String range) {
    final now = DateTime.now();
    DateTime start, end;
    switch (range) {
      case 'Today':
        start = end = now;
        break;
      case 'Yesterday':
        start = end = now.subtract(Duration(days: 1));
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(Duration(days: 6));
        break;
      case 'Last Week':
        end = now.subtract(Duration(days: now.weekday));
        start = end.subtract(Duration(days: 6));
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      default:
        return;
    }
    setState(() {
      fromDate = start;
      toDate = end;
      selectedDateRange = range;
    });
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd-MM-yyyy').format(date) : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       title: Text('Register Filter', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ), // <-- back icon color
        titleTextStyle: const TextStyle(
          color: Colors.white, // <-- title text color
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      body: Container(
        color: Colors.white, // Set entire body background to white
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Date Range ---
              _buildExpansionTile(
                title: 'Date Range Filter',
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Date Range',
                    ),
                    dropdownColor: Colors.white,
                    value: selectedDateRange,
                    items:
                        dateRangeOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDateRange = value;
                        if (value != 'Custom') _setDateRange(value!);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'From Date',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _formatDate(fromDate),
                          ),
                          onTap: () => _pickDate(context, true, false),
                        ),
                      ),

                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'To Date',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _formatDate(toDate),
                          ),
                          onTap: () => _pickDate(context, false, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Delivery From Date',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _formatDate(deliveryFromDate),
                          ),
                          onTap: () => _pickDate(context, true, true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Delivery To Date',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _formatDate(deliveryToDate),
                          ),
                          onTap: () => _pickDate(context, false, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // --- Order Status ---
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Order Status',
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Order Status',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    dropdownColor: Colors.white, // Menu background
                    value:
                        orderStatusOptions.contains(selectedOrderStatus)
                            ? selectedOrderStatus
                            : null,
                    items:
                        orderStatusOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) {
                      debugPrint("Selected status value: $value");
                      setState(() => selectedOrderStatus = value);
                    },
                    hint: const Text('Select Order Status'),
                  ),
                ],
              ),

              // --- Party ---
              if (UserSession.userType != "C") ...[
                const SizedBox(height: 10),
                _buildExpansionTile(
                  title: 'Party',
                  children: [
                    DropdownSearch<KeyName>(
                      items: ledgerList,
                      selectedItem: selectedLedger,
                      itemAsString: (KeyName? u) => u?.name ?? '',
                      onChanged:
                          (value) => setState(() => selectedLedger = value),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        containerBuilder:
                            (context, popupWidget) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white, // Menu background
                                borderRadius: BorderRadius.circular(0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: popupWidget,
                            ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select Party',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // --- Salesperson ---
              if (UserSession.userType != "S") ...[
                const SizedBox(height: 10),
                _buildExpansionTile(
                  title: 'Salesperson',
                  children: [
                    DropdownSearch<KeyName>(
                      items: salespersonList,
                      selectedItem: selectedSalesperson,
                      itemAsString: (KeyName? u) => u?.name ?? '',
                      onChanged:
                          (value) =>
                              setState(() => selectedSalesperson = value),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        containerBuilder:
                            (context, popupWidget) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white, // Menu background
                                borderRadius: BorderRadius.circular(0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: popupWidget,
                            ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select Salesperson',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // --- Buttons ---
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (fromDate != null &&
                            toDate != null &&
                            toDate!.isBefore(fromDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'To Date cannot be before From Date',
                              ),
                            ),
                          );
                          return;
                        }
                        if (deliveryFromDate != null &&
                            deliveryToDate != null &&
                            deliveryToDate!.isBefore(deliveryFromDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Delivery To Date cannot be before Delivery From Date',
                              ),
                            ),
                          );
                          return;
                        }

                        widget.onApplyFilters(
                          selectedLedger: selectedLedger,
                          selectedSalesperson: selectedSalesperson,
                          fromDate: fromDate,
                          toDate: toDate,
                          deliveryFromDate: deliveryFromDate,
                          deliveryToDate: deliveryToDate,
                          selectedOrderStatus: selectedOrderStatus,
                          selectedDateRange: selectedDateRange,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLedger = null;
                          selectedSalesperson = null;
                          fromDate = null;
                          toDate = null;
                          deliveryFromDate = null;
                          deliveryToDate = null;
                          selectedOrderStatus = null;
                          selectedDateRange = 'Custom';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Clear Filters',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.all(16),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: children,
        ),
      ),
    );
  }
}
