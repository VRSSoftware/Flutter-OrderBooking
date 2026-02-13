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
//           borderRadius: BorderRadius.circular(0),
//           onTap: () => _navigateTo(title, route),
//           child: Container(
//             decoration: BoxDecoration(
//               color:
//                   isSelected || isHovered
//                       ? const Color.fromARGB(255, 206, 222, 240)
//                       : Colors.transparent,
//               borderRadius: BorderRadius.circular(0),
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
//           borderRadius: BorderRadius.circular(0),
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
//               borderRadius: BorderRadius.circular(0),
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
import 'package:vrs_erp/screens/login_screen.dart'; // Import your LoginScreen

class DrawerScreen extends StatefulWidget {
  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  String? selectedSection;
  String? hoveredSection;

  final Map<String, String> _iconPaths = {
    'Home': 'assets/images/home.png',
    'Order Booking': 'assets/images/orderbooking.png',
    'Catalog': 'assets/images/catalog.png',
    'Order Register': 'assets/images/register.png',
    'Stock Report': 'assets/images/report.png',
    'Dashboard': 'assets/images/dashboard.png',
     'Production' : 'assets/images/production.png',
    'Setting': 'assets/images/setting.png',
    'Delete Account': 'assets/images/deleteAccount.png',
   
  };

  final Map<String, IconData> _fallbackIcons = {
    'Home': Icons.home,
    'Order Booking': Icons.book,
    'Catalog': Icons.category,
    'Order Register': Icons.list_alt,
    'Stock Report': Icons.assessment,
    'Dashboard': Icons.dashboard,
    'Production' : Icons.production_quantity_limits,
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
      case '/stockReport':
        return 'Stock Report';
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
  final drawerWidth = screenWidth * (isLargeScreen ? 0.3 : 0.65); // Responsive drawer width

  return Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: drawerWidth.clamp(260.0, 400.0), // Clamp for better limits
      child: Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isLargeScreen ? 48 : 24),
                _buildUserProfile(),
                const Divider(),
                ..._iconPaths.keys
                    .where((title) {
                        if (UserSession.userType != 'C') return true;
                        return title != 'Stock Report' && title != 'Dashboard';
                      })
                    .map((title) => _buildDrawerItem(title, _getRouteFromSection(title))),
                const Divider(),
                _buildLogoutButton(),
                SizedBox(height: isLargeScreen ? 32 : 16),
              ],
            ),
          ),
        ),
      ),
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
      case 'Stock Report':
        return '/stockReport';
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

  Widget _buildDrawerItem(String title, String route) {
    final isSelected = selectedSection == title;
    final isHovered = hoveredSection == title;
    final iconPath = _iconPaths[title]!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredSection = title),
      onExit: (_) => setState(() => hoveredSection = null),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 16 : 8,
          vertical: isLargeScreen ? 8 : 4,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(0), // Softer corners for better UX
          onTap: () => _navigateTo(title, route),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected || isHovered
                  ? const Color.fromARGB(255, 206, 222, 240)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(0),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 24 : 16,
                vertical: isLargeScreen ? 8 : 4,
              ),
              leading: SizedBox(
                width: isLargeScreen ? 32 : 24,
                height: isLargeScreen ? 32 : 24,
                child: Image.asset(
                  iconPath,
                  width: isLargeScreen ? 32 : 24,
                  height: isLargeScreen ? 32 : 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _fallbackIcons[title]!,
                      size: isLargeScreen ? 32 : 24,
                      color: isSelected || isHovered
                          ? AppColors.primaryColor
                          : Colors.grey[800],
                    );
                  },
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected || isHovered
                      ? AppColors.primaryColor
                      : Colors.grey[800],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 24 : 16,
        vertical: isLargeScreen ? 16 : 10,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isLargeScreen ? 36 : 28,
            backgroundImage: const AssetImage('assets/images/logo.png'),
            backgroundColor: Colors.grey[300],
          ),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  UserSession.name ?? 'Guest',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 8 : 4),
                Text(
                  UserSession.userType == 'C' ? 'Customer' : 'User',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 14 : 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredSection = 'Logout'),
      onExit: (_) => setState(() => hoveredSection = null),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 16 : 8,
          vertical: isLargeScreen ? 8 : 4,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(0),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: Container(
            decoration: BoxDecoration(
              color: hoveredSection == 'Logout'
                  ? const Color.fromARGB(255, 222, 187, 231)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(0),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 24 : 16,
                vertical: isLargeScreen ? 8 : 4,
              ),
              leading: SizedBox(
                width: isLargeScreen ? 32 : 24,
                height: isLargeScreen ? 32 : 24,
                child: Icon(
                  Icons.exit_to_app,
                  size: isLargeScreen ? 32 : 24,
                  color: hoveredSection == 'Logout'
                      ? AppColors.primaryColor
                      : Colors.grey[800],
                ),
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: hoveredSection == 'Logout'
                      ? AppColors.primaryColor
                      : Colors.grey[800],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}