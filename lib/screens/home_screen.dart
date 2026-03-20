// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/screens/MyWebViewPage.dart';
// import 'package:vrs_erp/screens/drawer_screen.dart';
// import 'package:vrs_erp/widget/bottom_navbar.dart';

// // --- Colors from the new design ---
// // We'll assume light mode, as your original code was light.
// const Color kPrimaryColor = Color(0xFF3B82F6);
// const Color kBackgroundLight = Color(0xFFF8FAFC);
// const Color kCardLight = Color(0xFFFFFFFF);
// const Color kTextLight = Color(0xFF334155);
// const Color kTextMutedLight = Color(0xFF64748B);

// // --- Data class for new icon style ---
// class IconStyle {
//   final IconData icon;
//   final Color iconColor;
//   final Color backgroundColor;

//   IconStyle(this.icon, this.iconColor, this.backgroundColor);
// }

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   // This helper function maps your labels to the new icons and colors
//   // to match the design you wanted.
//   IconStyle _getIconStyle(String label) {
//     switch (label) {
//       case 'Order Booking':
//         return IconStyle(
//           Icons.shopping_cart_checkout,
//           kPrimaryColor,
//           Colors.blue[100]!,
//         );
//       case 'Catalog':
//         return IconStyle(Icons.style, Colors.green[500]!, Colors.green[100]!);
//       case 'Order Register':
//         return IconStyle(
//           Icons.app_registration,
//           Colors.purple[500]!,
//           Colors.purple[100]!,
//         );
//       case 'Packing':
//         return IconStyle(
//           Icons.inventory_2,
//           Colors.orange[500]!,
//           Colors.orange[100]!,
//         );
//       case 'Sale Bill':
//         return IconStyle(
//           Icons.receipt_long,
//           Colors.red[500]!,
//           Colors.red[100]!,
//         );
//       case 'Packing Register':
//         return IconStyle(Icons.checklist, Colors.cyan[500]!, Colors.cyan[100]!);
//       case 'Sale Bill Register':
//         return IconStyle(Icons.receipt, Colors.teal[500]!, Colors.teal[100]!);
//       case 'Stock Report':
//         return IconStyle(
//           Icons.assessment,
//           Colors.yellow[700]!,
//           Colors.yellow[100]!,
//         );
//       case 'Dashboard':
//         return IconStyle(
//           Icons.dashboard,
//           Colors.indigo[500]!,
//           Colors.indigo[100]!,
//         );
//       case 'Production':
//         return IconStyle(
//           Icons.precision_manufacturing, // 🏭 Factory gear icon
//           kPrimaryColor,
//           Colors.purple[100]!,
//         );

//       default:
//         return IconStyle(Icons.grid_view, Colors.grey[500]!, Colors.grey[100]!);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBackgroundLight, // New background color
//       drawer: DrawerScreen(),
//       // --- New AppBar Styling ---
//       appBar: AppBar(
//         toolbarHeight: 48, // ✅ Decrease height (default is 56)

//         title: Text(
//           'VRS Software',
//           style: GoogleFonts.roboto(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 18, // Slightly reduced to match height
//           ),
//         ),

//         backgroundColor: AppColors.primaryColor,
//         elevation: 3,
//         centerTitle: true,

//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
//         ),

//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: const Icon(
//                   Icons.menu,
//                   color: Colors.white,
//                   size: 24, // Slightly smaller for compact look
//                 ),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//         ),
//       ),

//       // --- Your Existing Body Structure ---
//       body: Padding(
//         // Changed padding to match p-4 from new design
//         padding: const EdgeInsets.all(16.0),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     children: [
//                       _buildMainButtons(context, constraints.maxWidth),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       // --- Your Existing Bottom Nav Bar ---
//       bottomNavigationBar: BottomNavigationWidget(currentScreen: '/home'),
//     );
//   }

//   // --- Your Existing Button Layout Logic ---
//   Widget _buildMainButtons(BuildContext context, double screenWidth) {
//     final crossAxisCount = screenWidth > 600 ? 3 : 2;
//     // Changed spacing to 16.0 to match gap-4
//     final spacing = 12.0;
//     final totalSpacing = (crossAxisCount - 1) * spacing;
//     // Adjusted padding to 32 (16*2) to match p-4
//     final buttonWidth = (screenWidth - 32 - totalSpacing) / crossAxisCount;

