// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/keyName.dart';

// class OrderStatusFilterPage extends StatefulWidget {
//   final List<KeyName> brandsList;
//   final List<KeyName> stylesList;
//   final List<KeyName> shadesList;
//   final List<KeyName> sizesList;
//   final List<KeyName> statusList;
//   final Map<String, dynamic> initialFilters;

//   final Function({
//     DateTime? fromDate,
//     DateTime? toDate,
//     List<KeyName>? selectedBrand,
//     List<KeyName>? selectedStyle,
//     List<KeyName>? selectedShade,
//     List<KeyName>? selectedSize,

//     KeyName? selectedStatus,
//     KeyName? groupBy,
//     bool? withImage,
//   }) onApplyFilters;

//   const OrderStatusFilterPage({
//     Key? key,
//     required this.brandsList,
//     required this.stylesList,
//     required this.shadesList,
//     required this.sizesList,
//     required this.statusList,
//     required this.initialFilters,
//     required this.onApplyFilters,
//   }) : super(key: key);

//   @override
//   State<OrderStatusFilterPage> createState() => _OrderStatusFilterPageState();
// }

// class _OrderStatusFilterPageState extends State<OrderStatusFilterPage> {
//   DateTime? fromDate;
//   DateTime? toDate;
//   String? selectedDateRange;
//   List<KeyName> selectedBrand = [];
//   List<KeyName> selectedStyle = [];
//   List<KeyName> selectedShade = [];
//   List<KeyName> selectedSize = [];
//   KeyName? selectedStatus;
//   KeyName? groupBy;
//   bool withImage = false;

//   final List<String> dateRangeOptions = [
//     'Today',
//     'Yesterday',
//     'This Week',
//     'Previous Week',
//     'This Month',
//     'Previous Month',
//     'This Quarter',
//     'Previous Quarter',
//     'This Year',
//     'Previous Year',
//     'Custom',
//   ];

//   final List<KeyName> groupByOptions = [
//     KeyName(key: 'cust', name: 'Customer'),
//     KeyName(key: 'design', name: 'Design'),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // Initialize with passed filters
//     fromDate = widget.initialFilters['fromDate'] as DateTime?;
//     toDate = widget.initialFilters['toDate'] as DateTime?;
//     selectedBrand = widget.initialFilters['selectedBrand'] as List<KeyName>? ?? [];
//     selectedStyle = widget.initialFilters['selectedStyle'] as List<KeyName>? ?? [];
//     selectedShade = widget.initialFilters['selectedShade'] as List<KeyName>? ?? [];
//     selectedSize = widget.initialFilters['selectedSize'] as List<KeyName>? ?? [];
//     selectedStatus = widget.initialFilters['selectedStatus'] as KeyName? ??
//         widget.statusList.firstWhere((s) => s.key == 'all');
//     groupBy = widget.initialFilters['groupBy'] as KeyName? ??
//         groupByOptions.firstWhere((g) => g.key == 'cust');
//     withImage = widget.initialFilters['withImage'] as bool? ?? false;
//     selectedDateRange = widget.initialFilters['selectedDateRange'] as String? ?? 'Custom';
//   }

//   void _setDateRange(String range) {
//     final now = DateTime.now();
//     DateTime start, end;
//     switch (range) {
//       case 'Today':
//         start = DateTime(now.year, now.month, now.day);
//         end = DateTime(now.year, now.month, now.day, 23, 59, 59);
//         break;
//       case 'Yesterday':
//         final yesterday = now.subtract(const Duration(days: 1));
//         start = DateTime(yesterday.year, yesterday.month, yesterday.day);
//         end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
//         break;
//       case 'This Week':
//         start = now.subtract(Duration(days: now.weekday - 1));
//         end = DateTime(now.year, now.month, now.day, 23, 59, 59);
//         break;
//       case 'Previous Week':
//         final firstDayOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
//         start = DateTime(firstDayOfLastWeek.year, firstDayOfLastWeek.month, firstDayOfLastWeek.day);
//         end = DateTime(firstDayOfLastWeek.year, firstDayOfLastWeek.month, firstDayOfLastWeek.day + 6, 23, 59, 59);
//         break;
//       case 'This Month':
//         start = DateTime(now.year, now.month, 1);
//         end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
//         break;
//       case 'Previous Month':
//         start = DateTime(now.year, now.month - 1, 1);
//         end = DateTime(now.year, now.month, 0, 23, 59, 59);
//         break;
//       case 'This Quarter':
//         final quarter = (now.month - 1) ~/ 3;
//         start = DateTime(now.year, quarter * 3 + 1, 1);
//         end = DateTime(now.year, quarter * 3 + 4, 0, 23, 59, 59);
//         break;
//       case 'Previous Quarter':
//         final quarter = (now.month - 1) ~/ 3;
//         final prevQuarter = quarter == 0 ? 3 : quarter - 1;
//         final prevQuarterYear = quarter == 0 ? now.year - 1 : now.year;
//         start = DateTime(prevQuarterYear, prevQuarter * 3 + 1, 1);
//         end = DateTime(prevQuarterYear, prevQuarter * 3 + 4, 0, 23, 59, 59);
//         break;
//       case 'This Year':
//         start = DateTime(now.year, 1, 1);
//         end = DateTime(now.year, 12, 31, 23, 59, 59);
//         break;
//       case 'Previous Year':
//         start = DateTime(now.year - 1, 1, 1);
//         end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
//         break;
//       default:
//         return;
//     }
//     setState(() {
//       fromDate = start;
//       toDate = end;
//       selectedDateRange = range;
//     });
//   }

