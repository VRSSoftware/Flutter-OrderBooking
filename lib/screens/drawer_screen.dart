// import 'package:flutter/material.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/screens/login_screen.dart'; // Import your LoginScreen

// class DrawerScreen extends StatefulWidget {
//   @override
//   _DrawerScreenState createState() => _DrawerScreenState();
// }

// class _DrawerScreenState extends State<DrawerScreen> {
//   String? selectedSection;
//   String? hoveredSection;

//   final Map<String, String> _iconPaths = {
//     'Home': 'assets/images/home.png',
//     'Order Booking': 'assets/images/orderbooking.png',
//     'Catalog': 'assets/images/catalog.png',
//     'Order Register': 'assets/images/register.png',
//     'Stock Report': 'assets/images/report.png',
//     'Dashboard': 'assets/images/dashboard.png',
//     'Setting': 'assets/images/setting.png',
//     'Delete Account': 'assets/images/deleteAccount.png',
//   };

//   // Fallback icons in case assets fail to load
//   final Map<String, IconData> _fallbackIcons = {
//     'Home': Icons.home,
//     'Order Booking': Icons.book,
//     'Catalog': Icons.category,
//     'Order Register': Icons.list_alt,
//     'Stock Report': Icons.assessment,
//     'Dashboard': Icons.dashboard,
//     'Setting': Icons.settings,
//     'Delete Account': Icons.delete_forever,
//   };

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _updateSelectedSection();
//   }

//   void _updateSelectedSection() {
//     final route = ModalRoute.of(context)?.settings.name;
//     setState(() {
//       selectedSection = _getSectionFromRoute(route);
//     });
//   }

//   String? _getSectionFromRoute(String? route) {
//     switch (route) {
//       case '/home':
//         return 'Home';
//       case '/orderbooking':
//         return 'Order Booking';
//       case '/catalog':
//         return 'Catalog';
//       case '/registerOrders':
//         return 'Order Register';
//       case '/stockReport':
//         return 'Stock Report';
//       case '/dashboard':
//         return 'Dashboard';
//       case '/setting':
//         return 'Setting';
//       case '/deleteAccount':
//         return 'Delete Account';
//       default:
//         return null;
//     }
//   }

//   void _navigateTo(String section, String route) {
//     if (selectedSection == section) {
//       Navigator.pop(context);
//       return;
//     }

//     setState(() => selectedSection = section);
//     Navigator.pop(context);
//     Navigator.pushReplacementNamed(context, route);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: FractionallySizedBox(
//         widthFactor: 0.6,
//         child: Drawer(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 40),
//               _buildUserProfile(),
//               const Divider(),
//               // ..._iconPaths.keys.map((title) => _buildDrawerItem(
//               //       title,
//               //       _getRouteFromSection(title),
//               //     )),
//               ..._iconPaths.keys
//                   .where((title) {
//                     if (UserSession.userType != 'C') return true;
//                     return title != 'Stock Report';
//                   })
//                   .map(
//                     (title) =>
//                         _buildDrawerItem(title, _getRouteFromSection(title)),
//                   ),

//               const Divider(),
//               _buildLogoutButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   String _getRouteFromSection(String section) {
//     switch (section) {
//       case 'Home':
//         return '/home';
//       case 'Order Booking':
//         return '/orderbooking';
//       case 'Catalog':
//         return '/catalog';
//       case 'Order Register':
//         return '/registerOrders';
//       case 'Stock Report':
//         return '/stockReport';
//       case 'Dashboard':
//         return '/dashboard';
//       case 'Setting':
//         return '/setting';
//       case 'Delete Account':
//         return '/deleteAccount';
//       default:
//         return '/home';
//     }
//   }

//   Widget _buildDrawerItem(String title, String route) {
//     final isSelected = selectedSection == title;
//     final isHovered = hoveredSection == title;
//     final iconPath = _iconPaths[title]!;

