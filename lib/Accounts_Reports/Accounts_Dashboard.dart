import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/Accounts_Reports/Ledger/Customer_Ac_BillWise/CustomerAcBillwise.dart';
import 'package:vrs_erp/Accounts_Reports/Ledger/Customer_Ledger/CustomerLedger.dart';
import 'package:vrs_erp/Accounts_Reports/OutstandingAnalysis/BalanceSheet/BalanceSheet.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Bank_Book/bank_book.dart';
import 'package:vrs_erp/Accounts_Reports/Misc_Report/Broker_Comm_Rcpt_Billwise/Broker_comm_Rcpt_Billwise.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Cash_Book/cash_book.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Group_Summary/group_summary.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Group_Voucher/group_voucher.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Ledger/ledger.dart';
import 'package:vrs_erp/Accounts_Reports/OutstandingAnalysis/Payable/payable.dart';
import 'package:vrs_erp/Accounts_Reports/OutstandingAnalysis/Profit_Loss/Profit_Loss.dart';
import 'package:vrs_erp/Accounts_Reports/OutstandingAnalysis/Receivables/receivables.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Trial_Balance/trial_balance.dart';
import 'package:vrs_erp/Accounts_Reports/Remainder/OutStanding_Remainder/OustandingRemainder.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/Accounts_Reports/AccountBook/Day_Book/day_book.dart';



class AccountDashboard extends StatefulWidget {
  const AccountDashboard({super.key});

  @override
  State<AccountDashboard> createState() => _AccountDashboardState();
}

class _AccountDashboardState extends State<AccountDashboard> {
  // List to store recently viewed items dynamically
  List<Map<String, dynamic>> recentlyViewedItems = [];

  // Search query
  String searchQuery = '';

  // Search mode flag
  bool isSearchMode = false;

  // Controller for search field
  final TextEditingController searchController = TextEditingController();

  // Speech to text
  stt.SpeechToText? _speech;
  bool _isListening = false;
  String _text = '';
  bool _speechAvailable = false;

  // All menu items for search functionality
  final List<Map<String, dynamic>> allMenuItems = [
    // Accounts Book Items
    {
      "title": "Cash Book",
      "icon": Icons.book,
      "category": "Accounts Book",
      "route": "/cashBook",
    },
    {
      "title": "Bank Book",
      "icon": Icons.account_balance,
      "category": "Accounts Book",
      "route": "/bankBook",
    },
    {
      "title": "Ledger",
      "icon": Icons.book,
      "category": "Accounts Book",
      "route": "/ledger",
    },
    {
      "title": "Customer Ledger",
      "icon": Icons.people,
      "category": "Ledger",
      "route": "/customerLedger",
    },
    {
      "title": "Customer A/c (Billwise)",
      "icon": Icons.receipt,
      "category": "Ledger",
      "route": "/customerBillwise",
    },
    {
      "title": "Group Summary",
      "icon": Icons.group_work,
      "category": "Accounts Book",
      "route": "/groupSummary",
    },
    {
      "title": "Group Voucher",
      "icon": Icons.receipt_long,
      "category": "Accounts Book",
      "route": "/groupVoucher",
    },
    {
      "title": "Day Book",
      "icon": Icons.menu_book,
      "category": "Accounts Book",
      "route": "/dayBook",
    },
    {
      "title": "Trial Balance",
      "icon": Icons.balance,
      "category": "Accounts Book",
      "route": "/trialBalance",
    },
    // Outstanding Analysis Items
    {
      "title": "Receivable",
      "icon": Icons.call_received,
      "category": "Outstanding Analysis",
      "route": "/receivable",
    },
    {
      "title": "Payable",
      "icon": Icons.call_made,
      "category": "Outstanding Analysis",
      "route": "/payable",
    },
    {
      "title": "Profit Loss",
      "icon": Icons.trending_up,
      "category": "Outstanding Analysis",
      "route": "/profitLoss",
    },
    {
      "title": "Balance Sheet",
      "icon": Icons.account_balance_wallet,
      "category": "Outstanding Analysis",
      "route": "/balanceSheet",
    },
    // Misc Report Items
    {
      "title": "Broker Commission Receipt (Bill Wise)",
      "icon": Icons.attach_money,
      "category": "Misc Report",
      "route": "/brokerCommission",
    },
    // Remainder Items
    {
      "title": "Outstanding Remainder",
      "icon": Icons.notifications_active,
      "category": "Remainder",
      "route": "/outstandingRemainder",
    },
  ];