//   Future<void> _pickDate(BuildContext context, bool isFromDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: isFromDate ? fromDate ?? DateTime.now() : toDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isFromDate) {
//           fromDate = picked;
//         } else {
//           toDate = picked;
//         }
//         selectedDateRange = 'Custom';
//       });
//     }
//   }

//   String _formatDate(DateTime? date) {
//     return date != null ? DateFormat('dd-MM-yyyy').format(date) : '';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Filter Order Status'),
//         backgroundColor: AppColors.primaryColor,
//         iconTheme: const IconThemeData(color: Colors.white),
//         titleTextStyle: const TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       body: Container(
//         color: Colors.white,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Date Range Filter
//               _buildExpansionTile(
//                 title: 'Date Range Filter',
//                 children: [
//                   DropdownButtonFormField<String>(
//                     decoration: const InputDecoration(
//                       labelText: 'Select Date Range',
//                     ),
//                     dropdownColor: Colors.white,
//                     value: selectedDateRange,
//                     items: dateRangeOptions
//                         .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                         .toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         selectedDateRange = value;
//                         if (value != 'Custom') _setDateRange(value!);
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           readOnly: true,
//                           decoration: InputDecoration(
//                             labelText: 'From Date',
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           controller: TextEditingController(
//                             text: _formatDate(fromDate),
//                           ),
//                           onTap: () => _pickDate(context, true),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: TextFormField(
//                           readOnly: true,
//                           decoration: InputDecoration(
//                             labelText: 'To Date',
//                             filled: true,
//                             fillColor: Colors.white,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           controller: TextEditingController(
//                             text: _formatDate(toDate),
//                           ),
//                           onTap: () => _pickDate(context, false),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               // Brands Filter
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Brands',
//                 children: [
//                   DropdownSearch<KeyName>.multiSelection(
//                     items: widget.brandsList,
//                     selectedItems: selectedBrand,
//                     itemAsString: (KeyName? u) => u?.name ?? '',
//                     onChanged: (value) => setState(() => selectedBrand = value),
//                     popupProps: PopupPropsMultiSelection.menu(
//                       showSearchBox: true,
//                       containerBuilder: (context, popupWidget) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: popupWidget,
//                       ),
//                     ),
//                     dropdownDecoratorProps: DropDownDecoratorProps(
//                       dropdownSearchDecoration: InputDecoration(
//                         labelText: 'Select Brands',
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // Style Filter
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Style',
//                 children: [
//                   DropdownSearch<KeyName>.multiSelection(
//                     items: widget.stylesList,
//                     selectedItems: selectedStyle,
//                     itemAsString: (KeyName? u) => u?.name ?? '',
//                     onChanged: (value) => setState(() => selectedStyle = value),
//                     popupProps: PopupPropsMultiSelection.menu(
//                       showSearchBox: true,
//                       containerBuilder: (context, popupWidget) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: popupWidget,
//                       ),
//                     ),
//                     dropdownDecoratorProps: DropDownDecoratorProps(
//                       dropdownSearchDecoration: InputDecoration(
//                         labelText: 'Select Styles',
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // Shade Filter
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Shade',
//                 children: [
//                   DropdownSearch<KeyName>.multiSelection(
//                     items: widget.shadesList,
//                     selectedItems: selectedShade,
//                     itemAsString: (KeyName? u) => u?.name ?? '',
//                     onChanged: (value) => setState(() => selectedShade = value),
//                     popupProps: PopupPropsMultiSelection.menu(
//                       showSearchBox: true,
//                       containerBuilder: (context, popupWidget) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: popupWidget,
//                       ),
//                     ),
//                     dropdownDecoratorProps: DropDownDecoratorProps(
//                       dropdownSearchDecoration: InputDecoration(
//                         labelText: 'Select Shades',
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // Sizes Filter
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Sizes',
//                 children: [
//                   DropdownSearch<KeyName>.multiSelection(
//                     items: widget.sizesList,
//                     selectedItems: selectedSize,
//                     itemAsString: (KeyName? u) => u?.name ?? '',
//                     onChanged: (value) => setState(() => selectedSize = value),
//                     popupProps: PopupPropsMultiSelection.menu(
//                       showSearchBox: true,
//                       containerBuilder: (context, popupWidget) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: popupWidget,
//                       ),
//                     ),
//                     dropdownDecoratorProps: DropDownDecoratorProps(
//                       dropdownSearchDecoration: InputDecoration(
//                         labelText: 'Select Sizes',
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // Status Filter
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Status',
//                 children: [
//                   DropdownSearch<KeyName>(
//                     items: widget.statusList,
//                     selectedItem: selectedStatus,
//                     itemAsString: (KeyName? u) => u?.name ?? '',
//                     onChanged: (value) => setState(() => selectedStatus = value),
//                     popupProps: PopupProps.menu(
//                       showSearchBox: true,
//                       containerBuilder: (context, popupWidget) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: popupWidget,
//                       ),
//                     ),
//                     dropdownDecoratorProps: DropDownDecoratorProps(
//                       dropdownSearchDecoration: InputDecoration(
//                         labelText: 'Select Status',
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // Group By Filter
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Group By',
//                 children: [
//                   DropdownSearch<KeyName>(
//                     items: groupByOptions,
//                     selectedItem: groupBy,
//                     itemAsString: (KeyName? u) => u?.name ?? '',
//                     onChanged: (value) => setState(() => groupBy = value),
//                     popupProps: PopupProps.menu(
//                       showSearchBox: true,
//                       containerBuilder: (context, popupWidget) => Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.5),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         child: popupWidget,
//                       ),
//                     ),
//                     dropdownDecoratorProps: DropDownDecoratorProps(
//                       dropdownSearchDecoration: InputDecoration(
//                         labelText: 'Group By',
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               // With Image Checkbox
//               const SizedBox(height: 10),
//               _buildExpansionTile(
//                 title: 'Image Option',
//                 children: [
//                   Row(
//                     children: [
//                       Checkbox(
//                         value: withImage,
//                         onChanged: (value) {
//                           setState(() {
//                             withImage = value ?? false;
//                           });
//                         },
//                       ),
//                       const Text('Include Images in Results'),
//                     ],
//                   ),
//                 ],
//               ),
//               // Buttons
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('To Date cannot be before From Date'),
//                             ),
//                           );
//                           return;
//                         }
//                         widget.onApplyFilters(
//                           fromDate: fromDate,
//                           toDate: toDate,
//                           selectedBrand: selectedBrand,
//                           selectedStyle: selectedStyle,
//                           selectedShade: selectedShade,
//                           selectedSize: selectedSize,
//                           selectedStatus: selectedStatus,
//                           groupBy: groupBy,
//                           withImage: withImage,
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 14),
//                         child: Text(
//                           'Apply Filters',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           fromDate = DateTime.now().subtract(const Duration(days: 30));
//                           toDate = DateTime.now();
//                           selectedDateRange = 'Custom';
//                           selectedBrand = [];
//                           selectedStyle = [];
//                           selectedShade = [];
//                           selectedSize = [];
//                           selectedStatus = widget.statusList.firstWhere((s) => s.key == 'all');
//                           groupBy = groupByOptions.firstWhere((g) => g.key == 'cust');
//                           withImage = false;
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.grey,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 14),
//                         child: Text(
//                           'Clear Filters',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildExpansionTile({
//     required String title,
//     required List<Widget> children,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Theme(
//         data: ThemeData().copyWith(dividerColor: Colors.transparent),
//         child: ExpansionTile(
//           initiallyExpanded: true,
//           tilePadding: const EdgeInsets.symmetric(horizontal: 16),
//           childrenPadding: const EdgeInsets.all(16),
//           title: Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           children: children,
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/orderStatusFilterData.dart';
import 'package:vrs_erp/models/keyName.dart';

