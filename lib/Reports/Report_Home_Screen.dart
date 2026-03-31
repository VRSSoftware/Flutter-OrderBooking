import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/screens/home_screen.dart'; // Add this import

// --- Colors from the new design ---
const Color kPrimaryColor = Color(0xFF3B82F6);
const Color kBackgroundLight = Color(0xFFEFEFF2);
const Color kCardLight = Color(0xFFFFFFFF);
const Color kTextLight = Color(0xFF334155);
const Color kTextMutedLight = Color(0xFF64748B);

// --- Data class for icon style ---
class IconStyle {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  IconStyle(this.icon, this.iconColor, this.backgroundColor);
}

class ReportHomeScreen extends StatefulWidget {
  @override
  _ReportHomeScreenState createState() => _ReportHomeScreenState();
}

class _ReportHomeScreenState extends State<ReportHomeScreen>
    with TickerProviderStateMixin {
  // Animation controllers for each button
  final List<AnimationController> _animationControllers = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }

  // This helper function maps your labels to the icons and colors
  IconStyle _getIconStyle(String label) {
    switch (label) {
      case 'Sales Analysis':
        return IconStyle(
          Icons.assessment,
          Colors.green[700]!,
          Colors.green[50]!,
        );
      case 'Production Analysis':
        return IconStyle(
          Icons.factory,
          Colors.orange[700]!,
          Colors.orange[50]!,
        );
      case 'Customer Analysis':
        return IconStyle(Icons.people, Colors.pink[700]!, Colors.pink[50]!);
      case 'Stock Analysis':
        return IconStyle(
          Icons.inventory,
          Colors.brown[700]!,
          Colors.brown[50]!,
        );
      case 'Order Analysis':
        return IconStyle(
          Icons.shopping_cart,
          Colors.amber[700]!,
          Colors.amber[50]!,
        );
      case 'Payable':
        return IconStyle(Icons.payments, Colors.red[700]!, Colors.red[50]!);
      case 'Receivable':
        return IconStyle(
          Icons.account_balance_wallet,
          Colors.teal[700]!,
          Colors.teal[50]!,
        );
      case 'Ledger':
        return IconStyle(
          Icons.menu_book,
          Colors.indigo[700]!,
          Colors.indigo[50]!,
        );
      default:
        return IconStyle(Icons.grid_view, Colors.grey[700]!, Colors.grey[50]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Navigate to home screen when back button is pressed
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        backgroundColor: kBackgroundLight,
        drawer: DrawerScreen(),
        appBar: AppBar(
          toolbarHeight: 48,
          title: Text(
            'Reports',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
                  icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: kBackgroundLight,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  kBackgroundLight,
                  kBackgroundLight.withOpacity(0.95),
                  const Color(0xFFEEF2F6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Padding(
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
                            // Header Section
                            _buildHeader(),
                            const SizedBox(height: 24),
                            // Reports Grid
                            _buildReportsGrid(context, constraints.maxWidth),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insert_chart_outlined,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Analytics Reports',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'View and analyze your business data',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context, double screenWidth) {
    final crossAxisCount = screenWidth > 600 ? 2 : 1;
    final spacing = 5.0;
    final totalSpacing = (crossAxisCount - 1) * spacing;
    final buttonWidth = (screenWidth - 32 - totalSpacing) / crossAxisCount;

    // Clear existing animation controllers before creating new ones
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();

    // List of reports with correct subtitles
    List<Map<String, dynamic>> reports = [
      {
        "label": "Sales Analysis",
        "route": "/salesAnalysis",
        "icon": Icons.assessment,
        "color": Colors.green,
        "description": "Analyze sales performance, trends, and revenue metrics",
      },
      {
        "label": "Production Analysis",
        "route": "/ProductionAnalysis",
        "icon": Icons.factory,
        "color": Colors.orange,
        "description":
            "Track production output, efficiency, and manufacturing metrics",
      },
      {
        "label": "Customer Analysis",
        "route": "/CustomerAnalysis",
        "icon": Icons.people,
        "color": Colors.pink,
        "description":
            "View customer behavior, segmentation, and purchase patterns",
      },
      {
        "label": "Stock Analysis",
        "route": "/StockAnalysis",
        "icon": Icons.inventory,
        "color": Colors.brown,
        "description":
            "Monitor inventory levels, stock movement, and reorder points",
      },
      {
        "label": "Order Analysis",
        "route": "/OrderAnalysis",
        "icon": Icons.shopping_cart,
        "color": Colors.amber,
        "description":
            "Track order status, fulfillment rates, and delivery timelines",
      },
      {
        "label": "Payable",
        "route": "/payable",
        "icon": Icons.payments,
        "color": Colors.red,
        "description": "Track amounts payable to suppliers and vendors",
      },
      {
        "label": "Receivable",
        "route": "/receivable",
        "icon": Icons.account_balance_wallet,
        "color": Colors.teal,
        "description": "Track amounts receivable from customers and clients",
      },
      {
        "label": "Ledger",
        "route": "/ledger",
        "icon": Icons.menu_book,
        "color": Colors.indigo,
        "description": "View detailed ledger entries and account statements",
      },
    ];

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children:
                reports.map((report) {
                  return _buildReportButton(
                    context,
                    report["label"],
                    report["route"],
                    report["icon"],
                    report["color"],
                    report["description"],
                    buttonWidth,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context,
    String label,
    String route,
    IconData icon,
    Color color,
    String description,
    double width,
  ) {
    final style = _getIconStyle(label);

    // Create animation controller for this button
    final animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animationControllers.add(animationController);

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) {
            animationController.forward();
          },
          onTapUp: (_) {
            animationController.reverse().then((_) {
              Navigator.pushNamed(context, route);
            });
          },
          onTapCancel: () {
            animationController.reverse();
          },
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 - (animationController.value * 0.03),
                child: Container(
                  width: width,
                  child: Card(
                    elevation: 2.0 + (animationController.value * 4),
                    color: kCardLight,
                    shadowColor: color.withOpacity(
                      0.2 + (animationController.value * 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(color: style.backgroundColor, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Section
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  style.icon,
                                  size: 28,
                                  color: style.iconColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: style.iconColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Subtle indicator line
                          Container(
                            width: 50,
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
