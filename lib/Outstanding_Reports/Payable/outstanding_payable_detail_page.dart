// outstanding_payable_detail_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/Outstanding_Reports/Payable/payable_bill_detail_page.dart';

import 'package:vrs_erp/constants/app_constants.dart';
import 'package:fl_chart/fl_chart.dart';

class OutstandingPayableDetailPage extends StatefulWidget {
  final String ledgerName;
  final List<Map<String, dynamic>> bills;
  final double totalAmount;
  final Map<String, dynamic>? customerDetails;

  const OutstandingPayableDetailPage({
    super.key,
    required this.ledgerName,
    required this.bills,
    required this.totalAmount,
    this.customerDetails,
  });

  @override
  State<OutstandingPayableDetailPage> createState() =>
      _OutstandingPayableDetailPageState();
}

class _OutstandingPayableDetailPageState
    extends State<OutstandingPayableDetailPage> {
  bool _isSelectionMode = false;
  Set<int> _selectedIndexes = {};
  double _selectedTotalAmount = 0;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _filteredBills = [];

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
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _selectedTotalAmount = widget.totalAmount;
    _filteredBills = List.from(widget.bills);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Custom') {
        _showDateRangePicker();
        return;
      }
      _filterBills(filter);
    });
  }

  void _filterBills(String filter) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    _filteredBills = widget.bills.where((bill) {
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
      double amount = bill['Amount'] is int
          ? (bill['Amount'] as int).toDouble()
          : bill['Amount'] as double;
      total += amount;
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
        _filteredBills = widget.bills.where((bill) {
          DateTime dueDate;
          try {
            dueDate = DateTime.parse(bill['DueDt'] ?? bill['Doc_Dt'] ?? '');
          } catch (e) {
            return false;
          }
          return dueDate.isAfter(picked.start) && dueDate.isBefore(picked.end);
        }).toList();
        _calculateFilteredTotal();
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
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      double amount = _filteredBills[index]['Amount'] is int
          ? (_filteredBills[index]['Amount'] as int).toDouble()
          : _filteredBills[index]['Amount'] as double;

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
        double amount = _filteredBills[i]['Amount'] is int
            ? (_filteredBills[i]['Amount'] as int).toDouble()
            : _filteredBills[i]['Amount'] as double;
        _selectedTotalAmount -= amount;
      }
    });
  }

  void _showCustomerInformation() {
    final customer = widget.customerDetails ?? (widget.bills.isNotEmpty ? widget.bills[0] : null);
    
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
                            label: "Vendor Name",
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: _applyFilter,
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem(
                value: filter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(filter),
                    if (_selectedFilter == filter)
                      Icon(Icons.check, size: 18, color: AppColors.primaryColor),
                  ],
                ),
              );
            }).toList(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'customer_info') {
                _showCustomerInformation();
              } else if (value == 'ledger_report') {
                _showLedgerReport();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'customer_info',
                child: Text('Vendor Information'),
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
          // Amount Section
          Container(
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹ ${_selectedTotalAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
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

          // Select/Graph Row
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
                      color: _isSelectionMode ? AppColors.red : AppColors.primaryColor,
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
                        _filteredBills = List.from(widget.bills);
                        _calculateFilteredTotal();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          const Icon(Icons.close, size: 14, color: AppColors.primaryColor),
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

          const Divider(height: 1, thickness: 0.5, color: AppColors.slateBorder),

          // Bills List with onTap navigation
          Expanded(
            child: _filteredBills.isEmpty
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
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: AppColors.slateBorder,
                    ),
                    itemBuilder: (context, index) {
                      final bill = _filteredBills[index];
                      String docNo = bill['Doc_No'] ?? '';
                      String docDt = bill['Doc_Dt'] ?? '';
                      double amount = bill['Amount'] is int
                          ? (bill['Amount'] as int).toDouble()
                          : bill['Amount'] as double;
                      final isSelected = _selectedIndexes.contains(index);

                      return GestureDetector(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(index);
                          } else {
                            // Navigate to bill detail page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PayableBillDetailPage(
                                  bill: bill,
                                  ledgerName: widget.ledgerName,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      docNo,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(docDt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.slate600,
                                      ),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bill['Vchr_Type'] ?? 'Purchase',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
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

void _showSimpleGraphBottomSheet(BuildContext context) {
  // Calculate data
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
    double amount = bill['Amount'] is int
        ? (bill['Amount'] as int).toDouble()
        : bill['Amount'] as double;
    
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
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
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
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSummaryRow("No Due", data['No Due'] ?? 0, Colors.green),
                      const SizedBox(height: 10),
                      _buildSummaryRow("0-30 Days", data['0-30'] ?? 0, Colors.orange),
                      const SizedBox(height: 10),
                      _buildSummaryRow("31-60 Days", data['31-60'] ?? 0, Colors.orange),
                      const SizedBox(height: 10),
                      _buildSummaryRow("61-90 Days", data['61-90'] ?? 0, Colors.red),
                      const SizedBox(height: 10),
                      _buildSummaryRow("91-120 Days", data['91-120'] ?? 0, Colors.red),
                      const SizedBox(height: 10),
                      _buildSummaryRow("120+ Days", data['120+'] ?? 0, Colors.red),
                      const SizedBox(height: 16),
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
                              "Total Payable",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            Text(
                              "₹ ${_selectedTotalAmount.toStringAsFixed(2)}",
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