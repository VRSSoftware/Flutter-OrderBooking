import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/data.dart';
import 'package:vrs_erp/models/keyName.dart';

class DashboardFilterPage extends StatefulWidget {
  final List<KeyName> ledgerList;
  final List<KeyName> salespersonList;
  final Function({
    KeyName? selectedLedger,
    KeyName? selectedSalesperson,
    DateTime? fromDate,
    DateTime? toDate,
    KeyName? selectedState,
    KeyName? selectedCity,
  })
  onApplyFilters;

  const DashboardFilterPage({
    Key? key,
    required this.ledgerList,
    required this.salespersonList,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<DashboardFilterPage> createState() => _DashboardFilterPageState();
}

class _DashboardFilterPageState extends State<DashboardFilterPage> {
  List<KeyName> ledgerList = [];
  List<KeyName> salespersonList = [];
  List<KeyName> statesList = [];
  List<KeyName> citiesList = [];

  List<KeyName> selectedsalespersons = [];
  List<KeyName> selectedLedgers = [];
  List<KeyName> selectedStates = [];
  List<KeyName> selectedCities = [];

  KeyName? selectedLedger;
  KeyName? selectedSalesperson;
  KeyName? selectedState;
  KeyName? selectedCity;
  // String? selectedState;
  String? selectedOrderStatus;
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedDateRange;

  final List<String> dateRangeOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'Previous Week',
    'This Month',
    'Previous Month',
    'This Quarter',
    'Previous Quarter',
    'This Year',
    'Previous Year',
    'Custom',
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
      statesList = List<KeyName>.from(args['statesList']);
      citiesList = List<KeyName>.from(args['citiesList']);
      // fromDate = args['fromDate'] as DateTime?;
      // toDate = args['toDate'] as DateTime?;
      //selectedLedger = args['selectedLedger'] as KeyName?;
      //selectedSalesperson = args['selectedSalesperson'] as KeyName?;
      //selectedDateRange = args['selectedDateRange'] as String? ?? 'Custom';
    } else {
      // ledgerList = widget.ledgerList;
      // salespersonList = widget.salespersonList;
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      selectedsalespersons = FilterData.selectedSalespersons ?? [];
      selectedCities = FilterData.selectedCities ?? [];
      selectedStates = FilterData.selectedStates ?? [];
      selectedLedgers = FilterData.selectedLedgers ?? [];
      selectedDateRange = FilterData.selectedDateRange;
      toDate = FilterData.toDate;
      fromDate = FilterData.fromDate;
    });
  }

  void _setDateRange(String range) {
    final now = DateTime.now();
    DateTime start, end;
    switch (range) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        break;
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Previous Week':
        final firstDayOfLastWeek = now.subtract(
          Duration(days: now.weekday + 6),
        );
        start = DateTime(
          firstDayOfLastWeek.year,
          firstDayOfLastWeek.month,
          firstDayOfLastWeek.day,
        );
        end = DateTime(
          firstDayOfLastWeek.year,
          firstDayOfLastWeek.month,
          firstDayOfLastWeek.day + 6,
          23,
          59,
          59,
        );
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'Previous Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'This Quarter':
        final quarter = (now.month - 1) ~/ 3;
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = DateTime(now.year, quarter * 3 + 4, 0, 23, 59, 59);
        break;
      case 'Previous Quarter':
        final quarter = (now.month - 1) ~/ 3;
        final prevQuarter = quarter == 0 ? 3 : quarter - 1;
        final prevQuarterYear = quarter == 0 ? now.year - 1 : now.year;
        start = DateTime(prevQuarterYear, prevQuarter * 3 + 1, 1);
        end = DateTime(prevQuarterYear, prevQuarter * 3 + 4, 0, 23, 59, 59);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'Previous Year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        break;
      default:
        return;
    }
    setState(() {
      fromDate = start;
      toDate = end;
      selectedDateRange = range;
    });
    FilterData.selectedDateRange = selectedDateRange;
    FilterData.fromDate = fromDate;
    FilterData.toDate = toDate;
  }

  Future<void> _pickDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? fromDate ?? DateTime.now() : toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
        selectedDateRange = 'Custom';
      });
    }
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd-MM-yyyy').format(date) : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Dashboard'),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Filter
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _formatDate(fromDate),
                          ),
                          onTap: () => _pickDate(context, true),
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
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          controller: TextEditingController(
                            text: _formatDate(toDate),
                          ),
                          onTap: () => _pickDate(context, false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Party Filter
              if (UserSession.userType != "C") ...[
                const SizedBox(height: 10),
                _buildExpansionTile(
                  title: 'Party',
                  children: [
                    DropdownSearch<KeyName>.multiSelection(
                      items: ledgerList,
                      selectedItems: selectedLedgers,
                      itemAsString: (KeyName? u) => u?.name ?? '',
                      onChanged:
                          (value) => setState(() => selectedLedgers = value),
                      popupProps: PopupPropsMultiSelection.menu(
                        showSearchBox: true,
                        containerBuilder:
                            (context, popupWidget) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Salesperson Filter
              if (UserSession.userType != "S") ...[
                const SizedBox(height: 10),
                _buildExpansionTile(
                  title: 'Salesperson',
                  children: [
                    DropdownSearch<KeyName>.multiSelection(
                      items: salespersonList,
                      selectedItems: selectedsalespersons,
                      itemAsString: (KeyName? u) => u?.name ?? '',
                      onChanged:
                          (value) =>
                              setState(() => selectedsalespersons = value),
                      popupProps: PopupPropsMultiSelection.menu(
                        showSearchBox: true,
                        containerBuilder:
                            (context, popupWidget) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: popupWidget,
                            ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select Sales Persons',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // State Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'State',
                children: [
                  DropdownSearch<KeyName>.multiSelection(
                    items: statesList,
                    selectedItems: selectedStates,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged:
                        (value) => setState(() => selectedStates = value),
                    popupProps: PopupPropsMultiSelection.menu(
                      showSearchBox: true,
                      containerBuilder:
                          (context, popupWidget) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: popupWidget,
                          ),
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Select States',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // City Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'City',
                children: [
                  DropdownSearch<KeyName>.multiSelection(
                    items: citiesList,
                    selectedItems: selectedCities,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged:
                        (value) => setState(() => selectedCities = value),
                    popupProps: PopupPropsMultiSelection.menu(
                      showSearchBox: true,
                      containerBuilder:
                          (context, popupWidget) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: popupWidget,
                          ),
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Select City',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Buttons
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
                        print('selectedLedger: $selectedLedger');
                        print('selectedSalesperson: $selectedSalesperson');
                        print('fromDate: $fromDate');
                        print('toDate: $toDate');
                        print('selectedState: $selectedState');
                        print('selectedCity: $selectedCity');

                        FilterData.selectedLedger = selectedLedger;
                        // FilterData.selectedSalesperson = selectedSalesperson;
                        FilterData.selectedCity = selectedCity;
                        FilterData.selectedState = selectedState;
                        FilterData.selectedSalespersons = selectedsalespersons;
                        FilterData.selectedLedgers = selectedLedgers;
                        FilterData.selectedStates = selectedStates;
                        FilterData.selectedCities = selectedCities;
                        FilterData.selectedDateRange = selectedDateRange;
                        FilterData.fromDate = fromDate;
                        FilterData.toDate = toDate;

                        widget.onApplyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                        FilterData.selectedSalespersons = [];
                        FilterData.selectedLedgers = [];
                        FilterData.selectedStates = [];
                        FilterData.selectedCities = [];

                        setState(() {
                          selectedsalespersons = FilterData.selectedSalespersons ?? [];
                          selectedCities = FilterData.selectedCities ?? [];
                          selectedStates = FilterData.selectedStates ?? [];
                          selectedLedgers = FilterData.selectedLedgers ?? [];
                        });
                        setState(() {
                          selectedLedger = null;
                          selectedSalesperson = null;
                          selectedState = null;
                          selectedCity = null;
                          fromDate = null;
                          toDate = null;
                          selectedOrderStatus = null;
                          selectedDateRange = 'Custom';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
