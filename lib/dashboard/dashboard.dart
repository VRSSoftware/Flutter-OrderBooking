import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/dashboard/OrderDetails_page.dart';
import 'package:vrs_erp/dashboard/dashboard_filter.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
import 'package:vrs_erp/dashboard/data.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String selectedRange = 'Today';

  String? customer;
  String? city;
  String? salesman;
  String? state;

  String orderDocCount = '0';
  String pendingQty = '0';
  String packedDocCount = '0';
  String cancelledQty = '0';
  String invoicedDocCount = '0';
  String invoicedQty = '0';
  String orderQty = '0';
  String pendingDocCount = '0';
  String packedQty = '0';
  String cancelledDocCount = '0';
  String toBeReceived = '0';
  String inHand = '0';

  KeyName? selectedLedger;
  KeyName? selectedSalesperson;
  KeyName selectedState = KeyName(key: '', name: 'All States');
  KeyName selectedCity = KeyName(key: '', name: 'All Cities');
  List<KeyName> ledgerList = [];
  List<KeyName> salespersonList = [];
  List<KeyName> statesList = [];
  List<KeyName> citiesList = [];
  bool isLoadingLedgers = true;
  bool isLoading = false;
  bool isLoadingOrderDetails = false;
  bool isLoadingSalesperson = true;

  @override
  void initState() {
    super.initState();
    _updateDateRange('Today');
    _loadDropdownData();
    _fetchOrderSummary();
  }

  Future<void> _loadDropdownData() async {
    setState(() {
      isLoadingLedgers = true;
      isLoadingSalesperson = true;
    });

    try {
      final fetchedLedgersResponse = await ApiService.fetchLedgers(
        ledCat: 'w',
        coBrId: UserSession.coBrId ?? '',
      );
      final fetchedSalespersonResponse = await ApiService.fetchLedgers(
        ledCat: 's',
        coBrId: UserSession.coBrId ?? '',
      );
      final fetchedStatesResponse = await ApiService.fetchStates();
      final fetchedCitiesResponse = await ApiService.fetchCities(stateKey: "");

      setState(() {
        ledgerList = [
          ...List<KeyName>.from(fetchedLedgersResponse['result'] ?? []),
        ];
        salespersonList = [
          ...List<KeyName>.from(fetchedSalespersonResponse['result'] ?? []),
        ];
        statesList = [
          ...List<KeyName>.from(fetchedStatesResponse['result'] ?? []),
        ];
        citiesList = [
          ...List<KeyName>.from(fetchedCitiesResponse['result'] ?? []),
        ];
        isLoadingLedgers = false;
        isLoadingSalesperson = false;
      });
    } catch (e) {
      setState(() {
        isLoadingLedgers = false;
        isLoadingSalesperson = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching dropdown data: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate : toDate,
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
        selectedRange = 'Custom';
      });
      _fetchOrderSummary();
    }
  }

  void _updateDateRange(String range) {
    final now = DateTime.now();
    setState(() {
      // selectedRange = range;
   selectedRange = range; // Update selectedRange directly
    FilterData.selectedDateRange = range;
      switch (range) {
        case 'Today':
          fromDate = DateTime(now.year, now.month, now.day);
          toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          fromDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          toDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          );
          break;
        case 'This Week':
          final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
          fromDate = DateTime(
            firstDayOfWeek.year,
            firstDayOfWeek.month,
            firstDayOfWeek.day,
          );
          toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Previous Week':
          final firstDayOfLastWeek = now.subtract(
            Duration(days: now.weekday + 6),
          );
          fromDate = DateTime(
            firstDayOfLastWeek.year,
            firstDayOfLastWeek.month,
            firstDayOfLastWeek.day,
          );
          toDate = DateTime(
            firstDayOfLastWeek.year,
            firstDayOfLastWeek.month,
            firstDayOfLastWeek.day + 6,
            23,
            59,
            59,
          );
          break;
        case 'This Month':
          fromDate = DateTime(now.year, now.month, 1);
          toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Previous Month':
          final firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);
          fromDate = firstDayOfLastMonth;
          toDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case 'This Quarter':
          final quarter = (now.month - 1) ~/ 3;
          fromDate = DateTime(now.year, quarter * 3 + 1, 1);
          toDate = DateTime(now.year, quarter * 3 + 4, 0, 23, 59, 59);
          break;
        case 'Previous Quarter':
          final quarter = (now.month - 1) ~/ 3;
          final prevQuarter = quarter == 0 ? 3 : quarter - 1;
          final prevQuarterYear = quarter == 0 ? now.year - 1 : now.year;
          fromDate = DateTime(prevQuarterYear, prevQuarter * 3 + 1, 1);
          toDate = DateTime(
            prevQuarterYear,
            prevQuarter * 3 + 4,
            0,
            23,
            59,
            59,
          );
          break;
        case 'This Year':
          fromDate = DateTime(now.year, 1, 1);
          toDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case 'Previous Year':
          fromDate = DateTime(now.year - 1, 1, 1);
          toDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
          break;
        case 'Custom':
          break;
      }
    });
    FilterData.fromDate = fromDate;
    FilterData.toDate = toDate;
    _fetchOrderSummary();
  }

  Future<void> _fetchOrderSummary() async {
    setState(() {
     isLoadingOrderDetails = true;
    });
    final String apiUrl =
        '${AppConstants.BASE_URL}/orderRegister/order-details-dash';
    try {
      final body = jsonEncode({
        "FromDate":
            "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
        "ToDate":
            "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
        "CoBr_Id": UserSession.coBrId,
        "CustKey":
            UserSession.userType == 'C'
                ? UserSession.userLedKey
                : FilterData.selectedLedgers!.isNotEmpty
                ? FilterData.selectedLedgers!.map((b) => b.key).join(',')
                : null,
        "SalesPerson":
            UserSession.userType == 'S'
                ? UserSession.userLedKey
                : FilterData.selectedSalespersons!.isNotEmpty == true
                ? FilterData.selectedSalespersons!.map((b) => b.key).join(',')
                : null,
        "State":
            FilterData.selectedStates!.isNotEmpty == true
                ? FilterData.selectedStates!.map((b) => b.key).join(',')
                : null,
        "City":
            FilterData.selectedCities!.isNotEmpty == true
                ? FilterData.selectedCities!.map((b) => b.key).join(',')
                : null,
        "orderType": null,
        "Detail": null,
      });
      print(body);
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          orderDocCount = data['orderdoccount']?.toString() ?? '0';
          pendingQty = data['pendingqty']?.toString() ?? '0';
          packedDocCount = data['packeddoccount']?.toString() ?? '0';
          cancelledQty = data['cancelledqty']?.toString() ?? '0';
          invoicedDocCount = data['invoiceddoccount']?.toString() ?? '0';
          invoicedQty = data['invoicedqty']?.toString() ?? '0';
          orderQty = data['orderqty']?.toString() ?? '0';
          pendingDocCount = data['pendingdoccount']?.toString() ?? '0';
          packedQty = data['packedqty']?.toString() ?? '0';
          cancelledDocCount = data['cancelleddoccount']?.toString() ?? '0';
          toBeReceived = data['tobereceived']?.toString() ?? '0';
          inHand = data['inhand']?.toString() ?? '0';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${response.statusCode}'),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
finally {
    setState(() {
      isLoadingOrderDetails = false; // Reset the overlay loader
    });
  }

  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress for each status based on orderDocCount
    double totalOrders = double.tryParse(orderDocCount) ?? 0;
    double pendingProgress =
        totalOrders > 0
            ? (double.tryParse(pendingDocCount) ?? 0) / totalOrders
            : 0;
    double packedProgress =
        totalOrders > 0
            ? (double.tryParse(packedDocCount) ?? 0) / totalOrders
            : 0;
    double cancelledProgress =
        totalOrders > 0
            ? (double.tryParse(cancelledDocCount) ?? 0) / totalOrders
            : 0;
    double invoicedProgress =
        totalOrders > 0
            ? (double.tryParse(invoicedDocCount) ?? 0) / totalOrders
            : 0;
    double inHandProgress =
        totalOrders > 0 ? (double.tryParse(inHand) ?? 0) / totalOrders : 0;
    double toBeReceivedProgress =
        totalOrders > 0
            ? (double.tryParse(toBeReceived) ?? 0) / totalOrders
            : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:Stack(
      children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Selection
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Date Range',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownSearch<String>(
                                    items: [
                                      'Custom',
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
                                    ],
                                    selectedItem: selectedRange,
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedRange = newValue;
                                          FilterData.selectedDateRange =
                                              newValue;
                                        });
                                        _updateDateRange(newValue);
                                      }
                                    },
                                    dropdownDecoratorProps:
                                        const DropDownDecoratorProps(
                                          dropdownSearchDecoration:
                                              InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                              ),
                                        ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      fit: FlexFit.loose,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          hintText: 'Search...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .zero, 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .zero, 
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius
                                                    .zero,
                                            borderSide: BorderSide(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ),

                                      containerBuilder:
                                          (context, popupWidget) => Container(
                                            width: 600,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius
                                                      .zero, 
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: popupWidget,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            if (selectedRange == 'Custom') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'From Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap:
                                              () => _selectDate(context, true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F7FA),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${fromDate.day.toString().padLeft(2, '0')}/${fromDate.month.toString().padLeft(2, '0')}/${fromDate.year}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'To Date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap:
                                              () => _selectDate(context, false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F7FA),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${toDate.day.toString().padLeft(2, '0')}/${toDate.month.toString().padLeft(2, '0')}/${toDate.year}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 20,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Total Orders Box with Status Cards
                    Card(
                      elevation: 0,
                      color: Colors.blue.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showOrderDetails('TOTALORDER');
                                // Your tap logic here
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB2EBF2),
                                      Color(0xFF80DEEA),
                                    ], // Example blue gradient
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TOTAL ORDER',
                                          style: GoogleFonts.quando(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          orderDocCount,
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${double.parse(orderQty).toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            // Row 1: Pending, Packed
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'PENDING',
                                    count: pendingDocCount,
                                    qty: pendingQty,
                                    progress: pendingProgress,
                                    color: const Color(0xFFE6F0FA),
                                    icon: Icons.hourglass_empty,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'PACKED',
                                    count: packedDocCount,
                                    qty: packedQty,
                                    progress: packedProgress,
                                    color: const Color(0xFFE8F5E9),
                                    icon: Icons.check_circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Row 2: Cancelled, Invoiced
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'CANCELLED',
                                    count: cancelledDocCount,
                                    qty: cancelledQty,
                                    progress: cancelledProgress,
                                    color: const Color(0xFFFFE6E6),
                                    icon: Icons.cancel,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'INVOICED',
                                    count: invoicedDocCount,
                                    qty: invoicedQty,
                                    progress: invoicedProgress,
                                    color: const Color(0xFFF3E8FF),
                                    icon: Icons.receipt,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Inventory Summary Box
                    Card(
                      elevation: 0,
                      color: const Color(0xFFE0F7FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Summary',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'IN HAND',
                                    count: inHand,
                                    qty: '0',
                                    progress: inHandProgress,
                                    color: Colors.white,
                                    icon: Icons.inventory,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatusCard(
                                    title: 'TO BE RECEIVED',
                                    count: toBeReceived,
                                    qty: '0',
                                    progress: toBeReceivedProgress,
                                    color: Colors.white,
                                    icon: Icons.local_shipping,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Overlay loader for order details
        if (isLoadingOrderDetails)
          Container(
            color: Colors.black.withOpacity(0.5), // Semi-transparent background
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        DashboardFilterPage(
                          ledgerList: ledgerList,
                          salespersonList: salespersonList,
                          onApplyFilters: ({
                            KeyName? selectedLedger,
                            KeyName? selectedSalesperson,
                            DateTime? fromDate,
                            DateTime? toDate,
                            KeyName? selectedState,
                            KeyName? selectedCity,
                          }) {
                            setState(() {
                              this.selectedLedger = selectedLedger;
                              this.selectedSalesperson = selectedSalesperson;
                              this.fromDate = fromDate ?? this.fromDate;
                              this.toDate = toDate ?? this.toDate;
                              this.selectedCity =
                                  selectedCity ??
                                  KeyName(key: '', name: 'All Cities');
                            });
                            setState(() {
                              selectedRange =
                                  FilterData.selectedDateRange ?? 'Today';
                              fromDate = FilterData.fromDate;
                              toDate = FilterData.toDate;
                            });

                            _fetchOrderSummary();
                          },
                        ),
                settings: RouteSettings(
                  arguments: {
                    'ledgerList': ledgerList,
                    'salespersonList': salespersonList,
                    'statesList': statesList,
                    'citiesList': citiesList,
                    'fromDate': fromDate,
                    'toDate': toDate,
                  },
                ),
              ),
            );
          },
          tooltip: 'Filter Orders',
          child: const Icon(Icons.filter_list, color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen:  '/dashboard',),
      // bottomNavigationBar: BottomNavigationWidget(
      //   currentIndex: 3, // 👈 Highlight Order icon
      //   onTap: (index) {
      //     if (index == 0) Navigator.pushNamed(context, '/home');
      //     if (index == 1) Navigator.pushNamed(context, '/catalog');
      //     if (index == 2) Navigator.pushNamed(context, '/orderbooking');
      //     if (index == 3) return;
      //     if (index == 4) Navigator.pushNamed(context, '/stockReport');
      //   },
      // ),
    );
  }

  Future<void> _showOrderDetails(String orderType) async {
    setState(() {
  isLoadingOrderDetails = true;
    });
    try {
      String formattedOrderType = orderType
          .split(' ')
          .map(
            (word) => word[0].toUpperCase() + word.substring(1).toLowerCase(),
          )
          .join('');
      print(formattedOrderType);
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/report/getReportsDetail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "FromDate":
              "${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
          "ToDate":
              "${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
          "CoBr_Id": UserSession.coBrId,
          "CustKey":
              UserSession.userType == 'C'
                  ? UserSession.userLedKey
                  : FilterData.selectedLedgers!.isNotEmpty
                  ? FilterData.selectedLedgers!.map((b) => b.key).join(',')
                  : null,
          "SalesPerson":
              UserSession.userType == 'S'
                  ? UserSession.userLedKey
                  : FilterData.selectedSalespersons!.isNotEmpty == true
                  ? FilterData.selectedSalespersons!.map((b) => b.key).join(',')
                  : null,
          "State":
              FilterData.selectedStates!.isNotEmpty == true
                  ? FilterData.selectedStates!.map((b) => b.key).join(',')
                  : null,
          "City":
              FilterData.selectedCities!.isNotEmpty == true
                  ? FilterData.selectedCities!.map((b) => b.key).join(',')
                  : null,
          "orderType": formattedOrderType,
          "Detail": 1,
        }),
      );
      print("@@@@@order detail Response body:${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OrderDetailsPage(
                    orderDetails: List<Map<String, dynamic>>.from(data),
                    fromDate: fromDate,
                    toDate: toDate,
                    orderType: formattedOrderType,
                  ),
            ),
          );
        } else {
          throw Exception('Unexpected response format: Expected a list');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load order details: ${response.statusCode}',
            ),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }finally {
    setState(() {
      isLoadingOrderDetails = false; // Reset the order details loading state
    });
  }

  }

  Widget _buildStatusCard({
    required String title,
    required String count,
    required String qty,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return _StatusCard(
      title: title,
      count: count,
      qty: qty,
      progress: progress,
      color: color,
      icon: icon,
      onTap: () {
        String orderType = title.replaceAll(' ', '');
        print(orderType);
        if (orderType.contains('INHAND') ||
            orderType.contains('TOBERECEIVED')) {
        } else if (orderType.contains('PENDING') ||
            orderType.contains('PACKED') ||
            orderType.contains('CANCELLED') ||
            orderType.contains('INVOICED')) {
          _showOrderDetails(orderType + 'ORDER');
        }
      },
    );
  }
}

class _StatusCard extends StatefulWidget {
  final String title;
  final String count;
  final String qty;
  final double progress;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _StatusCard({
    required this.title,
    required this.count,
    required this.qty,
    required this.progress,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  __StatusCardState createState() => __StatusCardState();
}

class __StatusCardState extends State<_StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 0,
        color: widget.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _progressAnimation.value,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.blueAccent,
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                    widget.count,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: GoogleFonts.lemon(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: ${double.parse(widget.qty).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
