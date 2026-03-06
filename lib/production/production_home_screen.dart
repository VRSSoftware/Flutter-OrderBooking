import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/jobCardListScreen.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
// Adjust import path as needed

// --- Colors from the new design ---
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

class ProductionHomeScreen extends StatefulWidget {
  @override
  _ProductionHomeScreenState createState() => _ProductionHomeScreenState();
}

class _ProductionHomeScreenState extends State<ProductionHomeScreen> {
  // Helper function to map button labels to icons and colors
  IconStyle _getIconStyle(String label) {
    switch (label) {
      case 'Job Card / Cutting Report':
        return IconStyle(
          Icons.assignment_turned_in,
          Colors.blue[500]!,
          Colors.blue[100]!,
        );
      case 'Process Issue (Job Card)':
        return IconStyle(
          Icons.precision_manufacturing,
          Colors.orange[500]!,
          Colors.orange[100]!,
        );
      default:
        return IconStyle(Icons.production_quantity_limits, Colors.grey[500]!, Colors.grey[100]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundLight,
      drawer: DrawerScreen(),
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          'Production',
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
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildProductionButtons(context, constraints.maxWidth),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen: '/production'),
    );
  }

  Widget _buildProductionButtons(BuildContext context, double screenWidth) {
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final spacing = 12.0;
    final totalSpacing = (crossAxisCount - 1) * spacing;
    final buttonWidth = (screenWidth - 32 - totalSpacing) / crossAxisCount;

    return Center(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.center,
        children: [
          _buildFeatureButton(
            context,
            'Job Card / Cutting Report',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => JobCardListScreen()),
              );
            },
            buttonWidth,
          ),
          _buildFeatureButton(
            context,
            'Process Issue (Job Card)',
            () {
              // Add navigation for Process Issue screen when available
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => ProcessIssueScreen()),
              // );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Process Issue screen coming soon!')),
              );
            },
            buttonWidth,
          ),
        ],
      ),
    );
  }

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
              width: 1.5,
            ),
            bottom: BorderSide(
              color: Color(0xFF800000),
              width: 1.5,
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
                    child: Icon(style.icon, size: 30, color: style.iconColor),
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