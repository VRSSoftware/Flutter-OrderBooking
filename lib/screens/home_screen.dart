import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/Outstanding_Reports/Payable/outstanding_payable.dart';
import 'package:vrs_erp/Outstanding_Reports/Receivable/outstanding_receivable.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/MyWebViewPage.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/Outstanding_Services.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';

const Color kPrimaryColor = Color(0xFF3B82F6);
const Color kBackgroundLight = Color(0xFFEFEFF2);
const Color kCardLight = Color(0xFFFFFFFF);
const Color kTextLight = Color(0xFF334155);
const Color kTextMutedLight = Color(0xFF64748B);

// Alternative background colors you can try:
// const Color kBackgroundLight = Color(0xFFF9FAFB); // Very subtle gray
// const Color kBackgroundLight = Color(0xFFF3F4F6); // Light gray
// const Color kBackgroundLight = Color(0xFFFAFAFA); // Warm white
// const Color kBackgroundLight = Color(0xFFF8F9FA); // Cool off-white

// --- Data class for new icon style ---
class IconStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  IconStyle(this.icon, this.iconColor, this.backgroundColor);
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animation controllers for each button
  final List<AnimationController> _animationControllers = [];
  late AnimationController _shimmerController;
  // Dashboard summary data
  Map<String, double> _dashboardData = {
    'Bank': 0.0,
    'Bill Receivable': 0.0,
    'Purchase': 0.0,
    'Payment': 0.0,
    'Bill Payable': 0.0,
    'Sales': 0.0,
    'Receipt': 0.0,
    'Cash': 0.0,
  };
  bool _isLoadingCards = true;

  Future<void> _fetchDashboardSummary() async {
    setState(() {
      _isLoadingCards = true;
    });

    try {
      final response = await OutstandingService.getDashboardSummary();

      setState(() {
        _dashboardData = {
          'Bank': (response['bankAmt'] ?? 0.0).toDouble(),
          'Bill Receivable': (response['receivableBillAmt'] ?? 0.0).toDouble(),
          'Purchase': (response['purchaseAmt'] ?? 0.0).toDouble(),
          'Payment': (response['paymentAmt'] ?? 0.0).toDouble(),
          'Bill Payable': (response['payableTotalAmt'] ?? 0.0).toDouble(),
          'Sales': (response['salesAmt'] ?? 0.0).toDouble(),
          'Receipt': (response['receiptAmt'] ?? 0.0).toDouble(),
          'Cash': (response['cashAmt'] ?? 0.0).toDouble(),
        };
        _isLoadingCards = false;
      });
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      setState(() {
        _isLoadingCards = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);

    // Fetch dashboard summary
    _fetchDashboardSummary();
  }

  Widget _buildDashboardCards() {
    final List<Map<String, dynamic>> cardData = [
      {
        'title': 'Bank',
        'icon': Icons.account_balance,
        'color': Colors.blue,
        'page': null,
      },
      {
        'title': 'Bill Receivable',
        'icon': Icons.receipt,
        'color': Colors.green,
        'page': OutstandingReceivablePage(),
      },
      {
        'title': 'Purchase',
        'icon': Icons.shopping_cart,
        'color': Colors.orange,
        'page': null,
      },
      {
        'title': 'Payment',
        'icon': Icons.payment,
        'color': Colors.red,
        'page': null,
      },
      {
        'title': 'Bill Payable',
        'icon': Icons.receipt_long,
        'color': Colors.purple,
        'page': OutstandingPayablePage(),
      },
      {
        'title': 'Sales',
        'icon': Icons.trending_up,
        'color': Colors.teal,
        'page': null,
      },
      {
        'title': 'Receipt',
        'icon': Icons.receipt,
        'color': Colors.indigo,
        'page': null,
      },
      {
        'title': 'Cash',
        'icon': Icons.currency_rupee,
        'color': Colors.amber,
        'page': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Financial Summary',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        SizedBox(
          height: 70,
          child:
              _isLoadingCards
                  ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cardData.length,
                    itemBuilder: (context, index) {
                      final card = cardData[index];
                      final amount = _dashboardData[card['title']] ?? 0.0;
                      return GestureDetector(
                        onTap: () {
                          if (card['page'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => card['page'],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${card['title']} page coming soon',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                color: card['color'] as Color,
                                width: 4,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (card['color'] as Color).withOpacity(
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    card['icon'],
                                    size: 22,
                                    color: card['color'],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        card['title'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹ ${NumberFormat('#,##,###').format(amount)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: card['color'],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    _shimmerController.dispose();
    super.dispose();
  }

  // This helper function maps your labels to the new icons and colors
  // to match the design you wanted.
  IconStyle _getIconStyle(String label) {
    switch (label) {
      case 'Order Booking':
        return IconStyle(
          Icons.shopping_cart_checkout,
          kPrimaryColor,
          Colors.blue[50]!,
        );
      case 'Catalog':
        return IconStyle(Icons.style, Colors.green[700]!, Colors.green[50]!);
      case 'Order Register':
        return IconStyle(
          Icons.app_registration,
          Colors.purple[700]!,
          Colors.purple[50]!,
        );
      case 'Packing':
        return IconStyle(
          Icons.inventory_2,
          Colors.orange[700]!,
          Colors.orange[50]!,
        );
      case 'Sale Bill':
        return IconStyle(Icons.receipt_long, Colors.red[700]!, Colors.red[50]!);
      case 'Stock Report':
        return IconStyle(
          Icons.assessment,
          Colors.amber[800]!,
          Colors.amber[50]!,
        );
      case 'Dashboard':
        return IconStyle(
          Icons.dashboard,
          Colors.indigo[700]!,
          Colors.indigo[50]!,
        );
      case 'Production':
        return IconStyle(
          Icons.precision_manufacturing,
          Colors.pink[700]!,
          Colors.pink[50]!,
        );

      case 'Report':
        return IconStyle(
          Icons.account_balance_wallet,
          Colors.teal[700]!,
          Colors.teal[50]!,
        );
      case 'Ask VRS AI':
        return IconStyle(
          Icons.account_balance_wallet,
          Colors.teal[700]!,
          Colors.teal[50]!,
        );

      case 'Purchase Inward':
        return IconStyle(Icons.receipt, Colors.grey[700]!, Colors.grey[50]!);

      case 'Purchase Return':
        return IconStyle(
          Icons.receipt,
          Colors.yellow[700]!,
          Colors.yellow[50]!,
        );
      case 'Accounts':
        return IconStyle(Icons.receipt, Colors.red[700]!, Colors.red[50]!);

      case 'Masters':
        return IconStyle(Icons.receipt, Colors.brown[700]!, Colors.red[50]!);

      // case 'Web':
      //   return IconStyle(Icons.public, Colors.brown[700]!, Colors.brown[50]!);

      default:
        return IconStyle(Icons.grid_view, Colors.grey[700]!, Colors.grey[50]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        bool shouldExit = await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                contentPadding: EdgeInsets.zero,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.exit_to_app,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Exit App',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Are you sure you want to close the app?',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'No',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                SystemNavigator.pop(); // This directly closes the app
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        );

        if (shouldExit == true) {
          Navigator.pop(context); // exit app
        }
        // If shouldExit == false, do nothing and stay on home screen
      },
      child: Scaffold(
        backgroundColor: kBackgroundLight, // Now a slightly off-white color
        drawer: DrawerScreen(),
        // --- New AppBar Styling ---
        appBar: AppBar(
          toolbarHeight: 48, // ✅ Decrease height (default is 56)

          title: Text(
            'VRS Software',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18, // Slightly reduced to match height
            ),
          ),

          backgroundColor: AppColors.primaryColor,
          elevation: 3,
          centerTitle: true,

          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),

          leading: Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 24, // Slightly smaller for compact look
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
        ),

        // --- Your Existing Body Structure ---
        body: Container(
          decoration: BoxDecoration(
            color: kBackgroundLight,
            // Optional: Add a very subtle gradient for depth
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kBackgroundLight,
                kBackgroundLight.withOpacity(0.95),
                Color(0xFFEEF2F6), // Slightly darker at bottom
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Padding(
            // Changed padding to match p-4 from new design
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildDashboardCards(),
                          _buildMainButtons(context, constraints.maxWidth),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // --- Your Existing Bottom Nav Bar ---
        bottomNavigationBar: BottomNavigationWidget(currentScreen: '/home'),
      ),
    );
  }

  // --- Your Existing Button Layout Logic ---
  Widget _buildMainButtons(BuildContext context, double screenWidth) {
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    // Changed spacing to 16.0 to match gap-4
    final spacing = 12.0;
    final totalSpacing = (crossAxisCount - 1) * spacing;
    // Adjusted padding to 32 (16*2) to match p-4
    final buttonWidth = (screenWidth - 32 - totalSpacing) / crossAxisCount;

    // Clear existing animation controllers before creating new ones
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();

    // Create a list of buttons
    List<Widget> buttons = [];

    // Add buttons based on conditions
    buttons.add(
      _buildFeatureButton(context, 'Order Booking', () {
        // Navigator.pushNamed(context, '/orderbooking');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/orderbooking',
          (Route<dynamic> route) => false,
        );
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Catalog', () {
        // Navigator.pushNamed(context, '/catalog');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/catalog',
          (Route<dynamic> route) => false,
        );
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Order Register', () {
        Navigator.pushNamed(context, '/registerOrders');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Sale Bill', () {
        Navigator.pushNamed(context, '/saleBillRegister');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Packing', () {
        Navigator.pushNamed(context, '/packingRegister');
      }, buttonWidth),
    );



    buttons.add(
      _buildFeatureButton(context, 'Production', () {
        Navigator.pushNamed(context, '/production');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Purchase Inward', () {
        Navigator.pushNamed(context, '/purchaseInward');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Purchase Order', () {
        Navigator.pushNamed(context, '/purchaseOrder');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Purchase Return', () {
        Navigator.pushNamed(context, '/purchaseReturn');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Sales Return', () {
        Navigator.pushNamed(context, '/salesReturn');
      }, buttonWidth),
    );
    
    // buttons.add(
    //   _buildFeatureButton(context, 'Ask VRS AI', () {
    //     Navigator.pushNamed(context, '/vrsai');
    //   }, buttonWidth),
    // );

    // buttons.add(
    //   _buildFeatureButton(context, 'Web', () {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => UniversalWebView()),
    //     );
    //   }, buttonWidth),
    // );

    // buttons.add(
    //   _buildFeatureButton(context, 'Report', () {
    //     Navigator.pushNamed(context, '/reportHomeScreen');
    //   }, buttonWidth),
    // );

    buttons.add(
      _buildFeatureButton(context, 'Accounts', () {
        Navigator.pushNamed(context, '/accountDashboard');
      }, buttonWidth),
    );

    buttons.add(
      _buildFeatureButton(context, 'Masters', () {
        Navigator.pushNamed(context, '/masters');
      }, buttonWidth),
    );

    // --- Your Existing UserSession Logic ---
    if (UserSession.userType == 'A') {
      buttons.add(
        _buildFeatureButton(context, 'Stock Report', () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/stockReport',
            (Route<dynamic> route) => false,
          );
        }, buttonWidth),
      );
    }

    // Show Dashboard for Admin (A) and Customer (C) only, not for Salesperson (S)
    if (UserSession.userType == 'A' || UserSession.userType == 'C') {
      buttons.add(
        _buildFeatureButton(context, 'Dashboard', () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (Route<dynamic> route) => false,
          );
        }, buttonWidth),
      );
    }

    return Center(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.center,
        children: buttons,
      ),
    );
  }

  // --- REDESIGNED Feature Button with Material UI and animations ---
  Widget _buildFeatureButton(
    BuildContext context,
    String label,
    VoidCallback onTap,
    double width,
  ) {
    final style = _getIconStyle(label);

    // Create animation controller for this button
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Slightly shorter duration
    );
    _animationControllers.add(animationController);

    // Use simpler animation without CurvedAnimation to avoid issues
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(animationController);

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) {
            animationController.forward();
          },
          onTapUp: (_) {
            animationController.reverse().then((_) {
              onTap();
            });
          },
          onTapCancel: () {
            animationController.reverse();
          },
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    1.0 -
                    (animationController.value *
                        0.03), // Simple scale calculation
                child: Container(
                  width: width,
                  child: Card(
                    elevation:
                        2.0 +
                        (animationController.value *
                            4), // Simple elevation calculation
                    color: kCardLight,
                    shadowColor: style.iconColor.withOpacity(
                      0.2 + (animationController.value * 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(color: style.backgroundColor, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon with gradient background
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  style.backgroundColor,
                                  style.backgroundColor.withOpacity(0.5),
                                  Colors.white,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: style.iconColor.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              style.icon,
                              size: 32,
                              color: style.iconColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Label
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: style.iconColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtle indicator line
                          Container(
                            width: 30,
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  style.iconColor,
                                  style.iconColor.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}





















































































































// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/screens/MyWebViewPage.dart';
// import 'package:vrs_erp/screens/drawer_screen.dart';
// import 'package:vrs_erp/widget/bottom_navbar.dart';

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   // Animation controllers for each button
//   final List<AnimationController> _animationControllers = [];

//   // Financial metrics data
//   final List<Map<String, dynamic>> financialMetrics = [
//     {"title": "Sales", "amount": "12,50,000", "icon": Icons.trending_up, "color": Color(0xFF4CAF50), "change": "+8.2%"},
//     {"title": "Receipt", "amount": "4,50,000", "icon": Icons.attach_money, "color": Color(0xFF2196F3), "change": "+5.1%"},
//     {"title": "Bank", "amount": "8,75,000", "icon": Icons.account_balance, "color": Color(0xFF3F51B5), "change": "+12.3%"},
//     {"title": "Bills Rec.", "amount": "2,50,000", "icon": Icons.receipt, "color": Color(0xFFFF9800), "change": "-2.4%"},
//     {"title": "Purchase", "amount": "6,80,000", "icon": Icons.shopping_cart, "color": Color(0xFFF44336), "change": "+15.7%"},
//     {"title": "Payment", "amount": "5,20,000", "icon": Icons.payment, "color": Color(0xFF9C27B0), "change": "-3.2%"},
//     {"title": "Bill Pay.", "amount": "1,80,000", "icon": Icons.receipt_long, "color": Color(0xFF009688), "change": "+2.1%"},
//   ];

//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   void dispose() {
//     for (var controller in _animationControllers) {
//       controller.dispose();
//     }
//     _animationControllers.clear();
//     super.dispose();
//   }

//   // Simple icon color mapping
//   Color _getIconColor(String label) {
//     switch (label) {
//       case 'Order Booking':
//         return AppColors.primaryBlue;
//       case 'Catalog':
//         return Colors.green[700]!;
//       case 'Order Register':
//         return AppColors.deepPurple;
//       case 'Packing':
//         return Colors.orange[700]!;
//       case 'Sale Bill':
//         return AppColors.red;
//       case 'Packing Register':
//         return Colors.cyan[700]!;
//       case 'Sale Bill Register':
//         return Colors.teal[700]!;
//       case 'Stock Report':
//         return Colors.amber[800]!;
//       case 'Dashboard':
//         return Colors.indigo[700]!;
//       case 'Production':
//         return AppColors.pink;
//       case 'Report':
//         return AppColors.maroon;
//       case 'Ask VRS AI':
//         return AppColors.primaryColor;
//       case 'Accounts':
//         return AppColors.accentColor;
//       case 'Outstanding Report':
//         return AppColors.mutedPink;
//       default:
//         return AppColors.slate600;
//     }
//   }

//   // Scrollable Financial Metrics Cards
//   Widget _buildFinancialMetrics() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16, top: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 Container(
//                   width: 4,
//                   height: 20,
//                   decoration: BoxDecoration(
//                     color: AppColors.primaryColor[500],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   "Financial Overview",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.primaryColor[700],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(
//             height: 110,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               itemCount: financialMetrics.length,
//               itemBuilder: (context, index) {
//                 final metric = financialMetrics[index];
//                 return Container(
//                   width: 150,
//                   margin: const EdgeInsets.only(right: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.06),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                     border: Border.all(
//                       color: (metric['color'] as Color).withOpacity(0.15),
//                       width: 1,
//                     ),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: (metric['color'] as Color).withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Icon(
//                                 metric['icon'] as IconData,
//                                 color: metric['color'] as Color,
//                                 size: 20,
//                               ),
//                             ),
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: (metric['change'] as String).startsWith('+') 
//                                     ? Colors.green.withOpacity(0.1)
//                                     : Colors.red.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(
//                                     (metric['change'] as String).startsWith('+') 
//                                         ? Icons.arrow_upward
//                                         : Icons.arrow_downward,
//                                     size: 10,
//                                     color: (metric['change'] as String).startsWith('+') 
//                                         ? Colors.green[700]
//                                         : Colors.red[700],
//                                   ),
//                                   const SizedBox(width: 2),
//                                   Text(
//                                     metric['change'] as String,
//                                     style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w600,
//                                       color: (metric['change'] as String).startsWith('+') 
//                                           ? Colors.green[700]
//                                           : Colors.red[700],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           metric['title'] as String,
//                           style: GoogleFonts.poppins(
//                             fontSize: 11,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.slate600,
//                           ),
//                         ),
//                         Text(
//                           '₹${metric['amount']}',
//                           style: GoogleFonts.poppins(
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold,
//                             color: metric['color'] as Color,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Beautiful button with reduced width between items
//   Widget _buildSimpleButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
//     final iconColor = _getIconColor(label);
    
//     final animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 150),
//     );
//     _animationControllers.add(animationController);

//     return GestureDetector(
//       onTapDown: (_) => animationController.forward(),
//       onTapUp: (_) => animationController.reverse().then((_) => onTap()),
//       onTapCancel: () => animationController.reverse(),
//       child: AnimatedBuilder(
//         animation: animationController,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: 1.0 - (animationController.value * 0.03),
//             child: Container(
//               width: 80,
//               margin: const EdgeInsets.only(right: 8),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(14),
//                       boxShadow: [
//                         BoxShadow(
//                           color: iconColor.withOpacity(0.15),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: Icon(icon, color: iconColor, size: 26),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     label,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryColor[800],
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Section widget as a beautiful card (without icon in title)
//   Widget _buildSectionCard({
//     required String title,
//     required List<Widget> buttons,
//     required Color accentColor,
//   }) {
//     if (buttons.isEmpty) return const SizedBox.shrink();
    
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//         border: Border.all(
//           color: accentColor.withOpacity(0.15),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Card Header (without icon)
//           Container(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   accentColor.withOpacity(0.05),
//                   Colors.white,
//                 ],
//               ),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(24),
//                 topRight: Radius.circular(24),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 4,
//                   height: 20,
//                   decoration: BoxDecoration(
//                     color: accentColor,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.primaryColor[700],
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                     color: accentColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '${buttons.length}',
//                     style: GoogleFonts.poppins(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       color: accentColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Divider
//           Container(
//             height: 1,
//             color: accentColor.withOpacity(0.1),
//             margin: const EdgeInsets.symmetric(horizontal: 20),
//           ),
          
//           // Buttons
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: buttons,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         if (didPop) return;

//         bool shouldExit = await showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => AlertDialog(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//             elevation: 0,
//             backgroundColor: Colors.transparent,
//             contentPadding: EdgeInsets.zero,
//             content: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [AppColors.red, AppColors.red.withOpacity(0.8)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(24),
//                         topRight: Radius.circular(24),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(14),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.exit_to_app, color: Colors.white, size: 32),
//                         ),
//                         const SizedBox(height: 14),
//                         const Text('Exit App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
//                         const SizedBox(height: 8),
//                         const Text('Are you sure you want to close the app?', style: TextStyle(fontSize: 14, color: Colors.white), textAlign: TextAlign.center),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: () => Navigator.pop(context, false),
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: AppColors.slate600,
//                               side: BorderSide(color: AppColors.slateBorder),
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                             ),
//                             child: const Text('No', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: () => SystemNavigator.pop(),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: AppColors.red,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                               elevation: 0,
//                             ),
//                             child: const Text('Yes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );

//         if (shouldExit == true) {
//           Navigator.pop(context);
//         }
//       },
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         drawer: DrawerScreen(),
//         appBar: AppBar(
//           toolbarHeight: 56,
//           title: Text(
//             'VRS Software',
//             style: GoogleFonts.roboto(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//               letterSpacing: 0.5,
//             ),
//           ),
//           backgroundColor: AppColors.primaryColor[500],
//           elevation: 0,
//           centerTitle: true,
//           leading: Builder(
//             builder: (context) => IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white, size: 26),
//               onPressed: () => Scaffold.of(context).openDrawer(),
//             ),
//           ),
//           actions: [
//             Container(
//               margin: const EdgeInsets.only(right: 12),
//               child: CircleAvatar(
//                 radius: 16,
//                 backgroundColor: Colors.white.withOpacity(0.2),
//                 child: Icon(Icons.person, color: Colors.white, size: 18),
//               ),
//             ),
//           ],
//         ),
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Colors.grey[50]!,
//                 Colors.white,
//               ],
//             ),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 8),
//                 _buildFinancialMetrics(),
                
//                 // Order Management Card
//                 _buildSectionCard(
//                   title: "Order Management",
//                   accentColor: AppColors.primaryBlue,
//                   buttons: [
//                     _buildSimpleButton(context, 'Order Booking', Icons.shopping_cart_checkout, () {
//                       Navigator.pushNamedAndRemoveUntil(
//                         context,
//                         '/orderbooking',
//                         (Route<dynamic> route) => false,
//                       );
//                     }),
//                     _buildSimpleButton(context, 'Catalog', Icons.style, () {
//                       Navigator.pushNamedAndRemoveUntil(
//                         context,
//                         '/catalog',
//                         (Route<dynamic> route) => false,
//                       );
//                     }),
//                     _buildSimpleButton(context, 'Order Register', Icons.app_registration, () {
//                       Navigator.pushNamed(context, '/registerOrders');
//                     }),
//                   ],
//                 ),
                
//                 // Packing & Billing Card
//                 _buildSectionCard(
//                   title: "Packing & Billing",
//                   accentColor: Colors.orange[700]!,
//                   buttons: [
//                     _buildSimpleButton(context, 'Packing', Icons.inventory_2, () {
//                       Navigator.pushNamed(context, '/packingBooking');
//                     }),
//                     _buildSimpleButton(context, 'Sale Bill', Icons.receipt_long, () {
//                       Navigator.pushNamed(context, '/SaleBillBookingScreen');
//                     }),
//                     _buildSimpleButton(context, 'Packing Register', Icons.checklist, () {
//                       Navigator.pushNamed(context, '/packingOrders');
//                     }),
//                     _buildSimpleButton(context, 'Sale Bill Register', Icons.receipt, () {
//                       Navigator.pushNamed(context, '/saleBillRegister');
//                     }),
//                   ],
//                 ),
                
//                 // Production & AI Card
//                 _buildSectionCard(
//                   title: "Production & AI",
//                   accentColor: AppColors.pink,
//                   buttons: [
//                     _buildSimpleButton(context, 'Production', Icons.precision_manufacturing, () {
//                       Navigator.pushNamed(context, '/production');
//                     }),
//                     _buildSimpleButton(context, 'Ask VRS AI', Icons.auto_awesome, () {
//                       Navigator.pushNamed(context, '/vrsai');
//                     }),
//                   ],
//                 ),
                
//                 // Reports & Analytics Card
//                 _buildSectionCard(
//                   title: "Reports & Analytics",
//                   accentColor: AppColors.maroon,
//                   buttons: [
//                     _buildSimpleButton(context, 'Report', Icons.account_balance_wallet, () {
//                       Navigator.pushNamed(context, '/reportHomeScreen');
//                     }),
//                     _buildSimpleButton(context, 'Accounts', Icons.account_balance, () {
//                       Navigator.pushNamed(context, '/accountDashboard');
//                     }),
//                     _buildSimpleButton(context, 'Outstanding Report', Icons.assessment, () {
//                       Navigator.pushNamed(context, '/outstandingMainScreen');
//                     }),
//                   ],
//                 ),
                
//                 // Additional Features Card (Conditional)
//                 if (UserSession.userType == 'A' || UserSession.userType == 'C')
//                   _buildSectionCard(
//                     title: "Additional Features",
//                     accentColor: Colors.amber[700]!,
//                     buttons: [
//                       if (UserSession.userType == 'A')
//                         _buildSimpleButton(context, 'Stock Report', Icons.assessment, () {
//                           Navigator.pushNamedAndRemoveUntil(
//                             context,
//                             '/stockReport',
//                             (Route<dynamic> route) => false,
//                           );
//                         }),
//                       if (UserSession.userType == 'A' || UserSession.userType == 'C')
//                         _buildSimpleButton(context, 'Dashboard', Icons.dashboard, () {
//                           Navigator.pushNamedAndRemoveUntil(
//                             context,
//                             '/dashboard',
//                             (Route<dynamic> route) => false,
//                           );
//                         }),
//                     ],
//                   ),
                
//                 const SizedBox(height: 30),
//               ],
//             ),
//           ),
//         ),
//         bottomNavigationBar: BottomNavigationWidget(currentScreen: '/home'),
//       ),
//     );
//   }
// }