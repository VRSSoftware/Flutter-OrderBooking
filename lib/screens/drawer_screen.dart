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
//-----------------------------------------------------------------------------

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

  // Color palette for menu items
  final Map<String, Color> _menuColors = {
    'Home': Color(0xFF2196F3), // Blue
    'Dashboard': Color(0xFF9C27B0), // Purple
    'Order Booking': Color(0xFF4CAF50), // Green
    'Catalog': Color(0xFFFF9800), // Orange
    'Order Register': Color(0xFF009688), // Teal
    'Stock Report': Color(0xFF3F51B5), // Indigo
    'Setting': Color(0xFF607D8B), // Blue Grey
    'Delete Account': Color(0xFFF44336), // Red
  };

  final Map<String, String> _iconPaths = {
    'Home': 'assets/images/home.png',
    'Catalog': 'assets/images/catalog.png',
    'Order Booking': 'assets/images/orderbooking.png',
    'Order Register': 'assets/images/register.png',
    'Stock Report': 'assets/images/report.png',
    'Dashboard': 'assets/images/dashboard.png',
    'Setting': 'assets/images/setting.png',
    'Delete Account': 'assets/images/deleteAccount.png',
    // 'Sale Bill': 'assets/images/salebill.png',
    // 'Sale Bill Register': 'assets/images/sale.png',
    'Production': 'assets/images/production.png',
    //  'Packing': 'assets/images/packing.png',
    // 'Packing Register': 'assets/images/packing_register.pngg',
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
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final drawerWidth = screenWidth * (isLargeScreen ? 0.3 : 0.35);

    return Drawer(
      width: drawerWidth.clamp(230.0, 350.0),
      backgroundColor: Color(0xFF1A1A2E), // Dark navy background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Compact Header with Dark Theme
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10, // Reduced top space
              left: 16,
              right: 16,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkPurple, // Dark blue
                  AppColors.primaryColor, // Medium blue
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildProfileContent(),
          ),

          // Menu Items - No Scroll
          Expanded(
            child: Container(
              color: Color(0xFF1A1A2E), // Match drawer background
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 15),

                    // Main Menu Section
                    _buildSectionHeader('MAIN MENU'),
                    const SizedBox(height: 5),

                    ..._iconPaths.keys
                        .where((title) {
                          if (title == 'Stock Report' || title == 'Dashboard') {
                            return UserSession.userType == 'A';
                          }
                          return title != 'Setting' && title != 'Delete Account';
                        })
                        .map((title) => _buildDrawerItem(
                              title,
                              _getRouteFromSection(title),
                            )),

                    const SizedBox(height: 20),
                    
                    // Account Section
                    _buildSectionHeader('ACCOUNT'),
                    const SizedBox(height: 5),

                    _buildDrawerItem('Setting', '/setting'),
                    _buildDrawerItem('Delete Account', '/deleteAccount'),

                    const SizedBox(height: 20),
                    
                    // Logout Button
                    _buildLogoutButton(),

                    const SizedBox(height: 15),

                    // Version Info
                    Text(
                      'Version 2.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade800,
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
      // Profile Image
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage('assets/images/logo.png'),
          backgroundColor: Colors.white,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Company Name at the top
            Text(
              UserSession.coBrName?.toUpperCase() ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.lightBlue,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // User Name
             Text(
              UserSession.userName ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // User Type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: UserSession.userType == 'A' 
                    ? Colors.amber.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                UserSession.userType == 'C' 
                    ? 'CUSTOMER' 
                    : UserSession.userType == 'A' 
                        ? 'ADMIN' 
                        : 'SALESMAN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: UserSession.userType == 'A' 
                      ? Colors.amber 
                      : Colors.blue.shade300,
                  letterSpacing: 0.5,
                ),
              ),
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
    final itemColor = _menuColors[title] ?? AppColors.primaryColor;
    final iconPath = _iconPaths[title];

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredSection = title),
      onExit: (_) => setState(() => hoveredSection = null),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected || isHovered
              ? itemColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: itemColor.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateTo(title, route),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: iconPath != null
                        ? Image.asset(
                            iconPath,
                            width: 18,
                            height: 18,
                            color: isSelected || isHovered
                                ? itemColor
                                : Colors.grey.shade400,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _fallbackIcons[title] ?? Icons.help,
                                size: 18,
                                color: isSelected || isHovered
                                    ? itemColor
                                    : Colors.grey.shade400,
                              );
                            },
                          )
                        : Icon(
                            _fallbackIcons[title] ?? Icons.help,
                            size: 18,
                            color: isSelected || isHovered
                                ? itemColor
                                : Colors.grey.shade400,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected || isHovered
                            ? itemColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final isHovered = hoveredSection == 'Logout';

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredSection = 'Logout'),
      onExit: (_) => setState(() => hoveredSection = null),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isHovered ? Colors.red.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.logout,
                      size: 18,
                      color: isHovered ? Colors.red : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isHovered ? Colors.red : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}