import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
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
  
  // Search variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void _filterLedgers() {
    if (_searchQuery.isEmpty) {
      _filteredLedgers = List.from(_groupedLedgers);
    } else {
      _filteredLedgers = _groupedLedgers.where((ledger) {
        final ledgerName = ledger['ledName'].toString().toLowerCase();
        return ledgerName.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    _calculateTotalAmount();
  }

  void _filterGroups() {
    if (_searchQuery.isEmpty) {
      _filteredGroups = List.from(_groupedByAccLGrp);
    } else {
      _filteredGroups = _groupedByAccLGrp.where((group) {
        final groupName = group['accLGrpName'].toString().toLowerCase();
        return groupName.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    _calculateGroupTotalAmount();
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
        ledgerMap[ledKey] = {
          'ledKey': ledKey,
          'ledName': ledName,
          'totalAmount': amount,
          'bills': [bill],
        };
      }
      total += amount;
    }

    _groupedLedgers = ledgerMap.values.toList();
    _filteredLedgers = List.from(_groupedLedgers);
    _originalTotalAmount = total;
    _totalAmount = total;
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
        groupMap[accLGrpName]!['billCount'] = groupMap[accLGrpName]!['billCount'] + 1;
      } else {
        groupMap[accLGrpName] = {
          'accLGrpName': accLGrpName,
          'totalAmount': amount,
          'billCount': 1,
        };
      }
      total += amount;
    }

    _groupedByAccLGrp = groupMap.values.toList();
    _filteredGroups = List.from(_groupedByAccLGrp);
    _originalGroupTotalAmount = total;
    _groupTotalAmount = total;
  }

  double _originalTotalAmount = 0;
  double _originalGroupTotalAmount = 0;

  @override
  Widget build(BuildContext context) {
    // Determine which total amount to show based on current tab
    final displayTotalAmount = _tabController.index == 0 ? _totalAmount : _groupTotalAmount;

    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: _tabController.index == 0 
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
                  const SizedBox(width: 8),
                  Text(
                    "Outstanding Receivable",
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _toggleSearch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () {
                      // Filter functionality
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
      ),
      body: Column(
        children: [
          // Amount and Date
          Container(
            width: double.infinity,
            color: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  "₹ ${displayTotalAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "as of ${_getCurrentDate()}",
                  style: GoogleFonts.poppins(
                    color: AppColors.lightGray,
                    fontSize: 12,
                  ),
                ),
                if (_isSearching && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${_tabController.index == 0 ? _filteredLedgers.length : _filteredGroups.length} results",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tabs
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
                          // Update total when tab changes
                        });
                      },
                      tabs: const [Tab(text: "Ledgers"), Tab(text: "Group")],
                    ),
                  ),
                ),
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

          // Content
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
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.slate600,
          ),
          const SizedBox(height: 16),
          Text(
            "No results found for '$_searchQuery'",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _closeSearch,
            child: Text(
              "Clear search",
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
                      // Highlight matching text in search results
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
                      const SizedBox(height: 4),
                      Text(
                        "${item['bills'].length} bills",
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
                      "₹ ${(item['totalAmount'] as double).toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
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

        return Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Highlight matching text in search results
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
                    const SizedBox(height: 4),
                    Text(
                      "${item['billCount']} bills",
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
                    "₹ ${(item['totalAmount'] as double).toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
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

  // Helper method to highlight search text
  TextSpan _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(text: text);
    }
    
    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index;
    
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      // Add normal text before match
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        );
      }
      
      // Add highlighted text
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
    
    // Add remaining text
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

  Widget _groupView() {
    return _groupList();
  }

void _showGraphBottomSheet(BuildContext context) {
  final dataToShow = _tabController.index == 0 ? _filteredLedgers : _filteredGroups;
  
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
                Text("No data available", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.slate600)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
    return;
  }
  
  // Prepare data
  final List<Map<String, dynamic>> chartData = [];
  double maxAmount = 0;
  
  for (var item in dataToShow) {
    final name = _tabController.index == 0 ? item['ledName'] : item['accLGrpName'];
    final amount = item['totalAmount'] as double;
    if (amount > maxAmount) maxAmount = amount;
    chartData.add({'name': name, 'amount': amount});
  }
  
  final totalAmount = _tabController.index == 0 ? _totalAmount : _groupTotalAmount;
  
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slateBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _tabController.index == 0 ? "Ledger Analysis" : "Group Analysis",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Total: ₹ ${totalAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Simple Bar Graph
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(chartData.length, (index) {
                      final data = chartData[index];
                      final name = data['name'];
                      final amount = data['amount'];
                      final percentage = totalAmount > 0 ? (amount / totalAmount * 100) : 0;
                      final barWidth = maxAmount > 0 ? (amount / maxAmount) * (MediaQuery.of(context).size.width - 120) : 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name and Percentage Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // Bar with Amount
                            Stack(
                              children: [
                                Container(
                                  height: 32,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.slateBorder.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                Container(
                                  height: 32,
                                  width: barWidth,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  top: 7,
                                  child: Text(
                                    "₹ ${amount.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Legend
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 6),
                    Text("Amount", style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600)),
                    const SizedBox(width: 20),
                    Icon(Icons.percent, size: 12, color: AppColors.slate600),
                    const SizedBox(width: 6),
                    Text("Percentage", style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}
}