//     return Center(
//       child: Wrap(
//         spacing: spacing,
//         runSpacing: spacing,
//         alignment: WrapAlignment.center,
//         children: [
//           // We now call the new _buildFeatureButton
//           _buildFeatureButton(context, 'Order Booking', () {
//             Navigator.pushNamed(context, '/orderbooking');
//           }, buttonWidth),
//           _buildFeatureButton(context, 'Catalog', () {
//             Navigator.pushNamed(context, '/catalog');
//           }, buttonWidth),
//           _buildFeatureButton(context, 'Order Register', () {
//             Navigator.pushNamed(context, '/registerOrders');
//           }, buttonWidth),
//           // _buildFeatureButton(context, 'Packing', () {
//           //   Navigator.pushNamed(context, '/packingBooking');
//           // }, buttonWidth),
//           // _buildFeatureButton(context, 'Sale Bill', () {
//           //   Navigator.pushNamed(context, '/SaleBillBookingScreen');
//           // }, buttonWidth),
//           // _buildFeatureButton(context, 'Packing Register', () {
//           //   Navigator.pushNamed(context, '/packingOrders');
//           // }, buttonWidth),
//           // _buildFeatureButton(context, 'Sale Bill Register', () {
//           //   Navigator.pushNamed(context, '/saleBillRegister');
//           // }, buttonWidth),
//           // _buildFeatureButton(context, 'Production', () {
//           //   Navigator.pushNamed(context, '/production');
//           // }, buttonWidth),
//           // _buildFeatureButton(context, 'Web', () {
//           //   Navigator.push(
//           //     context,
//           //     MaterialPageRoute(builder: (context) =>  UniversalWebView()),
//           //   );
//           // }, buttonWidth),
//           // --- Your Existing UserSession Logic ---
//           UserSession.userType == 'A'
//               ? _buildFeatureButton(context, 'Stock Report', () {
//                 Navigator.pushNamed(context, '/stockReport');
//               }, buttonWidth)
//               : Container(),
//           UserSession.userType == 'A'
//               ? _buildFeatureButton(context, 'Dashboard', () {
//                 Navigator.pushNamed(context, '/dashboard');
//               }, buttonWidth)
//               : Container(),
//         ],
//       ),
//     );
//   }

//   // --- REBUILT Feature Button to match new design ---
//   Widget _buildFeatureButton(
//     BuildContext context,
//     String label,
//     VoidCallback onTap,
//     double width,
//   ) {
//     final style = _getIconStyle(label);

//     return SizedBox(
//       width: width,
//       child: Container(
//         decoration: BoxDecoration(
//           border: const Border(
//             top: BorderSide(
//               // color: Color(0xFF800000),
//               color:AppColors.primaryColor,
//               width: 1.5, // 🔥 Reduced
//             ),
//             bottom: BorderSide(
//               // color: Color(0xFF800000),
//                 color:AppColors.primaryColor,
//               width: 1.5, // 🔥 Reduced
//             ),
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Card(
//           color: kCardLight,
//           elevation: 1.0,
//           margin: EdgeInsets.zero,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12.0),
//           ),
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(12.0),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                 vertical: 24.0,
//                 horizontal: 16.0,
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     radius: 28,
//                     backgroundColor: style.backgroundColor,
//                     child: Icon(style.icon, size: 30, color: style.iconColor),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     label,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.lora(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.primaryColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/MyWebViewPage.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';

// --- Colors from the new design ---
// We'll assume light mode, as your original code was light.
const Color kPrimaryColor = Color(0xFF3B82F6);
const Color kBackgroundLight = Color(
  0xFFEFEFF2,
); // Slightly off-white (was F8FAFC)
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

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);
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
      case 'Packing Register':
        return IconStyle(Icons.checklist, Colors.cyan[700]!, Colors.cyan[50]!);
      case 'Sale Bill Register':
        return IconStyle(Icons.receipt, Colors.teal[700]!, Colors.teal[50]!);
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
      case 'Web':
        return IconStyle(Icons.public, Colors.brown[700]!, Colors.brown[50]!);

      default:
        return IconStyle(Icons.grid_view, Colors.grey[700]!, Colors.grey[50]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
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
        // Navigator.pushNamed(context, '/registerOrders');
        Navigator.pushNamedAndRemoveUntil(
            context,
            '/registerOrders',
            (Route<dynamic> route) => false,
          );
      }, buttonWidth),
    );

    //    buttons.add(_buildFeatureButton(context, 'Packing', () {
    //     Navigator.pushNamed(context, '/packingBooking');
    //   }, buttonWidth));
    //   _buildFeatureButton(context, 'Sale Bill', () {
    //     Navigator.pushNamed(context, '/SaleBillBookingScreen');
    //   }, buttonWidth);
    //  buttons.add(_buildFeatureButton(context, 'Packing Register', () {
    //     Navigator.pushNamed(context, '/packingOrders');
    //   }, buttonWidth));
    //    buttons.add(_buildFeatureButton(context, 'Sale Bill Register', () {
    //     Navigator.pushNamed(context, '/saleBillRegister');
    //   }, buttonWidth));
     buttons.add(_buildFeatureButton(context, 'Production', () {
      Navigator.pushNamed(context, '/production');
    }, buttonWidth));
    //   buttons.add (_buildFeatureButton(context, 'Web', () {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) =>  UniversalWebView()),
    //     );
    //   }, buttonWidth));

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

      buttons.add(
        _buildFeatureButton(context, 'Dashboard', () {
          // Navigator.pushNamed(context, '/dashboard');
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
