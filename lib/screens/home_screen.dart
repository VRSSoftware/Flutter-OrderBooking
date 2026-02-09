import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';

// --- Colors from the new design ---
// We'll assume light mode, as your original code was light.
const Color kPrimaryColor = Color(0xFF3B82F6);
const Color kBackgroundLight = Color(0xFFF8FAFC);
const Color kCardLight = Color(0xFFFFFFFF);
const Color kTextLight = Color(0xFF334155);
const Color kTextMutedLight = Color(0xFF64748B);

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

class _HomeScreenState extends State<HomeScreen> {
  // This helper function maps your labels to the new icons and colors
  // to match the design you wanted.
  IconStyle _getIconStyle(String label) {
    switch (label) {
      case 'Order Booking':
        return IconStyle(
          Icons.shopping_cart_checkout,
          kPrimaryColor,
          Colors.blue[100]!,
        );
      case 'Catalog':
        return IconStyle(
          Icons.style,
          Colors.green[500]!,
          Colors.green[100]!,
        );
      case 'Order Register':
        return IconStyle(
          Icons.app_registration,
          Colors.purple[500]!,
          Colors.purple[100]!,
        );
      case 'Packing':
        return IconStyle(
          Icons.inventory_2,
          Colors.orange[500]!,
          Colors.orange[100]!,
        );
      case 'Sale Bill':
        return IconStyle(
          Icons.receipt_long,
          Colors.red[500]!,
          Colors.red[100]!,
        );
      case 'Packing Register':
        return IconStyle(
          Icons.checklist,
          Colors.cyan[500]!,
          Colors.cyan[100]!,
        );
      case 'Sale Bill Register':
        return IconStyle(
          Icons.receipt,
          Colors.teal[500]!,
          Colors.teal[100]!,
        );
      case 'Stock Report':
        return IconStyle(
          Icons.assessment,
          Colors.yellow[700]!,
          Colors.yellow[100]!,
        );
      case 'Dashboard':
        return IconStyle(
          Icons.dashboard,
          Colors.indigo[500]!,
          Colors.indigo[100]!,
        );
      default:
        return IconStyle(
          Icons.grid_view,
          Colors.grey[500]!,
          Colors.grey[100]!,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundLight, // New background color
      drawer: DrawerScreen(),
      // --- New AppBar Styling ---
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.roboto(
            color: kTextLight,
            fontWeight: FontWeight.bold,
            fontSize: 20, // text-xl
          ),
        ),
        backgroundColor: kBackgroundLight,
        elevation: 1.0, // shadow-sm
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: kTextLight,
              size: 30, // text-3xl
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          
        ],
      ),
      // --- Your Existing Body Structure ---
      body: Padding(
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
      // --- Your Existing Bottom Nav Bar ---
      bottomNavigationBar: BottomNavigationWidget(
        currentScreen: '/home',
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

    return Center(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.center,
        children: [
          // We now call the new _buildFeatureButton
          _buildFeatureButton(
            context,
            'Order Booking',
            () {
              Navigator.pushNamed(context, '/orderbooking');
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Catalog',
            () {
              Navigator.pushNamed(context, '/catalog');
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Order Register',
            () {
              Navigator.pushNamed(context, '/registerOrders');
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Packing',
            () {
              Navigator.pushNamed(context, '/packingBooking');
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Sale Bill',
            () {
              Navigator.pushNamed(context, '/SaleBillBookingScreen');
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Packing Register',
            () {
              Navigator.pushNamed(context, '/packingOrders');
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Sale Bill Register',
            () {
              Navigator.pushNamed(context, '/saleBillRegister');
            },
            buttonWidth,
          ),
          // --- Your Existing UserSession Logic ---
          UserSession.userType == 'A'
              ? _buildFeatureButton(
                  context,
                  'Stock Report',
                  () {
                    Navigator.pushNamed(context, '/stockReport');
                  },
                  buttonWidth,
                )
              : Container(),
          UserSession.userType == 'A'
              ? _buildFeatureButton(
                  context,
                  'Dashboard',
                  () {
                    Navigator.pushNamed(context, '/dashboard');
                  },
                  buttonWidth,
                )
              : Container(),
        ],
      ),
    );
  }

  // --- REBUILT Feature Button to match new design ---
  Widget _buildFeatureButton(
    BuildContext context,
    String label,
    VoidCallback onTap,
    double width,
  ) {
    final style = _getIconStyle(label);
    
    // We use SizedBox to constrain the width to fit your Wrap layout
    return SizedBox(
      width: width,
      child: Card(
        color: kCardLight,
        elevation: 1.0, // shadow-sm
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // rounded-lg
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0), // p-4 equivalent
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28, // w-14 h-14
                  backgroundColor: style.backgroundColor,
                  child: Icon(
                    style.icon,
                    size: 30, // text-3xl
                    color: style.iconColor,
                  ),
                ),
                const SizedBox(height: 12), // mb-3
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto( // Using Roboto font
                    fontSize: 14, // text-sm
                    fontWeight: FontWeight.w500, // font-medium
                    color: kTextLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}