  // Get filtered menu items based on search query
  List<Map<String, dynamic>> get filteredAccountsBookItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Accounts Book')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Accounts Book' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredOutstandingItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Outstanding Analysis')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Outstanding Analysis' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredLedgerItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Ledger')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Ledger' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredMiscReportItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Misc Report')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Misc Report' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<Map<String, dynamic>> get filteredRemainderItems {
    if (searchQuery.isEmpty) {
      return allMenuItems
          .where((item) => item['category'] == 'Remainder')
          .toList();
    }
    return allMenuItems
        .where(
          (item) =>
              item['category'] == 'Remainder' &&
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  // Check if any section has items to show
  bool get hasAccountsBookItems => filteredAccountsBookItems.isNotEmpty;
  bool get hasOutstandingItems => filteredOutstandingItems.isNotEmpty;
  bool get hasLedgerItems => filteredLedgerItems.isNotEmpty;
  bool get hasMiscReportItems => filteredMiscReportItems.isNotEmpty;
  bool get hasRemainderItems => filteredRemainderItems.isNotEmpty;
  bool get hasSearchResults => 
      hasAccountsBookItems || 
      hasOutstandingItems || 
      hasLedgerItems || 
      hasMiscReportItems || 
      hasRemainderItems;

  // Helper method to add item to recently viewed
  void addToRecentlyViewed(String title, IconData icon) {
    setState(() {
      // Remove if already exists
      recentlyViewedItems.removeWhere((item) => item['title'] == title);
      // Add to beginning of list
      recentlyViewedItems.insert(0, {'title': title, 'icon': icon});
      // Keep only last 10 items
      if (recentlyViewedItems.length > 10) {
        recentlyViewedItems.removeLast();
      }
    });
  }

  // Navigation method
  void navigateToPage(String route, String title, IconData icon) {
    addToRecentlyViewed(title, icon);

    // Close search mode if open
    if (isSearchMode) {
      closeSearchMode();
    }

    // Navigate based on route
    switch (route) {
      case '/cashBook':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CashBookPage()),
        );
        break;
      case '/bankBook':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BankBookPage()),
        );
        break;
      case '/ledger':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LedgerPage()),
        );
        break;
      case '/customerLedger':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerLedgerPage()),
        );
       break;
      case '/customerBillwise':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerAcBillwisePage()),
        );
        break;
      case '/groupSummary':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupSummaryPage()),
        );
        break;
      case '/groupVoucher':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupVoucherPage()),
        );
        break;
      case '/dayBook':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DayBookPage()),
        );
        break;
      case '/trialBalance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrialBalancePage()),
        );
        break;
      case '/receivable':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReceivablePage()),
        );
        break;
      case '/payable':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PayablePage()),
        );
        break;
      case '/profitLoss':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfitLossPage()),
        );
        break;
      case '/balanceSheet':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BalanceSheetPage()),
        );
        break;
      case '/brokerCommission':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BrokerCommissionReceiptPage()),
        );
        break;
      case '/outstandingRemainder':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OutstandingRemainderPage()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $title...'),
            duration: Duration(seconds: 1),
          ),
        );
    }
  }

  // Clear search
  void clearSearch() {
    setState(() {
      searchQuery = '';
      searchController.clear();
    });
  }

  // Close search mode
  void closeSearchMode() {
    setState(() {
      isSearchMode = false;
      searchQuery = '';
      searchController.clear();
      if (_isListening) {
        _stopListening();
      }
    });
  }

  // Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      status = await Permission.microphone.request();
      return status.isGranted;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }

  // Initialize speech to text
  Future<void> initSpeech() async {
    _speech = stt.SpeechToText();

    bool available = await _speech!.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'notAvailable') {
          setState(() {
            _speechAvailable = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
            ),
          );
        }
      },
      onError: (error) {
        print('Speech error: $error');
        setState(() {
          _isListening = false;
          _speechAvailable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: ${error.errorMsg}')),
        );
      },
    );

    setState(() {
      _speechAvailable = available;
    });

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  // Start listening
  Future<void> _startListening() async {
    bool hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission required for voice search'),
        ),
      );
      return;
    }

    if (_speech == null || !_speechAvailable) {
      await initSpeech();
    }

    if (_speech != null && _speechAvailable) {
      bool isListening = await _speech!.listen(
        onResult: (result) {
          print('Result: ${result.recognizedWords}');
          setState(() {
            _text = result.recognizedWords;
            searchQuery = _text;
            searchController.text = _text;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'en_US',
        onSoundLevelChange: (level) {},
      );

      setState(() {
        _isListening = isListening;
      });

      if (!isListening) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start speech recognition')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not ready')),
      );
    }
  }

  // Stop listening
  void _stopListening() {
    if (_speech != null) {
      _speech!.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initSpeech();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    if (_speech != null) {
      _speech!.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            !isSearchMode
                ? const Text(
                  "All Reports",
                  style: TextStyle(color: Colors.white),
                )
                : Container(
                  height: 40,
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search reports...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: clearSearch,
                            ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening ? Colors.red : Colors.grey,
                            ),
                            onPressed:
                                _isListening ? _stopListening : _startListening,
                          ),
                        ],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
        actions: [
          if (!isSearchMode)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  isSearchMode = true;
                });
              },
            ),
          if (isSearchMode)
            TextButton(
              onPressed: closeSearchMode,
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (recentlyViewedItems.isNotEmpty && searchQuery.isEmpty)
                      _buildRecentlyViewed(),

                    if (searchQuery.isNotEmpty && !hasSearchResults)
                      _buildNoResultsFound(),

                    if (hasAccountsBookItems) _buildAccountsBook(),
                    
                    if (hasLedgerItems) _buildLedgerSection(),
                    
                    if (hasOutstandingItems) _buildOutstandingAnalysis(),
                    
                    if (hasMiscReportItems) _buildMiscReportSection(),
                    
                    if (hasRemainderItems) _buildRemainderSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No Results Found Widget
  Widget _buildNoResultsFound() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No results found for '$searchQuery'",
            style: TextStyle(fontSize: 16, color: AppColors.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Try searching with different keywords",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🕘 Recently Viewed (Dynamic based on user interaction)
  Widget _buildRecentlyViewed() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recently Viewed",
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyViewedItems.length,
              itemBuilder: (context, index) {
                final item = recentlyViewedItems[index];
                return GestureDetector(
                  onTap: () {
                    // Find the route for this item
                    final menuItem = allMenuItems.firstWhere(
                      (menu) => menu['title'] == item['title'],
                      orElse: () => {'route': ''},
                    );
                    navigateToPage(
                      menuItem['route'],
                      item['title'],
                      item['icon'],
                    );
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.veryLightGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item['icon'],
                            color: AppColors.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  // 📘 Accounts Book
  Widget _buildAccountsBook() {
    return _buildSection(
      title: "Accounts Book",
      items: filteredAccountsBookItems,
    );
  }

  // 📊 Outstanding Analysis
  Widget _buildOutstandingAnalysis() {
    return _buildSection(
      title: "Outstanding Analysis",
      items: filteredOutstandingItems,
    );
  }

  // 📒 Ledger Section
  Widget _buildLedgerSection() {
    return _buildSection(
      title: "Ledger",
      items: filteredLedgerItems,
    );
  }

  // 📋 Misc Report Section
  Widget _buildMiscReportSection() {
    return _buildSection(
      title: "Misc Report",
      items: filteredMiscReportItems,
    );
  }

  // 🔔 Remainder Section
  Widget _buildRemainderSection() {
    return _buildSection(
      title: "Remainder",
      items: filteredRemainderItems,
    );
  }

  // 🔹 Reusable Section Widget
  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  navigateToPage(item['route'], item['title'], item['icon']);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.veryLightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'],
                        color: AppColors.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}