//     return MouseRegion(
//       onEnter: (_) => setState(() => hoveredSection = title),
//       onExit: (_) => setState(() => hoveredSection = null),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: () => _navigateTo(title, route),
//           child: Container(
//             decoration: BoxDecoration(
//               color:
//                   isSelected || isHovered
//                       ? const Color.fromARGB(255, 206, 222, 240)
//                       : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 0,
//               ),
//               leading: SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: Image.asset(
//                   iconPath,
//                   width: 24,
//                   height: 24,
//                   errorBuilder: (context, error, stackTrace) {
//                     // Fallback to icon if asset fails to load
//                     return Icon(
//                       _fallbackIcons[title]!,
//                       size: 24,
//                       color:
//                           isSelected || isHovered
//                               ? AppColors.primaryColor
//                               : Colors.grey[800],
//                     );
//                   },
//                 ),
//               ),
//               title: Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color:
//                       isSelected || isHovered
//                           ? AppColors.primaryColor
//                           : Colors.grey[800],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUserProfile() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 28,
//             backgroundImage: AssetImage(
//               'assets/images/logo.png',
//             ),
//             backgroundColor: Colors.grey[300],
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   UserSession.name ??
//                       'Guest', // Make sure `loginName` is set
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 // Text(
//                 //   UserSession.userType == 'C' ? 'Customer' : 'User',
//                 //   style: const TextStyle(fontSize: 13, color: Colors.grey),
//                 // ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLogoutButton() {
//     return MouseRegion(
//       onEnter: (_) => setState(() => hoveredSection = 'Logout'),
//       onExit: (_) => setState(() => hoveredSection = null),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: () {
//             Navigator.pop(context); // Close the drawer
//             Navigator.pushReplacementNamed(
//               context,
//               '/login',
//             ); // Navigate to login screen
//           },
//           child: Container(
//             decoration: BoxDecoration(
//               color:
//                   hoveredSection == 'Logout'
//                       ? const Color.fromARGB(255, 222, 187, 231)
//                       : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ListTile(
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: 0,
//               ),
//               leading: SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: Icon(
//                   Icons.exit_to_app,
//                   size: 24,
//                   color:
//                       hoveredSection == 'Logout'
//                           ? AppColors.primaryColor
//                           : Colors.grey[800],
//                 ),
//               ),
//               title: Text(
//                 'Logout',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color:
//                       hoveredSection == 'Logout'
//                           ? AppColors.primaryColor
//                           : Colors.grey[800],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/login_screen.dart';

class DrawerScreen extends StatefulWidget {
  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  String? selectedSection;
  String? hoveredSection;

  final Map<String, String> _iconPaths = {
    'Home': 'assets/images/home.png',
    'Dashboard': 'assets/images/dashboard.png',
    'Order Booking': 'assets/images/orderbooking.png',
    'Catalog': 'assets/images/catalog.png',
    'Order Register': 'assets/images/register.png',
    'Packing': 'assets/images/packing.png',
    'Packing Register': 'assets/images/packing_register.png',
    'Stock Report': 'assets/images/report.png',
    'Sale Bill': 'assets/images/salebill.png',
    'Sale Bill Register': 'assets/images/report.png',
    'Production': 'assets/images/production.png',
    'Setting': 'assets/images/setting.png',
    'Delete Account': 'assets/images/deleteAccount.png',
  };

  final Map<String, IconData> _fallbackIcons = {
    'Home': Icons.home,

    'Order Booking': Icons.shopping_cart_checkout,

    'Catalog': Icons.inventory_2,

    'Order Register': Icons.receipt_long,

    'Packing': Icons.inventory,

    'Packing Register': Icons.fact_check,

    'Stock Report': Icons.bar_chart,

    'Sale Bill': Icons.point_of_sale,

    'Sale Bill Register': Icons.menu_book,

    'Dashboard': Icons.dashboard_customize,

    'Production': Icons.precision_manufacturing,

    'Setting': Icons.settings,

    'Delete Account': Icons.delete_forever,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedSection();
  }

  void _updateSelectedSection() {
    final route = ModalRoute.of(context)?.settings.name;
    setState(() {
      selectedSection = _getSectionFromRoute(route);
    });
  }

