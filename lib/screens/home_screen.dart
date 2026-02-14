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
        return IconStyle(Icons.style, Colors.green[500]!, Colors.green[100]!);
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
        return IconStyle(Icons.checklist, Colors.cyan[500]!, Colors.cyan[100]!);
      case 'Sale Bill Register':
        return IconStyle(Icons.receipt, Colors.teal[500]!, Colors.teal[100]!);
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
        case 'Production':
  return IconStyle(
    Icons.precision_manufacturing,   // 🏭 Factory gear icon
    kPrimaryColor,
    Colors.purple[100]!,
  );

      default:
        return IconStyle(Icons.grid_view, Colors.grey[500]!, Colors.grey[100]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundLight, // New background color
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

    return Center(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.center,
        children: [
          // We now call the new _buildFeatureButton
          _buildFeatureButton(context, 'Order Booking', () {
            Navigator.pushNamed(context, '/orderbooking');
          }, buttonWidth),
          _buildFeatureButton(context, 'Catalog', () {
            Navigator.pushNamed(context, '/catalog');
          }, buttonWidth),
          _buildFeatureButton(context, 'Order Register', () {
            Navigator.pushNamed(context, '/registerOrders');
          }, buttonWidth),
          _buildFeatureButton(context, 'Packing', () {
            Navigator.pushNamed(context, '/packingBooking');
          }, buttonWidth),
          _buildFeatureButton(context, 'Sale Bill', () {
            Navigator.pushNamed(context, '/SaleBillBookingScreen');
          }, buttonWidth),
          _buildFeatureButton(context, 'Packing Register', () {
            Navigator.pushNamed(context, '/packingOrders');
          }, buttonWidth),
          _buildFeatureButton(context, 'Sale Bill Register', () {
            Navigator.pushNamed(context, '/saleBillRegister');
          }, buttonWidth),
           _buildFeatureButton(context, 'Production', () {
            Navigator.pushNamed(context, '/production');
          }, buttonWidth),
          // --- Your Existing UserSession Logic ---
          UserSession.userType == 'A'
              ? _buildFeatureButton(context, 'Stock Report', () {
                Navigator.pushNamed(context, '/stockReport');
              }, buttonWidth)
              : Container(),
          UserSession.userType == 'A'
              ? _buildFeatureButton(context, 'Dashboard', () {
                Navigator.pushNamed(context, '/dashboard');
              }, buttonWidth)
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

  return SizedBox(
    width: width,
    child: Container(
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(
            color: Color(0xFF800000), 
            width: 1.5, // 🔥 Reduced
          ),
          bottom: BorderSide(
            color: Color(0xFF800000), 
            width: 1.5, // 🔥 Reduced
          ),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Card(
        color: kCardLight,
        elevation: 1.0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: style.backgroundColor,
                  child: Icon(
                    style.icon,
                    size: 30,
                    color: style.iconColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextLight,
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
