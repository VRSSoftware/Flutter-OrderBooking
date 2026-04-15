import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_pdf_viewer.dart';
import 'dart:io';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/AccountReport_Services.dart';
import 'package:vrs_erp/services/Outstanding_Services.dart';
import 'outstanding_receivable_detail_page.dart';

class OutstandingReceivablePage extends StatefulWidget {
  const OutstandingReceivablePage({super.key});

  @override
  State<OutstandingReceivablePage> createState() =>
      _OutstandingReceivablePageState();
}

class _OutstandingReceivablePageState extends State<OutstandingReceivablePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // Date Filter variables
  DateTime fromDate = DateTime(DateTime.now().year, 4, 1);
  DateTime toDate = DateTime.now();
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

  // Sort variables
  String selectedSort = "name";
  String sortOrder = "asc";

  List<Map<String, dynamic>> _billsData = [];
  List<Map<String, dynamic>> _groupedLedgers = [];
  List<Map<String, dynamic>> _filteredLedgers = [];

  // Group data
  List<Map<String, dynamic>> _groupedByAccLGrp = [];
  List<Map<String, dynamic>> _filteredGroups = [];

  bool _isLoading = true;
  String _errorMessage = '';
  double _totalAmount = 0;
  double _groupTotalAmount = 0;

  final List<String> _filterOptions = [
    'All',
    'Due Today',
    'All Due',
    'Not Due',
    '>0',
    '>30',
    '>60',
    '>90',
    '>120',
    '>180',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterLedgers();
      _filterGroups();
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Custom') {
        _showDateRangePicker();
        return;
      }
      _filterDataByDueDays(filter);
    });
  }

  void _filterDataByDueDays(String filter) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Filter Ledgers
    List<Map<String, dynamic>> filteredLedgers = [];
    for (var ledger in _groupedLedgers) {
      List<Map<String, dynamic>> filteredBills = [];
      for (var bill in ledger['bills']) {
        DateTime dueDate;
        try {
          dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
          dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        } catch (e) {
          continue;
        }
        int daysDifference = today.difference(dueDate).inDays;

        if (_checkFilterCondition(filter, daysDifference)) {
          filteredBills.add(bill);
        }
      }
      if (filteredBills.isNotEmpty) {
        double totalAmount = 0;
        for (var bill in filteredBills) {
          double amount =
              bill['Amount'] is int
                  ? (bill['Amount'] as int).toDouble()
                  : bill['Amount'] as double;
          totalAmount += amount;
        }
        filteredLedgers.add({
          ...ledger,
          'bills': filteredBills,
          'totalAmount': totalAmount,
        });
      }
    }
    _filteredLedgers = filteredLedgers;
    _calculateTotalAmount();

    // Filter Groups
    List<Map<String, dynamic>> filteredGroups = [];
    for (var group in _groupedByAccLGrp) {
      List<Map<String, dynamic>> filteredBills = [];
      for (var bill in group['bills']) {
        DateTime dueDate;
        try {
          dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
          dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        } catch (e) {
          continue;
        }
        int daysDifference = today.difference(dueDate).inDays;

        if (_checkFilterCondition(filter, daysDifference)) {
          filteredBills.add(bill);
        }
      }
      if (filteredBills.isNotEmpty) {
        double totalAmount = 0;
        for (var bill in filteredBills) {
          double amount =
              bill['Amount'] is int
                  ? (bill['Amount'] as int).toDouble()
                  : bill['Amount'] as double;
          totalAmount += amount;
        }
        filteredGroups.add({
          ...group,
          'bills': filteredBills,
          'totalAmount': totalAmount,
          'billCount': filteredBills.length,
        });
      }
    }
    _filteredGroups = filteredGroups;
    _calculateGroupTotalAmount();

    _applySortToLedgers();
    _applySortToGroups();
  }

  bool _checkFilterCondition(String filter, int daysDifference) {
    switch (filter) {
      case 'All':
        return true;
      case 'Due Today':
        return daysDifference == 0;
      case 'All Due':
        return daysDifference >= 0;
      case 'Not Due':
        return daysDifference < 0;
      case '>0':
        return daysDifference > 0;
      case '>30':
        return daysDifference > 30;
      case '>60':
        return daysDifference > 60;
      case '>90':
        return daysDifference > 90;
      case '>120':
        return daysDifference > 120;
      case '>180':
        return daysDifference > 180;
      default:
        return true;
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterDataByDateRange(picked.start, picked.end);
      });
    } else {
      _filterDataByDueDays('All');
    }
  }

  void _filterDataByDateRange(DateTime start, DateTime end) {
    // Filter Ledgers by date range
    List<Map<String, dynamic>> filteredLedgers = [];
    for (var ledger in _groupedLedgers) {
      List<Map<String, dynamic>> filteredBills = [];
      for (var bill in ledger['bills']) {
        DateTime dueDate;
        try {
          dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
        } catch (e) {
          continue;
        }
        if (dueDate.isAfter(start) && dueDate.isBefore(end)) {
          filteredBills.add(bill);
        }
      }
      if (filteredBills.isNotEmpty) {
        double totalAmount = 0;
        for (var bill in filteredBills) {
          double amount =
              bill['Amount'] is int
                  ? (bill['Amount'] as int).toDouble()
                  : bill['Amount'] as double;
          totalAmount += amount;
        }
        filteredLedgers.add({
          ...ledger,
          'bills': filteredBills,
          'totalAmount': totalAmount,
        });
      }
    }
    _filteredLedgers = filteredLedgers;
    _calculateTotalAmount();

    // Filter Groups by date range
    List<Map<String, dynamic>> filteredGroups = [];
    for (var group in _groupedByAccLGrp) {
      List<Map<String, dynamic>> filteredBills = [];
      for (var bill in group['bills']) {
        DateTime dueDate;
        try {
          dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
        } catch (e) {
          continue;
        }
        if (dueDate.isAfter(start) && dueDate.isBefore(end)) {
          filteredBills.add(bill);
        }
      }
      if (filteredBills.isNotEmpty) {
        double totalAmount = 0;
        for (var bill in filteredBills) {
          double amount =
              bill['Amount'] is int
                  ? (bill['Amount'] as int).toDouble()
                  : bill['Amount'] as double;
          totalAmount += amount;
        }
        filteredGroups.add({
          ...group,
          'bills': filteredBills,
          'totalAmount': totalAmount,
          'billCount': filteredBills.length,
        });
      }
    }
    _filteredGroups = filteredGroups;
    _calculateGroupTotalAmount();

    _applySortToLedgers();
    _applySortToGroups();
  }

  void _clearFilter() {
    setState(() {
      _selectedFilter = 'All';
      _selectedDateRange = null;
      _filteredLedgers = List.from(_groupedLedgers);
      _filteredGroups = List.from(_groupedByAccLGrp);
      _totalAmount = _originalTotalAmount;
      _groupTotalAmount = _originalGroupTotalAmount;
      _applySortToLedgers();
      _applySortToGroups();
    });
  }

  void _filterLedgers() {
    if (_searchQuery.isEmpty) {
      _filteredLedgers = List.from(_groupedLedgers);
    } else {
      _filteredLedgers =
          _groupedLedgers.where((ledger) {
            final ledgerName = ledger['ledName'].toString().toLowerCase();
            return ledgerName.contains(_searchQuery.toLowerCase());
          }).toList();
    }
    _applySortToLedgers();
    _calculateTotalAmount();
  }

  void _filterGroups() {
    if (_searchQuery.isEmpty) {
      _filteredGroups = List.from(_groupedByAccLGrp);
    } else {
      _filteredGroups =
          _groupedByAccLGrp.where((group) {
            final groupName = group['accLGrpName'].toString().toLowerCase();
            return groupName.contains(_searchQuery.toLowerCase());
          }).toList();
    }
    _applySortToGroups();
    _calculateGroupTotalAmount();
  }

  void _applySortToLedgers() {
    if (selectedSort == "name") {
      _filteredLedgers.sort((a, b) {
        int comparison = a['ledName'].toString().compareTo(
          b['ledName'].toString(),
        );
        return sortOrder == "asc" ? comparison : -comparison;
      });
    } else if (selectedSort == "amount") {
      _filteredLedgers.sort((a, b) {
        int comparison = a['totalAmount'].compareTo(b['totalAmount']);
        return sortOrder == "asc" ? comparison : -comparison;
      });
    } else if (selectedSort == "avgPayDays") {
      _filteredLedgers.sort((a, b) {
        int comparison = a['avgPayDays'].compareTo(b['avgPayDays']);
        return sortOrder == "asc" ? comparison : -comparison;
      });
    }
  }

  void _applySortToGroups() {
    if (selectedSort == "name") {
      _filteredGroups.sort((a, b) {
        int comparison = a['accLGrpName'].toString().compareTo(
          b['accLGrpName'].toString(),
        );
        return sortOrder == "asc" ? comparison : -comparison;
      });
    } else if (selectedSort == "amount") {
      _filteredGroups.sort((a, b) {
        int comparison = a['totalAmount'].compareTo(b['totalAmount']);
        return sortOrder == "asc" ? comparison : -comparison;
      });
    } else if (selectedSort == "avgPayDays") {
      _filteredGroups.sort((a, b) {
        int comparison = a['avgPayDays'].compareTo(b['avgPayDays']);
        return sortOrder == "asc" ? comparison : -comparison;
      });
    }
  }

  void _calculateTotalAmount() {
    double total = 0;
    for (var ledger in _filteredLedgers) {
      total += ledger['totalAmount'] as double;
    }
    _totalAmount = total;
  }

  void _calculateGroupTotalAmount() {
    double total = 0;
    for (var group in _filteredGroups) {
      total += group['totalAmount'] as double;
    }
    _groupTotalAmount = total;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _filteredLedgers = List.from(_groupedLedgers);
        _filteredGroups = List.from(_groupedByAccLGrp);
        _totalAmount = _originalTotalAmount;
        _groupTotalAmount = _originalGroupTotalAmount;
      }
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
      _filteredLedgers = List.from(_groupedLedgers);
      _filteredGroups = List.from(_groupedByAccLGrp);
      _totalAmount = _originalTotalAmount;
      _groupTotalAmount = _originalGroupTotalAmount;
    });
  }

  void openDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DateFilterSheetForOutstanding(
          currentFromDate: fromDate,
          currentToDate: toDate,
          onApply: (fDate, tDate) {
            setState(() {
              fromDate = fDate;
              toDate = tDate;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Date filter will be implemented soon'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  void openSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String tempSort = selectedSort;
        String tempOrder = sortOrder;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Sort By",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSortOption(
                      context: context,
                      title: "Party Name",
                      isSelected: tempSort == "name",
                      order: tempSort == "name" ? tempOrder : null,
                      onTap: () {
                        if (tempSort == "name") {
                          tempOrder = tempOrder == "asc" ? "desc" : "asc";
                        } else {
                          tempSort = "name";
                          tempOrder = "asc";
                        }
                        setStateSB(() {});
                      },
                    ),

                    _buildSortOption(
                      context: context,
                      title: "Amount",
                      isSelected: tempSort == "amount",
                      order: tempSort == "amount" ? tempOrder : null,
                      onTap: () {
                        if (tempSort == "amount") {
                          tempOrder = tempOrder == "asc" ? "desc" : "asc";
                        } else {
                          tempSort = "amount";
                          tempOrder = "asc";
                        }
                        setStateSB(() {});
                      },
                    ),

                    _buildSortOption(
                      context: context,
                      title: "Avg Pay Days",
                      isSelected: tempSort == "avgPayDays",
                      order: tempSort == "avgPayDays" ? tempOrder : null,
                      onTap: () {
                        if (tempSort == "avgPayDays") {
                          tempOrder = tempOrder == "asc" ? "desc" : "asc";
                        } else {
                          tempSort = "avgPayDays";
                          tempOrder = "asc";
                        }
                        setStateSB(() {});
                      },
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedSort = tempSort;
                            sortOrder = tempOrder;
                            if (_tabController.index == 0) {
                              _applySortToLedgers();
                              _calculateTotalAmount();
                            } else {
                              _applySortToGroups();
                              _calculateGroupTotalAmount();
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Apply Sort",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required String? order,
    required VoidCallback onTap,
  }) {
    String getOrderText() {
      if (title == "Party Name") {
        return order == "asc" ? "(A to Z)" : "(Z to A)";
      } else {
        return order == "asc" ? "(Low to High)" : "(High to Low)";
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? AppColors.primaryColor : Colors.black87,
                    ),
                  ),
                  if (isSelected && order != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      getOrderText(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              order == "asc"
                  ? Icon(
                    Icons.arrow_downward,
                    color: AppColors.primaryColor,
                    size: 20,
                  )
                  : Icon(
                    Icons.arrow_upward,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    String field = "";
    if (selectedSort == "name")
      field = "Party Name";
    else if (selectedSort == "amount")
      field = "Amount";
    else
      field = "Avg Pay Days";

    String order = sortOrder == "asc" ? "Low to High" : "High to Low";
    if (selectedSort == "name")
      order = sortOrder == "asc" ? "A to Z" : "Z to A";

    return "$field ($order)";
  }

  Future<void> _shareAsPDF() async {
    setState(() => _isLoading = true);

    try {
      // Convert DateTime to dd/MM/yyyy format for API
      String fromDateStr = DateFormat('dd/MM/yyyy').format(fromDate);
      String toDateStr = DateFormat('dd/MM/yyyy').format(toDate);

      // Get selected ledger keys (for current filter)
      List<String> ledgerKeys = [];
      if (_tabController.index == 0) {
        // For Ledgers tab, get ledger keys from filtered ledgers
        ledgerKeys =
            _filteredLedgers
                .map((ledger) => ledger['ledKey'].toString())
                .toList();
      } else {
        // For Groups tab, get all ledger keys from bills in filtered groups
        Set<String> uniqueLedgerKeys = {};
        for (var group in _filteredGroups) {
          for (var bill in group['bills']) {
            uniqueLedgerKeys.add(bill['Led_Key'].toString());
          }
        }
        ledgerKeys = uniqueLedgerKeys.toList();
      }

      // Determine report type based on current tab
      String reportType = _tabController.index == 0 ? 'summary' : 'detail';

      // Determine if age wise (for groups tab we can set ageWise to true)
      bool isAgeWise = _tabController.index == 1;

      // Determine if overdue only (based on selected filter)
      bool isOverdueOnly =
          _selectedFilter != 'All' &&
          _selectedFilter != 'Not Due' &&
          _selectedFilter != 'Custom';

      debugPrint('From Date: $fromDateStr');
      debugPrint('To Date: $toDateStr');
      debugPrint('Ledger Keys: $ledgerKeys');
      debugPrint('Report Type: $reportType');
      debugPrint('Overdue Only: $isOverdueOnly');
      debugPrint('Age Wise: $isAgeWise');

      // Call the API to generate PDF
      final pdfBytes = await AccountReportService.generateReceivableReport(
        fromDate: fromDateStr,
        toDate: toDateStr,
        ledgerKeys: ledgerKeys,
        reportType: reportType,
        isOverdueOnly: isOverdueOnly,
        isAgeWise: isAgeWise,
      );

      if (pdfBytes != null && mounted) {
        final path = await AccountReportService.savePdfToTemp(
          pdfBytes,
          'Receivable_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        // Get subtitle for the PDF viewer
        String subtitle = _getPdfSubtitle(reportType, isOverdueOnly, isAgeWise);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => CommonPdfViewer(
                  pdfPath: path,
                  title: 'Receivable Report',
                  subtitle: subtitle,
                  fromDate: fromDateStr,
                  toDate: toDateStr,
                  reportType: reportType,
                ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getPdfSubtitle(
    String reportType,
    bool isOverdueOnly,
    bool isAgeWise,
  ) {
    List<String> parts = [];

    if (_selectedLedgersCount > 0) {
      parts.add('${_selectedLedgersCount} Ledger(s)');
    }
    if (reportType == 'detail') {
      parts.add('Detailed');
    }
    if (isOverdueOnly) {
      parts.add('Overdue Only');
    }
    if (isAgeWise) {
      parts.add('Age Wise');
    }

    if (parts.isEmpty) {
      return 'All Receivables';
    }
    return parts.join(' • ');
  }

  // Add this to track selected ledgers count (you may need to modify based on your filter)
  int get _selectedLedgersCount {
    if (_tabController.index == 0) {
      return _filteredLedgers.length;
    } else {
      // For groups, count unique ledgers
      Set<String> uniqueLedgers = {};
      for (var group in _filteredGroups) {
        for (var bill in group['bills']) {
          uniqueLedgers.add(bill['Led_Key'].toString());
        }
      }
      return uniqueLedgers.length;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await OutstandingService.getOutstandingReceivableBills();
      setState(() {
        _billsData = data;
        _groupAndCalculateLedgers();
        _groupByAccLGrpName();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  double _calculateAvgPayDays(List<Map<String, dynamic>> bills) {
    if (bills.isEmpty) return 0.0;
    int totalDays = 0;
    int validBills = 0;

    for (var bill in bills) {
      try {
        DateTime docDate = DateTime.parse(bill['Doc_Dt']);
        DateTime dueDate = DateTime.parse(bill['DueDt']);
        int daysDifference = dueDate.difference(docDate).inDays;
        if (daysDifference > 0) {
          totalDays += daysDifference;
          validBills++;
        }
      } catch (e) {
        print('Error parsing dates for bill: $e');
      }
    }
    return validBills > 0 ? totalDays / validBills : 0.0;
  }

  double _calculateCreditDays(List<Map<String, dynamic>> bills) {
    if (bills.isEmpty) return 0.0;
    int totalDays = 0;
    int validBills = 0;
    DateTime today = DateTime.now();

    for (var bill in bills) {
      try {
        DateTime dueDate = DateTime.parse(bill['DueDt']);
        if (dueDate.isBefore(today)) {
          int daysOverdue = today.difference(dueDate).inDays;
          totalDays += daysOverdue;
          validBills++;
        } else {
          validBills++;
        }
      } catch (e) {
        print('Error parsing dates for bill: $e');
      }
    }
    return validBills > 0 ? totalDays / validBills : 0.0;
  }

  void _groupAndCalculateLedgers() {
    Map<String, Map<String, dynamic>> ledgerMap = {};
    double total = 0;

    for (var bill in _billsData) {
      String ledKey = bill['Led_Key'];
      String ledName = bill['Led_Name'];
      double amount =
          bill['Amount'] is int
              ? (bill['Amount'] as int).toDouble()
              : bill['Amount'] as double;

      if (ledgerMap.containsKey(ledKey)) {
        double existingAmount = ledgerMap[ledKey]!['totalAmount'];
        ledgerMap[ledKey]!['totalAmount'] = existingAmount + amount;
        ledgerMap[ledKey]!['bills'].add(bill);
      } else {
        // Safely convert Credit_Limit to double
        double creditLimit = 0.0;
        var limitValue = bill['Credit_Limit'];
        if (limitValue != null) {
          if (limitValue is int) {
            creditLimit = limitValue.toDouble();
          } else if (limitValue is double) {
            creditLimit = limitValue;
          } else if (limitValue is String) {
            creditLimit = double.tryParse(limitValue) ?? 0.0;
          } else if (limitValue is num) {
            creditLimit = limitValue.toDouble();
          }
        }

        // Safely convert Credit_Period to int
        int creditPeriod = 0;
        var periodValue = bill['Credit_Period'];
        if (periodValue != null) {
          if (periodValue is int) {
            creditPeriod = periodValue;
          } else if (periodValue is double) {
            creditPeriod = periodValue.toInt();
          } else if (periodValue is String) {
            creditPeriod = int.tryParse(periodValue) ?? 0;
          } else if (periodValue is num) {
            creditPeriod = periodValue.toInt();
          }
        }

        ledgerMap[ledKey] = {
          'ledKey': ledKey,
          'ledName': ledName,
          'totalAmount': amount,
          'bills': [bill],
          'creditLimit': creditLimit,
          'creditPeriod': creditPeriod,
        };
      }
      total += amount;
    }

    _groupedLedgers =
        ledgerMap.values.map((ledger) {
          double avgPayDays = _calculateAvgPayDays(ledger['bills']);
          double creditDays = _calculateCreditDays(ledger['bills']);
          return {
            ...ledger,
            'avgPayDays': avgPayDays,
            'creditDays': creditDays,
          };
        }).toList();

    _filteredLedgers = List.from(_groupedLedgers);
    _originalTotalAmount = total;
    _totalAmount = total;
    _applySortToLedgers();
  }

  void _groupByAccLGrpName() {
    Map<String, Map<String, dynamic>> groupMap = {};
    double total = 0;

    for (var bill in _billsData) {
      String accLGrpName = bill['AccLGrp_Name'] ?? 'Uncategorized';
      double amount =
          bill['Amount'] is int
              ? (bill['Amount'] as int).toDouble()
              : bill['Amount'] as double;

      if (groupMap.containsKey(accLGrpName)) {
        double existingAmount = groupMap[accLGrpName]!['totalAmount'];
        groupMap[accLGrpName]!['totalAmount'] = existingAmount + amount;
        groupMap[accLGrpName]!['billCount'] =
            groupMap[accLGrpName]!['billCount'] + 1;
        groupMap[accLGrpName]!['bills'].add(bill);
      } else {
        groupMap[accLGrpName] = {
          'accLGrpName': accLGrpName,
          'totalAmount': amount,
          'billCount': 1,
          'bills': [bill],
        };
      }
      total += amount;
    }

    _groupedByAccLGrp =
        groupMap.values.map((group) {
          double avgPayDays = _calculateAvgPayDays(group['bills']);
          double creditDays = _calculateCreditDays(group['bills']);
          return {...group, 'avgPayDays': avgPayDays, 'creditDays': creditDays};
        }).toList();

    _filteredGroups = List.from(_groupedByAccLGrp);
    _originalGroupTotalAmount = total;
    _groupTotalAmount = total;
    _applySortToGroups();
  }

  double _originalTotalAmount = 0;
  double _originalGroupTotalAmount = 0;

  @override
  Widget build(BuildContext context) {
    final displayTotalAmount =
        _tabController.index == 0 ? _totalAmount : _groupTotalAmount;
    String dateRangeText =
        "${DateFormat('dd-MM-yyyy').format(fromDate)} ~ ${DateFormat('dd-MM-yyyy').format(toDate)}";

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        _tabController.index == 0
                            ? 'Search by ledger name...'
                            : 'Search by group name...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _closeSearch,
                    ),
                  ),
                )
                : Row(
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Outstanding Receivable",
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₹ ${displayTotalAmount.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (_selectedFilter != 'All')
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedFilter,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: _clearFilter,
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _toggleSearch,
                    ),
                    // Filter Icon Button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_alt, color: Colors.white),
                      onSelected: _applyFilter,
                      itemBuilder:
                          (context) =>
                              _filterOptions.map((filter) {
                                return PopupMenuItem(
                                  value: filter,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(filter),
                                      if (_selectedFilter == filter)
                                        Icon(
                                          Icons.check,
                                          size: 18,
                                          color: AppColors.primaryColor,
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      onPressed: _shareAsPDF,
                    ),
                    const SizedBox(width: 2),
                  ],
                ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: openDateFilterSheet,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateRangeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.sort_by_alpha,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: openSortSheet,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.only(right: 16),
                      indicatorColor: AppColors.primaryColor,
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: AppColors.slate600,
                      onTap: (index) {
                        setState(() {
                          _currentTabIndex = index;
                        });
                      },
                      tabs: const [Tab(text: "Ledgers"), Tab(text: "Group")],
                    ),
                  ),
                ),
                if (_currentTabIndex == 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () => _showGraphBottomSheet(context),
                      icon: const Icon(Icons.bar_chart),
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _filteredLedgers.isEmpty && _searchQuery.isNotEmpty
                    ? _buildNoResultsWidget()
                    : _ledgerList(),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _filteredGroups.isEmpty && _searchQuery.isNotEmpty
                    ? _buildNoResultsWidget()
                    : _groupList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.slate600),
          const SizedBox(height: 16),
          Text(
            "No results found",
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.slate600),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _clearFilter,
            child: Text(
              "Clear Filter",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    DateTime now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')} ${_getMonthAbbreviation(now.month)} ${now.year.toString().substring(2)}";
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _ledgerList() {
    return ListView.separated(
      itemCount: _filteredLedgers.length,
      separatorBuilder:
          (_, __) => Divider(
            height: 0.5,
            thickness: 0.3,
            color: AppColors.slateBorder,
          ),
      itemBuilder: (context, index) {
        final item = _filteredLedgers[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OutstandingReceivableDetailPage(
                      ledgerName: item['ledName'],
                      bills: item['bills'],
                      totalAmount: item['totalAmount'],
                    ),
              ),
            );
          },
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isSearching && _searchQuery.isNotEmpty
                          ? RichText(
                            text: _buildHighlightedText(
                              item['ledName'],
                              _searchQuery,
                            ),
                          )
                          : Text(
                            item['ledName'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                size: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "Credit: ${(item['creditLimit'] ?? 0).toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "|",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${(item['creditPeriod'] ?? 0)} days",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹ ${(item['totalAmount'] as double).toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "avg.pay: ${(item['avgPayDays'] as double).toStringAsFixed(0)} days",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _groupList() {
    return ListView.separated(
      itemCount: _filteredGroups.length,
      separatorBuilder:
          (_, __) => Divider(
            height: 0.5,
            thickness: 0.3,
            color: AppColors.slateBorder,
          ),
      itemBuilder: (context, index) {
        final item = _filteredGroups[index];

        // Get credit period and limit from the first bill of the group
        int creditPeriod = 0;
        double creditLimit = 0.0;

        if (item['bills'].isNotEmpty) {
          var firstBill = item['bills'][0];

          // Get credit period
          var periodValue = firstBill['Credit_Period'];
          if (periodValue != null) {
            if (periodValue is int) {
              creditPeriod = periodValue;
            } else if (periodValue is double) {
              creditPeriod = periodValue.toInt();
            } else if (periodValue is String) {
              creditPeriod = int.tryParse(periodValue) ?? 0;
            } else if (periodValue is num) {
              creditPeriod = periodValue.toInt();
            }
          }

          // Get credit limit
          var limitValue = firstBill['Credit_Limit'];
          if (limitValue != null) {
            if (limitValue is int) {
              creditLimit = limitValue.toDouble();
            } else if (limitValue is double) {
              creditLimit = limitValue;
            } else if (limitValue is String) {
              creditLimit = double.tryParse(limitValue) ?? 0.0;
            } else if (limitValue is num) {
              creditLimit = limitValue.toDouble();
            }
          }
        }

        return Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isSearching && _searchQuery.isNotEmpty
                        ? RichText(
                          text: _buildHighlightedText(
                            item['accLGrpName'],
                            _searchQuery,
                          ),
                        )
                        : Text(
                          item['accLGrpName'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              size: 12,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "Credit: ${creditLimit.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "|",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$creditPeriod days",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹ ${(item['totalAmount'] as double).toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "avg.pay: ${(item['avgPayDays'] as double).toStringAsFixed(0)} days",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  TextSpan _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text);

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int index;

    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
          ),
        ),
      );

      start = index + query.length;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  void _showGraphBottomSheet(BuildContext context) {
    final dataToShow =
        _tabController.index == 0 ? _filteredLedgers : _filteredGroups;

    if (dataToShow.isEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return SafeArea(
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slateBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Icon(Icons.bar_chart, size: 60, color: AppColors.slateBorder),
                  const SizedBox(height: 16),
                  Text(
                    "No data available",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // For Ledgers Tab - Show message that graph is disabled
    if (_tabController.index == 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return SafeArea(
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slateBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Icon(Icons.bar_chart, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "Graph Disabled for Ledgers",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please switch to Groups tab to view analysis",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    // For Groups Tab - Show Ageing Analysis
    // Calculate ageing data from all bills in groups
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    Map<String, double> ageingData = {
      'No Due': 0.0,
      '0-30': 0.0,
      '31-60': 0.0,
      '61-90': 0.0,
      '91-120': 0.0,
      '120+': 0.0,
    };

    // Collect all bills from all groups
    for (var group in _filteredGroups) {
      List<Map<String, dynamic>> bills = group['bills'] ?? [];
      for (var bill in bills) {
        DateTime dueDate;
        try {
          dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
          dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        } catch (e) {
          continue;
        }

        int daysDifference = today.difference(dueDate).inDays;
        double amount =
            bill['Amount'] is int
                ? (bill['Amount'] as int).toDouble()
                : bill['Amount'] as double;

        if (daysDifference < 0) {
          ageingData['No Due'] = ageingData['No Due']! + amount;
        } else if (daysDifference <= 30) {
          ageingData['0-30'] = ageingData['0-30']! + amount;
        } else if (daysDifference <= 60) {
          ageingData['31-60'] = ageingData['31-60']! + amount;
        } else if (daysDifference <= 90) {
          ageingData['61-90'] = ageingData['61-90']! + amount;
        } else if (daysDifference <= 120) {
          ageingData['91-120'] = ageingData['91-120']! + amount;
        } else {
          ageingData['120+'] = ageingData['120+']! + amount;
        }
      }
    }

    // Get max value for chart scaling
    double maxValue = ageingData.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 1;

    // Define different colors for each ageing bucket
    final List<Color> barColors = [
      Colors.green, // No Due
      Colors.lightGreen, // 0-30
      Colors.amber, // 31-60
      Colors.orange, // 61-90
      Colors.deepOrange, // 91-120
      Colors.red, // 120+
    ];

    final List<String> ageingLabels = [
      'No Due',
      '0-30',
      '31-60',
      '61-90',
      '91-120',
      '120+',
    ];

    final List<double> ageingValues = [
      ageingData['No Due']!,
      ageingData['0-30']!,
      ageingData['31-60']!,
      ageingData['61-90']!,
      ageingData['91-120']!,
      ageingData['120+']!,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slateBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Ageing Analysis",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bar Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 280,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxValue * 1.1,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 70,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '₹${NumberFormat('#,##,###').format(value.toInt())}',
                                        style: GoogleFonts.poppins(fontSize: 9),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < ageingLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            ageingLabels[value.toInt()],
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(ageingValues.length, (
                                index,
                              ) {
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: ageingValues[index],
                                      color: barColors[index],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                );
                              }),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: maxValue / 4,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: AppColors.lightGray,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Legend
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(ageingLabels.length, (index) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: barColors[index],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ageingLabels[index],
                                  style: GoogleFonts.poppins(fontSize: 10),
                                ),
                              ],
                            );
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Total Outstanding Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Outstanding",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              Text(
                                "₹ ${NumberFormat('#,##,###.##').format(_groupTotalAmount)}",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Date Filter Sheet for Outstanding Receivable (UI Only)
class DateFilterSheetForOutstanding extends StatelessWidget {
  final DateTime currentFromDate;
  final DateTime currentToDate;
  final Function(DateTime, DateTime) onApply;

  DateFilterSheetForOutstanding({
    super.key,
    required this.currentFromDate,
    required this.currentToDate,
    required this.onApply,
  });

  final DateTime now = DateTime.now();

  List<Map<String, String>> get presetFilters {
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    DateTime endOfLastMonth = DateTime(now.year, now.month, 0);
    DateTime startOfQuarter = DateTime(
      now.year,
      ((now.month - 1) ~/ 3) * 3 + 1,
      1,
    );
    DateTime startOfYear = DateTime(now.year, 1, 1);
    DateTime startOfLastYear = DateTime(now.year - 1, 1, 1);
    DateTime endOfLastYear = DateTime(now.year - 1, 12, 31);
    DateTime fyStart =
        now.month >= 4
            ? DateTime(now.year, 4, 1)
            : DateTime(now.year - 1, 4, 1);
    DateTime fyEnd = fyStart.add(const Duration(days: 365));

    return [
      {
        "label":
            "Financial Year (${DateFormat('yyyy').format(fyStart)}-${DateFormat('yy').format(fyEnd)})",
        "from": DateFormat('yyyy-MM-dd').format(fyStart),
        "to": DateFormat('yyyy-MM-dd').format(fyEnd),
      },
      {
        "label": "Today",
        "from": DateFormat('yyyy-MM-dd').format(today),
        "to": DateFormat('yyyy-MM-dd').format(today),
      },
      {
        "label": "Yesterday",
        "from": DateFormat(
          'yyyy-MM-dd',
        ).format(today.subtract(const Duration(days: 1))),
        "to": DateFormat(
          'yyyy-MM-dd',
        ).format(today.subtract(const Duration(days: 1))),
      },
      {
        "label": "This Week",
        "from": DateFormat('yyyy-MM-dd').format(startOfWeek),
        "to": DateFormat('yyyy-MM-dd').format(today),
      },
      {
        "label": "This Month",
        "from": DateFormat('yyyy-MM-dd').format(startOfMonth),
        "to": DateFormat('yyyy-MM-dd').format(today),
      },
      {
        "label": "Last Month",
        "from": DateFormat('yyyy-MM-dd').format(startOfLastMonth),
        "to": DateFormat('yyyy-MM-dd').format(endOfLastMonth),
      },
      {
        "label": "This Quarter",
        "from": DateFormat('yyyy-MM-dd').format(startOfQuarter),
        "to": DateFormat('yyyy-MM-dd').format(today),
      },
      {
        "label": "This Year",
        "from": DateFormat('yyyy-MM-dd').format(startOfYear),
        "to": DateFormat('yyyy-MM-dd').format(today),
      },
      {
        "label": "Last Year",
        "from": DateFormat('yyyy-MM-dd').format(startOfLastYear),
        "to": DateFormat('yyyy-MM-dd').format(endOfLastYear),
      },
      {"label": "Custom Date", "from": "", "to": ""},
    ];
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    DateTime? from = await showDatePicker(
      context: context,
      helpText: "Select From Date",
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (from == null) return;
    DateTime? to = await showDatePicker(
      context: context,
      helpText: "Select To Date",
      initialDate: from,
      firstDate: from,
      lastDate: DateTime(2100),
    );
    if (to == null) return;
    onApply(from, to);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Duration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Current Date: ${DateFormat('dd-MM-yyyy').format(now)}"),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: presetFilters.length,
                itemBuilder: (context, index) {
                  final filter = presetFilters[index];
                  return ListTile(
                    title: Text(filter["label"]!),
                    onTap: () {
                      if (filter["label"] == "Custom Date") {
                        _pickCustomDate(context);
                      } else {
                        DateTime from = DateTime.parse(filter["from"]!);
                        DateTime to = DateTime.parse(filter["to"]!);
                        onApply(from, to);
                        Navigator.pop(context);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
