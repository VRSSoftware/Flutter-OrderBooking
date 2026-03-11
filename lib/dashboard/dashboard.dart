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

  final ScrollController _dateRangeScrollController = ScrollController();
  bool _showCustomDatePicker = false;

  final List<String> dateRanges = [
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
 
  ];

  @override
  void initState() {
    super.initState();
    _updateDateRange('Today');
    _loadDropdownData();
    _fetchOrderSummary();
  }

  @override
  void dispose() {
    _dateRangeScrollController.dispose();
    super.dispose();
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
      });
      _fetchOrderSummary();
    }
  }

  void _updateDateRange(String range) {
    final now = DateTime.now();
    setState(() {
      selectedRange = range;
      FilterData.selectedDateRange = range;
      _showCustomDatePicker = (range == 'Custom');
      
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
    } finally {
      setState(() {
        isLoadingOrderDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: DrawerScreen(),
     appBar: AppBar(
  title: Text(
    'Dashboard',
    style: GoogleFonts.poppins(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
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
  actions: [
    Container(
      margin: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.2),
        child: IconButton(
          icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
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
                              _showCustomDatePicker = (selectedRange == 'Custom');
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
        ),
      ),
    ),
  ],
  iconTheme: const IconThemeData(color: Colors.white),
),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horizontal Date Range Scroll
                    _buildHorizontalDateRange(),
                    
                    if (_showCustomDatePicker) ...[
                      const SizedBox(height: 16),
                      _buildCustomDatePicker(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Key Metrics - Total Orders
                    _buildKeyMetricsSection(),
                    const SizedBox(height: 20),

                    // Order Status Section
                    _buildOrderStatusSection(),
                    const SizedBox(height: 20),

                    // Inventory Summary
                    _buildInventorySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

          if (isLoadingOrderDetails)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     await Navigator.push(
      //       context,
      //       PageRouteBuilder(
      //         pageBuilder:
      //             (context, animation, secondaryAnimation) =>
      //                 DashboardFilterPage(
      //                   ledgerList: ledgerList,
      //                   salespersonList: salespersonList,
      //                   onApplyFilters: ({
      //                     KeyName? selectedLedger,
      //                     KeyName? selectedSalesperson,
      //                     DateTime? fromDate,
      //                     DateTime? toDate,
      //                     KeyName? selectedState,
      //                     KeyName? selectedCity,
      //                   }) {
      //                     setState(() {
      //                       this.selectedLedger = selectedLedger;
      //                       this.selectedSalesperson = selectedSalesperson;
      //                       this.fromDate = fromDate ?? this.fromDate;
      //                       this.toDate = toDate ?? this.toDate;
      //                       this.selectedCity =
      //                           selectedCity ??
      //                           KeyName(key: '', name: 'All Cities');
      //                     });
      //                     setState(() {
      //                       selectedRange =
      //                           FilterData.selectedDateRange ?? 'Today';
      //                       fromDate = FilterData.fromDate;
      //                       toDate = FilterData.toDate;
      //                       _showCustomDatePicker = (selectedRange == 'Custom');
      //                     });

      //                     _fetchOrderSummary();
      //                   },
      //                 ),
      //         settings: RouteSettings(
      //           arguments: {
      //             'ledgerList': ledgerList,
      //             'salespersonList': salespersonList,
      //             'statesList': statesList,
      //             'citiesList': citiesList,
      //             'fromDate': fromDate,
      //             'toDate': toDate,
      //           },
      //         ),
      //       ),
      //     );
      //   },
      //   backgroundColor: AppColors.primaryColor,
      //   icon: const Icon(Icons.filter_list, color: Colors.white),
      //   label: Text(
      //     'Filter',
      //     style: GoogleFonts.poppins(
      //       color: Colors.white,
      //       fontWeight: FontWeight.w500,
      //     ),
      //   ),
      // ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen: '/dashboard'),
    );
  }

  Widget _buildHorizontalDateRange() {
    return Container(
      height: 50,
      child: ListView.builder(
        controller: _dateRangeScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dateRanges.length,
        itemBuilder: (context, index) {
          final range = dateRanges[index];
          final isSelected = selectedRange == range;
          
          return GestureDetector(
            onTap: () => _updateDateRange(range),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  range,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDatePickerField(
              label: 'From',
              date: fromDate,
              onTap: () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDatePickerField(
              label: 'To',
              date: toDate,
              onTap: () => _selectDate(context, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetricsSection() {
    return GestureDetector(
      onTap: () => _showOrderDetails('TOTALORDER'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Orders',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  orderDocCount,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${double.parse(orderQty).toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Order Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatusCard(
                  title: 'PENDING',
                  count: pendingDocCount,
                  qty: pendingQty,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.hourglass_empty,
                  onTap: () => _showOrderDetails('PENDINGORDER'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatusCard(
                  title: 'PACKED',
                  count: packedDocCount,
                  qty: packedQty,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle,
                  onTap: () => _showOrderDetails('PACKEDORDER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactStatusCard(
                  title: 'CANCELLED',
                  count: cancelledDocCount,
                  qty: cancelledQty,
                  color: const Color(0xFFEF4444),
                  icon: Icons.cancel,
                  onTap: () => _showOrderDetails('CANCELLEDORDER'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactStatusCard(
                  title: 'INVOICED',
                  count: invoicedDocCount,
                  qty: invoicedQty,
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.receipt,
                  onTap: () => _showOrderDetails('INVOICEDORDER'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusCard({
    required String title,
    required String count,
    required String qty,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        count,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${double.parse(qty).toStringAsFixed(0)})',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Inventory Summary',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCompactInventoryCard(
                  title: 'In Hand',
                  count: inHand,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactInventoryCard(
                  title: 'To Be Received',
                  count: toBeReceived,
                  color: const Color(0xFF3B82F6),
                  icon: Icons.local_shipping,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInventoryCard({
    required String title,
    required String count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
    } finally {
      setState(() {
        isLoadingOrderDetails = false;
      });
    }
  }
}