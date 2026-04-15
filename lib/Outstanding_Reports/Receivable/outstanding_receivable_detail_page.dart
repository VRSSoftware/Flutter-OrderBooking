import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/Outstanding_Reports/Receivable/bill_detail_page.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class OutstandingReceivableDetailPage extends StatefulWidget {
  final String ledgerName;
  final List<Map<String, dynamic>> bills;
  final double totalAmount;
  final Map<String, dynamic>? customerDetails;

  const OutstandingReceivableDetailPage({
    super.key,
    required this.ledgerName,
    required this.bills,
    required this.totalAmount,
    this.customerDetails,
  });

  @override
  State<OutstandingReceivableDetailPage> createState() =>
      _OutstandingReceivableDetailPageState();
}

class _OutstandingReceivableDetailPageState
    extends State<OutstandingReceivableDetailPage> {
  bool _isSelectionMode = false;
  Set<int> _selectedIndexes = {};
  double _selectedTotalAmount = 0;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredBills = [];

  // Sort variables
  String _selectedSort = 'due_days_high_low';

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
    '180',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTotalAmount = widget.totalAmount;
    _filteredBills = List.from(widget.bills);
    _applySort(_selectedSort);
  }

  void _applySort(String sortOption) {
    setState(() {
      _selectedSort = sortOption;
      List<Map<String, dynamic>> sortedList = List.from(_filteredBills);

      switch (sortOption) {
        case 'due_days_high_low':
          sortedList.sort((a, b) => _getDueDays(b).compareTo(_getDueDays(a)));
          break;
        case 'due_days_low_high':
          sortedList.sort((a, b) => _getDueDays(a).compareTo(_getDueDays(b)));
          break;
        case 'amount_high_low':
          sortedList.sort((a, b) => _getAmount(b).compareTo(_getAmount(a)));
          break;
        case 'amount_low_high':
          sortedList.sort((a, b) => _getAmount(a).compareTo(_getAmount(b)));
          break;
        case 'name_desc':
          sortedList.sort(
            (a, b) => b['Vchr_Type']?.compareTo(a['Vchr_Type'] ?? '') ?? 0,
          );
          break;
        case 'name_asc':
          sortedList.sort(
            (a, b) => a['Vchr_Type']?.compareTo(b['Vchr_Type'] ?? '') ?? 0,
          );
          break;
      }

      _filteredBills = sortedList;
    });
  }

  int _getDueDays(Map<String, dynamic> bill) {
    try {
      DateTime dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
      DateTime today = DateTime.now();
      return today.difference(dueDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  int _getDaysBetween(Map<String, dynamic> bill) {
    try {
      DateTime docDate = DateTime.parse(bill['Doc_Dt']);
      DateTime dueDate = DateTime.parse(bill['DueDt']);
      return dueDate.difference(docDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  double _getAmount(Map<String, dynamic> bill) {
    return bill['Amount'] is int
        ? (bill['Amount'] as int).toDouble()
        : bill['Amount'] as double;
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Custom') {
        _showDateRangePicker();
        return;
      }
      _filterBills(filter);
      _applySort(_selectedSort);
    });
  }

  void _filterBills(String filter) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    _filteredBills =
        widget.bills.where((bill) {
          DateTime dueDate;
          try {
            dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
            dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
          } catch (e) {
            return false;
          }

          int daysDifference = today.difference(dueDate).inDays;

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
            case '180':
              return daysDifference > 180;
            default:
              return true;
          }
        }).toList();

    _calculateFilteredTotal();
  }

  void _calculateFilteredTotal() {
    double total = 0;
    for (var bill in _filteredBills) {
      total += _getAmount(bill);
    }
    _selectedTotalAmount = total;
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
        _filteredBills =
            widget.bills.where((bill) {
              DateTime dueDate;
              try {
                dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
              } catch (e) {
                return false;
              }
              return dueDate.isAfter(picked.start) &&
                  dueDate.isBefore(picked.end);
            }).toList();
        _calculateFilteredTotal();
        _applySort(_selectedSort);
      });
    } else {
      _filterBills('All');
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIndexes.clear();
        _selectedTotalAmount = widget.totalAmount;
        _filteredBills = List.from(widget.bills);
        _selectedFilter = 'All';
        _applySort(_selectedSort);
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      double amount = _getAmount(_filteredBills[index]);

      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
        _selectedTotalAmount += amount;
      } else {
        _selectedIndexes.add(index);
        _selectedTotalAmount -= amount;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIndexes.clear();
      _selectedTotalAmount = 0;
      for (int i = 0; i < _filteredBills.length; i++) {
        _selectedIndexes.add(i);
        _selectedTotalAmount -= _getAmount(_filteredBills[i]);
      }
    });
  }

  void _showCustomerInformation() {
    final customer =
        widget.customerDetails ??
        (widget.bills.isNotEmpty ? widget.bills[0] : null);

    if (customer == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.slateBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            customer['Led_Name'] ?? widget.ledgerName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          _buildInfoCard(
                            icon: Icons.business,
                            label: "Contact Name",
                            value: customer['Co_Name'] ?? '',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.category,
                            label: "Group",
                            value: customer['PartyGrp_Key'] ?? '',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.location_on,
                            label: "Address",
                            value: customer['OAddr'] ?? '',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.phone,
                            label: "Mobile",
                            value: customer['Mobile1'] ?? '',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.account_balance,
                            label: "GST No",
                            value: customer['GSTNo'] ?? '',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slateBorder.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "—" : value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLedgerReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ledger Report - Coming Soon')),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not call $phoneNumber')));
    }
  }

  String _formatDate(String dateTimeStr) {
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.day} ${_getMonthAbbreviation(dateTime.month)} ${dateTime.year}";
    } catch (e) {
      return dateTimeStr;
    }
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

  // Calculate oldest bill due date
  String _getOldestBillDue() {
    if (_filteredBills.isEmpty) return 'No bills';

    DateTime oldestDate = DateTime.now();
    for (var bill in _filteredBills) {
      try {
        DateTime dueDate = DateTime.parse(
          bill['DueDt'] ?? bill['Doc_Dt'] ?? '',
        );
        if (dueDate.isBefore(oldestDate)) {
          oldestDate = dueDate;
        }
      } catch (e) {
        continue;
      }
    }
    return _formatDate(oldestDate.toIso8601String());
  }

  // Calculate average pay days (current year)
  double _calculateAvgPayDaysCY() {
    if (_filteredBills.isEmpty) return 0.0;

    int currentYear = DateTime.now().year;
    int totalDays = 0;
    int validBills = 0;

    for (var bill in _filteredBills) {
      try {
        DateTime docDate = DateTime.parse(bill['Doc_Dt']);
        DateTime dueDate = DateTime.parse(bill['DueDt']);

        // Only count bills from current year
        if (docDate.year == currentYear) {
          int daysDifference = dueDate.difference(docDate).inDays;
          if (daysDifference > 0) {
            totalDays += daysDifference;
            validBills++;
          }
        }
      } catch (e) {
        continue;
      }
    }

    return validBills > 0 ? totalDays / validBills : 0.0;
  }

  String _getCreditLimit() {
    final customer =
        widget.customerDetails ??
        (widget.bills.isNotEmpty ? widget.bills[0] : null);
    if (customer != null && customer['Credit_Limit'] != null) {
      double creditLimit =
          customer['Credit_Limit'] is int
              ? (customer['Credit_Limit'] as int).toDouble()
              : customer['Credit_Limit'] as double;
      return "₹ ${creditLimit.toStringAsFixed(2)}";
    }
    return "Not set";
  }

  @override
  Widget build(BuildContext context) {
    final customer =
        widget.customerDetails ??
        (widget.bills.isNotEmpty ? widget.bills[0] : null);
    final phoneNumber = customer?['Mobile1']?.toString() ?? '';
    double avgPayDaysCY = _calculateAvgPayDaysCY();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.ledgerName,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          // Sort PopupMenuButton
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: _applySort,
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'due_days_high_low',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedSort == 'due_days_high_low',
                          onChanged: null,
                          activeColor: AppColors.primaryColor,
                        ),
                        const Text('Due Days (High → Low)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'due_days_low_high',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedSort == 'due_days_low_high',
                          onChanged: null,
                          activeColor: AppColors.primaryColor,
                        ),
                        const Text('Due Days (Low → High)'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'amount_high_low',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedSort == 'amount_high_low',
                          onChanged: null,
                          activeColor: AppColors.primaryColor,
                        ),
                        const Text('Amount (High → Low)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'amount_low_high',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedSort == 'amount_low_high',
                          onChanged: null,
                          activeColor: AppColors.primaryColor,
                        ),
                        const Text('Amount (Low → High)'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'name_desc',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedSort == 'name_desc',
                          onChanged: null,
                          activeColor: AppColors.primaryColor,
                        ),
                        const Text('Name (Z → A)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'name_asc',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _selectedSort == 'name_asc',
                          onChanged: null,
                          activeColor: AppColors.primaryColor,
                        ),
                        const Text('Name (A → Z)'),
                      ],
                    ),
                  ),
                ],
          ),
          // Filter PopupMenuButton
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: _applyFilter,
            itemBuilder:
                (context) =>
                    _filterOptions.map((filter) {
                      return PopupMenuItem(
                        value: filter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          // More options PopupMenuButton
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'customer_info') {
                _showCustomerInformation();
              } else if (value == 'ledger_report') {
                _showLedgerReport();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'customer_info',
                    child: Text('Customer Information'),
                  ),
                  const PopupMenuItem(
                    value: 'ledger_report',
                    child: Text('Ledger Report'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Amount Section - Single Row
          Container(
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₹ ${_selectedTotalAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "as of ${_getCurrentDate()}",
                  style: GoogleFonts.poppins(
                    color: AppColors.lightGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Summary Cards Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "Oldest Bill Due",
                    value: _getOldestBillDue(),
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Credit Limit",
                    value: _getCreditLimit(),
                    icon: Icons.credit_card,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Avg.Pay CY",
                    value: "${avgPayDaysCY.toStringAsFixed(0)} days",
                    icon: Icons.timeline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Customer Action Row
          if (phoneNumber.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: InkWell(
                onTap: () => _makePhoneCall(phoneNumber),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "Customer has not paid? Call Customer",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Select/Graph Row (ORIGINAL - NOT CHANGED)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _toggleSelectionMode,
                  child: Text(
                    "Select",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          _isSelectionMode
                              ? AppColors.red
                              : AppColors.primaryColor,
                    ),
                  ),
                ),

                if (_isSelectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _selectAll,
                        child: Text(
                          "Select All",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _toggleSelectionMode,
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (_selectedFilter != 'All')
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _filterBills('All');
                        _applySort(_selectedSort);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFilter,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _showSimpleGraphBottomSheet(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.bar_chart,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.slateBorder,
          ),

          // Bills List
          Expanded(
            child:
                _filteredBills.isEmpty
                    ? Center(
                      child: Text(
                        "No bills found",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.slate600,
                        ),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredBills.length,
                      separatorBuilder:
                          (_, __) => const Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.slateBorder,
                          ),
                      itemBuilder: (context, index) {
                        final bill = _filteredBills[index];
                        String billNo = bill['Doc_No'] ?? '';
                        double amount = _getAmount(bill);
                        final isSelected = _selectedIndexes.contains(index);
                        int dueDays = _getDueDays(bill);
                        int daysBetween = _getDaysBetween(bill);

                        // Get dates
                        String docDateStr = _formatDate(bill['Doc_Dt'] ?? '');
                        String dueDateStr = _formatDate(bill['DueDt'] ?? '');

                        return GestureDetector(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(index);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BillDetailPage(
                                        bill: bill,
                                        ledgerName: widget.ledgerName,
                                      ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            color:
                                isSelected
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isSelectionMode) ...[
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSelection(index),
                                    activeColor: AppColors.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Bill Number
                                      Text(
                                        billNo,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Row: Doc Date | Days Between | Due Date
                                      Wrap(
                                        spacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            docDateStr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const Text(
                                            "|",
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "$dueDays days", // Changed from daysBetween to dueDays
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  dueDays > 0
                                                      ? Colors.red
                                                      : Colors
                                                          .orange, // Red if overdue, orange if not
                                            ),
                                          ),
                                          const Text(
                                            "|",
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            "due: $dueDateStr",
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
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
                                      "₹ ${amount.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blueGrey,
                                      ),
                                    ),

                                    // const SizedBox(height: 4),
                                    // Container(
                                    //   padding: const EdgeInsets.symmetric(
                                    //     horizontal: 6,
                                    //     vertical: 2,
                                    //   ),
                                    //   decoration: BoxDecoration(
                                    //     color: AppColors.primaryColor
                                    //         .withOpacity(0.1),
                                    //     borderRadius: BorderRadius.circular(4),
                                    //   ),
                                    //   child: Text(
                                    //     bill['Vchr_Type'] ?? 'Sales',
                                    //     style: GoogleFonts.poppins(
                                    //       fontSize: 10,
                                    //       color: AppColors.primaryColor,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showSimpleGraphBottomSheet(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    Map<String, double> data = {
      'No Due': 0.0,
      '0-30': 0.0,
      '31-60': 0.0,
      '61-90': 0.0,
      '91-120': 0.0,
      '120+': 0.0,
    };

    for (var bill in _filteredBills) {
      DateTime dueDate;
      try {
        dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
        dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
      } catch (e) {
        continue;
      }

      int daysDifference = today.difference(dueDate).inDays;
      double amount = _getAmount(bill);

      if (daysDifference < 0) {
        data['No Due'] = data['No Due']! + amount;
      } else if (daysDifference <= 30) {
        data['0-30'] = data['0-30']! + amount;
      } else if (daysDifference <= 60) {
        data['31-60'] = data['31-60']! + amount;
      } else if (daysDifference <= 90) {
        data['61-90'] = data['61-90']! + amount;
      } else if (daysDifference <= 120) {
        data['91-120'] = data['91-120']! + amount;
      } else {
        data['120+'] = data['120+']! + amount;
      }
    }

    // Get max value for chart scaling
    double maxValue = data.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 1;

    // Define different colors for each bar
    final List<Color> barColors = [
      Colors.green, // No Due
      Colors.pink, // 0-30
      Colors.amber, // 31-60
      Colors.purple, // 61-90
      Colors.deepOrange, // 91-120
      Colors.red, // 120+
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
                                      const titles = [
                                        'No Due',
                                        '0-30',
                                        '31-60',
                                        '61-90',
                                        '91-120',
                                        '120+',
                                      ];
                                      if (value.toInt() >= 0 &&
                                          value.toInt() < titles.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            titles[value.toInt()],
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
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['No Due']!,
                                      color: barColors[0],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['0-30']!,
                                      color: barColors[1],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 2,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['31-60']!,
                                      color: barColors[2],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 3,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['61-90']!,
                                      color: barColors[3],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 4,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['91-120']!,
                                      color: barColors[4],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 5,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data['120+']!,
                                      color: barColors[5],
                                      width: 40,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ],
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
                        // Legend with different colors
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildLegendItem('No Due', barColors[0]),
                            _buildLegendItem('0-30 Days', barColors[1]),
                            _buildLegendItem('31-60 Days', barColors[2]),
                            _buildLegendItem('61-90 Days', barColors[3]),
                            _buildLegendItem('91-120 Days', barColors[4]),
                            _buildLegendItem('120+ Days', barColors[5]),
                          ],
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
                                "₹ ${NumberFormat('#,##,###.##').format(_selectedTotalAmount)}",
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

  // Add this helper method inside the class
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
            ),
          ),
          Text(
            "₹ ${amount.toStringAsFixed(2)}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
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
}