class OrderStatusFilterPage extends StatefulWidget {
  final List<KeyName> brandsList;
  final List<KeyName> stylesList;
  final List<KeyName> shadesList;
  final List<KeyName> sizesList;
  final List<KeyName> statusList;
  final Map<String, dynamic> filters;
  final List<KeyName> groupByOptions;
  final Function({
    DateTime? fromDate,
    DateTime? toDate,
    List<KeyName>? selectedBrand,
    List<KeyName>? selectedStyle,
    List<KeyName>? selectedShade,
    List<KeyName>? selectedSize,
    KeyName? selectedStatus,
    KeyName? groupBy,
    bool? withImage,
    String? selectedDateRange,
  })
  onApplyFilters;

  const OrderStatusFilterPage({
    super.key,
    required this.brandsList,
    required this.stylesList,
    required this.shadesList,
    required this.sizesList,
    required this.statusList,
    required this.filters,
    required this.groupByOptions,
    required this.onApplyFilters,
  });

  @override
  State<OrderStatusFilterPage> createState() => _OrderStatusFilterPageState();
}

class _OrderStatusFilterPageState extends State<OrderStatusFilterPage> {
  DateTime? fromDate;
  DateTime? toDate;
  String? selectedDateRange;
  List<KeyName> selectedBrand = [];
  List<KeyName> selectedStyle = [];
  List<KeyName> selectedShade = [];
  List<KeyName> selectedSize = [];
  KeyName? selectedStatus;
  KeyName? groupBy;
  bool withImage = false;

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
  void initState() {
    super.initState();
    // setState(() {
    //   fromDate = Orderstatusfilterdata.fromDate;
    //   toDate = Orderstatusfilterdata.toDate;
    //   selectedBrand = Orderstatusfilterdata.selectedBrand!;
    //   selectedStyle = Orderstatusfilterdata.selectedStyle!;
    //   selectedShade = Orderstatusfilterdata.selectedShade!;
    //   selectedSize = Orderstatusfilterdata.selectedSize!;
    //   selectedStatus = Orderstatusfilterdata.selectedStatus;
    //   groupBy = Orderstatusfilterdata.groupBy;
    //   withImage = Orderstatusfilterdata.withImage!;
    //   selectedDateRange = Orderstatusfilterdata.selectedDateRange;
   
   
    // });
  fromDate = widget.filters['fromDate'] as DateTime?;
  toDate = widget.filters['toDate'] as DateTime?;
  selectedBrand = widget.filters['selectedBrand'] as List<KeyName>? ?? [];
  selectedStyle = widget.filters['selectedStyle'] as List<KeyName>? ?? [];
  selectedShade = widget.filters['selectedShade'] as List<KeyName>? ?? [];
  selectedSize = widget.filters['selectedSize'] as List<KeyName>? ?? [];
  selectedStatus = widget.filters['selectedStatus'] as KeyName? ??
      widget.statusList.firstWhere(
        (s) => s.key == 'all',
        orElse: () => widget.statusList[0],
      );
  groupBy = widget.filters['groupBy'] as KeyName? ??
      widget.groupByOptions.firstWhere(
        (g) => g.key == 'cust',
        orElse: () => widget.groupByOptions[0],
      );
  withImage = widget.filters['withImage'] as bool? ?? false;
  selectedDateRange = widget.filters['selectedDateRange'] as String? ?? 'Custom';
    // Initialize with passed filters
    //fromDate = widget.filters['fromDate'] as DateTime?;
    //toDate = widget.filters['toDate'] as DateTime?;
    //selectedBrand = widget.filters['selectedBrand'] as List<KeyName>? ?? [];
    //selectedStyle = widget.filters['selectedStyle'] as List<KeyName>? ?? [];
    //selectedShade = widget.filters['selectedShade'] as List<KeyName>? ?? [];
    //selectedSize = widget.filters['selectedSize'] as List<KeyName>? ?? [];
    //selectedStatus = widget.filters['selectedStatus'] as KeyName? ??
    //    widget.statusList.firstWhere((s) => s.key == 'all', orElse: () => widget.statusList[0]);
    //groupBy = widget.filters['groupBy'] as KeyName? ??
    //  widget.groupByOptions.firstWhere((g) => g.key == 'cust', orElse: () => widget.groupByOptions[0]);
    //withImage = widget.filters['withImage'] as bool? ?? false;
    // selectedDateRange = widget.filters['selectedDateRange'] as String? ?? 'Custom';
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
        start = firstDayOfLastWeek;
        end = firstDayOfLastWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
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
        title: const Text('Filter Order Status'),
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
              // Brands Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Brands',
                children: [
                  DropdownSearch<KeyName>.multiSelection(
                    items: widget.brandsList,
                    selectedItems: selectedBrand,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged: (value) => setState(() => selectedBrand = value),
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
                        labelText: 'Select Brands',
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
              // Style Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Style',
                children: [
                  DropdownSearch<KeyName>.multiSelection(
                    items: widget.stylesList,
                    selectedItems: selectedStyle,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged: (value) => setState(() => selectedStyle = value),
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
                        labelText: 'Select Styles',
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
              // Shade Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Shade',
                children: [
                  DropdownSearch<KeyName>.multiSelection(
                    items: widget.shadesList,
                    selectedItems: selectedShade,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged: (value) => setState(() => selectedShade = value),
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
                        labelText: 'Select Shades',
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
              // Sizes Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Sizes',
                children: [
                  DropdownSearch<KeyName>.multiSelection(
                    items: widget.sizesList,
                    selectedItems: selectedSize,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged: (value) => setState(() => selectedSize = value),
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
                        labelText: 'Select Sizes',
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
              // Status Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Status',
                children: [
                  DropdownSearch<KeyName>(
                    items: widget.statusList,
                    selectedItem: selectedStatus,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged:
                        (value) => setState(() => selectedStatus = value),
                    popupProps: PopupProps.menu(
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
                        labelText: 'Select Status',
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
              // Group By Filter
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Group By',
                children: [
                  DropdownSearch<KeyName>(
                    items: widget.groupByOptions,
                    selectedItem: groupBy,
                    itemAsString: (KeyName? u) => u?.name ?? '',
                    onChanged: (value) => setState(() => groupBy = value),
                    popupProps: PopupProps.menu(
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
                        labelText: 'Group By',
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
              // With Image Checkbox
              const SizedBox(height: 10),
              _buildExpansionTile(
                title: 'Image Option',
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: withImage,
                        onChanged: (value) {
                          setState(() {
                            withImage = value ?? false;
                          });
                        },
                      ),
                      const Text('Include Images in Results'),
                    ],
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
                        Orderstatusfilterdata.fromDate = fromDate;
                        Orderstatusfilterdata.toDate = toDate;

                        Orderstatusfilterdata.selectedBrand = selectedBrand;

                        Orderstatusfilterdata.selectedStyle = selectedStyle;
                        Orderstatusfilterdata.selectedShade = selectedShade;
                        Orderstatusfilterdata.selectedSize = selectedSize;
                        Orderstatusfilterdata.selectedStatus = selectedStatus;
                        Orderstatusfilterdata.groupBy = groupBy;

                        Orderstatusfilterdata.withImage = withImage;
                        Orderstatusfilterdata.selectedDateRange =
                            selectedDateRange;

                        widget.onApplyFilters(
                          fromDate: fromDate,
                          toDate: toDate,
                          selectedBrand: selectedBrand,
                          selectedStyle: selectedStyle,
                          selectedShade: selectedShade,
                          selectedSize: selectedSize,
                          selectedStatus: selectedStatus,
                          groupBy: groupBy,
                          withImage: withImage,
                          selectedDateRange: selectedDateRange,
                        );
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
                        setState(() {
                          fromDate = DateTime.now().subtract(
                            const Duration(days: 30),
                          );
                          toDate = DateTime.now();
                          selectedDateRange = 'Custom';
                          selectedBrand = [];
                          selectedStyle = [];
                          selectedShade = [];
                          selectedSize = [];
                          selectedStatus = widget.statusList.firstWhere(
                            (s) => s.key == 'all',
                            orElse: () => widget.statusList[0],
                          );
                          groupBy = widget.groupByOptions.firstWhere(
                            (g) => g.key == 'cust',
                            orElse: () => widget.groupByOptions[0],
                          );
                          withImage = false;
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
