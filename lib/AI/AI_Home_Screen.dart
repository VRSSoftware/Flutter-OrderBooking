import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';

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

class AIHomeScreen extends StatefulWidget {
  @override
  _AIHomeScreenState createState() => _AIHomeScreenState();
}

class _AIHomeScreenState extends State<AIHomeScreen>
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
      case 'Image':
        return IconStyle(
          Icons.assessment,
          Colors.green[700]!,
          Colors.green[50]!,
        );
      // case 'Test AI':
      //   return IconStyle(
      //     Icons.payments,
      //     Colors.red[700]!,
      //     Colors.red[50]!,
      //   );
    
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
                                SystemNavigator.pop();
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
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: kBackgroundLight,
        drawer: DrawerScreen(),
        appBar: AppBar(
          toolbarHeight: 48,
          title: Text(
            'VRS AI',
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
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
        ),
        body: Container(
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
                          // AIs Grid
                          _buildAIsGrid(context, constraints.maxWidth),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationWidget(currentScreen: '/AIs'),
      ),
    );
  }

Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced from 20 to 12
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
          padding: const EdgeInsets.all(8), // Reduced from 12 to 8
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12), // Reduced from 15 to 12
          ),
          child: Icon(
            Icons.insert_chart_outlined,
            color: AppColors.primaryColor,
            size: 24, // Reduced from 28 to 24
          ),
        ),
        const SizedBox(width: 12), // Reduced from 16 to 12
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Added to minimize height
            children: [
              Text(
                'ASK VRS AI',
                style: GoogleFonts.poppins(
                  fontSize: 16, // Reduced from 18 to 16
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 2), // Reduced from 4 to 2
              // Text(
              //   'Fabric to Finish with AI',
              //   style: GoogleFonts.poppins(
              //     fontSize: 11, // Reduced from 13 to 11
              //     color: Colors.grey[600],
              //   ),
              // ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildAIsGrid(BuildContext context, double screenWidth) {
    final crossAxisCount = screenWidth > 600 ? 2 : 1;
    final spacing = 5.0;
    final totalSpacing = (crossAxisCount - 1) * spacing;
    final buttonWidth = (screenWidth - 32 - totalSpacing) / crossAxisCount;

    // Clear existing animation controllers before creating new ones
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();

    // List of AIs
    List<Map<String, dynamic>> AIs = [
      {
        "label": "Image",
        "route": "/image",
        "icon": Icons.assessment,
        "color": Colors.green,
        "description": "View sales performance and trends"
      },
      // {
      //   "label": "Test AI",
      //   "route": "/testAI",
      //   "icon": Icons.payments,
      //   "color": Colors.red,
      //   "description": "Track amounts payable to suppliers"
      // },
     
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Available AIs',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.start,
          children: AIs.map((AI) {
            return _buildAIButton(
              context,
              AI["label"],
              AI["route"],
              AI["icon"],
              AI["color"],
              AI["description"],
              buttonWidth,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAIButton(
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