import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _initialized = false;
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

  if (_initialized) return;

  final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  if (args != null) {
    ledgerList = List<KeyName>.from(args['ledgerList'] ?? widget.ledgerList);
    salespersonList =
        List<KeyName>.from(args['salespersonList'] ?? widget.salespersonList);

    selectedLedger = args['selectedLedger'];
    selectedSalesperson = args['selectedSalesperson'];
    selectedOrderStatus = args['selectedOrderStatus'];

    fromDate = args['fromDate'];
    toDate = args['toDate'];

    deliveryFromDate = args['deliveryFromDate'];
    deliveryToDate = args['deliveryToDate'];

    if (fromDate != null || toDate != null) {
      selectedDateRange = 'Custom';
    }
  } else {
    ledgerList = widget.ledgerList;
    salespersonList = widget.salespersonList;
  }

  _initialized = true;
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDeliveryDate) {
          if (isFromDate) {
            deliveryFromDate = picked;
            if (deliveryToDate != null && deliveryToDate!.isBefore(picked)) {
              deliveryToDate = picked;
            }
          } else {
            deliveryToDate = picked;
          }
        } else {
          if (isFromDate) {
            fromDate = picked;
            if (toDate != null && toDate!.isBefore(picked)) {
              toDate = picked;
            }
          } else {
            toDate = picked;
          }
        }
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

  Widget _buildExpansionTile({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = true,
      required bool active,
    ValueChanged<bool>? onExpansionChanged,
  }) {
    return CustomExpansionTile(
      title: title,
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
       active: active,
      children: children,
    );
  }

  Widget _buildDateInput(
    TextEditingController controller,
    String label,
    DateTime? date,
    VoidCallback onTap,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.primaryColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today, color: AppColors.primaryColor),
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.plusJakartaSans(),
    );
  }

  Widget filterWrapper({required Widget child, required bool active}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? AppColors.primaryColor : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),

        if (active)
          Positioned(
            right: 4,
            top: 4,
            child: Icon(
              Icons.check_circle,
              color: AppColors.primaryColor,
              size: 16,
            ),
          ),
      ],
    );
  }

  int _getFilterCount() {
    int count = 0;

    if (selectedLedger != null) count++;
    if (selectedSalesperson != null) count++;
    if (selectedOrderStatus != null && selectedOrderStatus != 'All') count++;
    if (fromDate != null) count++;
    if (toDate != null) count++;
    if (deliveryFromDate != null) count++;
    if (deliveryToDate != null) count++;

    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Register Filter',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey.shade50,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  children: [
                    _buildExpansionTile(
                      title: 'Date Range Filter',
                       active: fromDate != null ||
          toDate != null ||
          deliveryFromDate != null ||
          deliveryToDate != null,
                      initiallyExpanded: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              // Searchable Date Range Dropdown
                              DropdownSearch<String>(
                                items: dateRangeOptions,
                                selectedItem: selectedDateRange,
                                onChanged: (value) {
                                  setState(() {
                                    selectedDateRange = value;
                                    if (value != 'Custom')
                                      _setDateRange(value!);
                                  });
                                },
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchDelay: Duration(milliseconds: 300),
                                  menuProps: MenuProps(
                                    backgroundColor: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    elevation: 4,
                                  ),
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search date range...',
                                      hintStyle: GoogleFonts.plusJakartaSans(
                                        color: Colors.grey.shade400,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.grey.shade600,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Select Date Range',
                                    labelStyle: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey.shade600,
                                    ),
                                    floatingLabelStyle:
                                        GoogleFonts.plusJakartaSans(
                                          color: AppColors.primaryColor,
                                        ),
                                    prefixIcon: Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey.shade600,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColors.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                                dropdownBuilder: (context, selectedItem) {
                                  if (selectedItem == null) {
                                    return Text(
                                      'Select Date Range',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    );
                                  }
                                  return Container(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      selectedItem,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateInput(
                                      TextEditingController(
                                        text: _formatDate(fromDate),
                                      ),
                                      'From Date',
                                      fromDate,
                                      () => _pickDate(context, true, false),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDateInput(
                                      TextEditingController(
                                        text: _formatDate(toDate),
                                      ),
                                      'To Date',
                                      toDate,
                                      () => _pickDate(context, false, false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateInput(
                                      TextEditingController(
                                        text: _formatDate(deliveryFromDate),
                                      ),
                                      'Delivery From Date',
                                      deliveryFromDate,
                                      () => _pickDate(context, true, true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDateInput(
                                      TextEditingController(
                                        text: _formatDate(deliveryToDate),
                                      ),
                                      'Delivery To Date',
                                      deliveryToDate,
                                      () => _pickDate(context, false, true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    _buildExpansionTile(
                      title: 'Order Status',
                       active: selectedOrderStatus != null &&
          selectedOrderStatus != 'All',
                      initiallyExpanded: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: DropdownSearch<String>(
                            items: orderStatusOptions,
                            selectedItem: selectedOrderStatus,
                            onChanged: (value) {
                              debugPrint("Selected status value: $value");
                              setState(() => selectedOrderStatus = value);
                            },
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: Duration(milliseconds: 300),
                              menuProps: MenuProps(
                                backgroundColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 4,
                              ),
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search order status...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Order Status',
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade600,
                                ),
                                floatingLabelStyle: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryColor,
                                ),
                                prefixIcon: Icon(
                                  Icons.info_outline,
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            dropdownBuilder: (context, selectedItem) {
                              if (selectedItem == null) {
                                return Text(
                                  'Select Order Status',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                );
                              }
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  selectedItem,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    if (UserSession.userType != "C") ...[
                      const SizedBox(height: 5),
                      _buildExpansionTile(
                        title: 'Party',
                        active: selectedLedger != null,
                        initiallyExpanded: true,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: DropdownSearch<KeyName>(
                              items: ledgerList,
                              selectedItem: selectedLedger,
                              itemAsString: (KeyName? u) => u?.name ?? '',
                              onChanged:
                                  (value) =>
                                      setState(() => selectedLedger = value),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchDelay: Duration(milliseconds: 300),
                                menuProps: MenuProps(
                                  backgroundColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 4,
                                ),
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search party...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Select Party',
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600,
                                  ),
                                  floatingLabelStyle:
                                      GoogleFonts.plusJakartaSans(
                                        color: AppColors.primaryColor,
                                      ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              dropdownBuilder: (context, selectedItem) {
                                if (selectedItem == null) {
                                  return Text(
                                    'Select Party',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    selectedItem.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (UserSession.userType != "S") ...[
                      const SizedBox(height: 5),
                      _buildExpansionTile(
                        title: 'Salesperson',
                         active: selectedSalesperson != null,
                        initiallyExpanded: true,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: DropdownSearch<KeyName>(
                              items: salespersonList,
                              selectedItem: selectedSalesperson,
                              itemAsString: (KeyName? u) => u?.name ?? '',
                              onChanged:
                                  (value) => setState(
                                    () => selectedSalesperson = value,
                                  ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchDelay: Duration(milliseconds: 300),
                                menuProps: MenuProps(
                                  backgroundColor: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 4,
                                ),
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search salesperson...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade600,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: 'Select Salesperson',
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600,
                                  ),
                                  floatingLabelStyle:
                                      GoogleFonts.plusJakartaSans(
                                        color: AppColors.primaryColor,
                                      ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              dropdownBuilder: (context, selectedItem) {
                                if (selectedItem == null) {
                                  return Text(
                                    'Select Salesperson',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    selectedItem.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (fromDate != null &&
                                toDate != null &&
                                toDate!.isBefore(fromDate!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'To Date cannot be before From Date',
                                    style: GoogleFonts.plusJakartaSans(),
                                  ),
                                ),
                              );
                              return;
                            }
                            if (deliveryFromDate != null &&
                                deliveryToDate != null &&
                                deliveryToDate!.isBefore(deliveryFromDate!)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Delivery To Date cannot be before Delivery From Date',
                                    style: GoogleFonts.plusJakartaSans(),
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
                          child: Text(
                            'Apply Filters (${_getFilterCount()})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          child: Text(
                            'Clear Filters',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool active;
  final ValueChanged<bool>? onExpansionChanged;

  const CustomExpansionTile({
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.active = false,
    this.onExpansionChanged,
  });

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
   return Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      margin: const EdgeInsets.only(bottom: 6, top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        // thinner border
        border: Border.all(
          color: widget.active
              ? AppColors.primaryColor
              : Colors.grey.shade200,
          width: widget.active ? 0.8 : 0.5,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),

      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            widget.onExpansionChanged?.call(expanded);
          },
          children: widget.children,
        ),
      ),
    ),

    /// CHECK BADGE
    if (widget.active)
      Positioned(
        right: -4,   // push outside border
        top: -4,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
  ],
);
  }
}