  String? _getSectionFromRoute(String? route) {
    switch (route) {
      case '/home':
        return 'Home';
      case '/orderbooking':
        return 'Order Booking';
      case '/catalog':
        return 'Catalog';
      case '/registerOrders':
        return 'Order Register';
      case '/packingBooking':
        return 'Packing';
      case '/packingOrders':
        return 'Packing Register';
      case '/stockReport':
        return 'Stock Report';
      case '/SaleBillBookingScreen':
        return 'Sale Bill';
      case '/saleBillRegister':
        return 'Sale Bill Register';
      case '/dashboard':
        return 'Dashboard';
      case '/production':
        return 'Production';
      case '/setting':
        return 'Setting';
      case '/deleteAccount':
        return 'Delete Account';
      default:
        return null;
    }
  }

  void _navigateTo(String section, String route) {
    if (selectedSection == section) {
      Navigator.pop(context);
      return;
    }

    setState(() => selectedSection = section);
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final drawerWidth = screenWidth * (isLargeScreen ? 0.3 : 0.70);

    return Drawer(
      width: drawerWidth.clamp(260.0, 400.0),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          /// 🔵 GRADIENT PROFILE HEADER (Now covers status bar)
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 30, // ✅ Fix here
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(35),
              ),
            ),
            child: _buildProfileContent(),
          ),

          /// 🔹 REST CONTENT SAFE
          Expanded(
            child: SafeArea(
              top: false, // ✅ Important
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    ..._iconPaths.keys
                        .where((title) {
                          if (UserSession.userType != 'C') return true;
                          return title != 'Stock Report' &&
                              title != 'Dashboard';
                        })
                        .map(
                          (title) => _buildDrawerItem(
                            title,
                            _getRouteFromSection(title),
                          ),
                        ),

                    const Divider(thickness: 1),

                    _buildLogoutButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRouteFromSection(String section) {
    switch (section) {
      case 'Home':
        return '/home';
      case 'Order Booking':
        return '/orderbooking';
      case 'Catalog':
        return '/catalog';
      case 'Order Register':
        return '/registerOrders';
      case 'Packing':
        return '/packingBooking';
      case 'Packing Register':
        return '/packingOrders';
      case 'Stock Report':
        return '/stockReport';
      case 'Sale Bill':
        return '/SaleBillBookingScreen';
      case 'Sale Bill Register':
        return '/saleBillRegister';
      case 'Dashboard':
        return '/dashboard';
      case 'Production':
        return '/production';
      case 'Setting':
        return '/setting';
      case 'Delete Account':
        return '/deleteAccount';
      default:
        return '/home';
    }
  }

  Widget _buildProfileContent() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage('assets/images/logo.png'),
          backgroundColor: Colors.white,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UserSession.name ?? 'Guest',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                UserSession.userType == 'C' ? 'Customer' : 'User',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(String title, String route) {
    final isSelected = selectedSection == title;
    final isHovered = hoveredSection == title;
    final iconPath = _iconPaths[title]!;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredSection = title),
      onExit: (_) => setState(() => hoveredSection = null),
      child: InkWell(
        onTap: () => _navigateTo(title, route),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color:
                isSelected || isHovered
                    ? AppColors.primaryColor.withOpacity(0.10)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Image.asset(
              iconPath,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  _fallbackIcons[title]!,
                  color:
                      isSelected || isHovered
                          ? AppColors.primaryColor
                          : Colors.grey[800],
                );
              },
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    isSelected || isHovered
                        ? AppColors.primaryColor
                        : Colors.grey[800],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔴 LOGOUT BUTTON (Different Color)
  Widget _buildLogoutButton() {
    final isHovered = hoveredSection == 'Logout';

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredSection = 'Logout'),
      onExit: (_) => setState(() => hoveredSection = null),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/login');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:
                isHovered ? Colors.red.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red, // 🔴 Different color
              ),
            ),
          ),
        ),
      ),
    );
  }
}
