import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
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
        return IconStyle(Icons.image, Colors.green[700]!, Colors.green[50]!);
      case 'AI Chat Reports':
        return IconStyle(Icons.bar_chart, Colors.blue[700]!, Colors.blue[50]!);
      case 'Test AI':
        return IconStyle(Icons.science, Colors.red[700]!, Colors.red[50]!);
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
          // Navigate to HomeScreen when back button is pressed
          Navigator.pushReplacementNamed(context, '/home');
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
                  icon: const Icon(Icons.menu, color: Colors.white, size: 24),
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

  // List of AIs - Test AI removed
  List<Map<String, dynamic>> AIs = [
    {
      "label": "Image",
      "route": "/image",
      "icon": Icons.image,
      "color": Colors.green,
      "description": "Generate and analyze images using AI",
    },
    {
      "label": "AI Chat Reports",
      "route": "/ai_chat_reports",
      "icon": Icons.bar_chart,
      "color": Colors.blue,
      "description": "View comprehensive AI-powered analytics and reports",
    },
  ];

  return Center(
    child: Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
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
