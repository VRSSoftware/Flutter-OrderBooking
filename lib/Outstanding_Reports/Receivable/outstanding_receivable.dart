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
  
  List<Map<String, dynamic>> _billsData = [];
  List<Map<String, dynamic>> _groupedLedgers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
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
      double amount = bill['Amount'] is int 
          ? (bill['Amount'] as int).toDouble() 
          : bill['Amount'] as double;

      if (ledgerMap.containsKey(ledKey)) {
        // Add to existing ledger
        double existingAmount = ledgerMap[ledKey]!['totalAmount'];
        ledgerMap[ledKey]!['totalAmount'] = existingAmount + amount;
        ledgerMap[ledKey]!['bills'].add(bill);
      } else {
        // Create new ledger
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
    _totalAmount = total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
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
            const Icon(Icons.search, color: Colors.white),
            const SizedBox(width: 12),
            const Icon(Icons.tune, color: Colors.white),
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
                  "₹ ${_totalAmount.toStringAsFixed(2)}",
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
                        : _ledgerList(),
                _groupView(),
              ],
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _ledgerList() {
    return ListView.separated(
      itemCount: _groupedLedgers.length,
      separatorBuilder: (_, __) => Divider(
        height: 0.5,
        thickness: 0.3,
        color: AppColors.slateBorder,
      ),
      itemBuilder: (context, index) {
        final item = _groupedLedgers[index];
        
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutstandingReceivableDetailPage(
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
                      Text(
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

  Widget _groupView() {
    return Center(child: Text("Group Data", style: GoogleFonts.poppins()));
  }

  void _showGraphBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          color: AppColors.white,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(height: 4, width: 40, color: AppColors.slateBorder),
              const SizedBox(height: 16),
              Container(
                height: 180,
                child: Center(
                  child: Icon(
                    Icons.bar_chart,
                    size: 60,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Divider(thickness: 0.3, color: AppColors.slateBorder),
              Expanded(child: _ledgerList()),
            ],
          ),
        );
      },
    );
  }
}