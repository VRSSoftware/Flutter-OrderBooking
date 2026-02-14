import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
     return WillPopScope(
      onWillPop: () async {
        // Navigate to DrawerScreen when back button is pressed
        Navigator.pushReplacementNamed(context, '/home');
        return false; // Prevent default back behavior
      },
      child:
     Scaffold(
           backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Privacy Policy', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:SafeArea(
  child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy for VRS ERP App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('1. Information We Collect'),
            _buildSectionContent(
              'Our app collects the following types of information to provide ERP services for garment businesses:',
            ),
            
            // Catalog Section
            _buildSubSection('Garment Catalog Data'),
            _buildSectionContent(
              'We collect garment product details such as item names, descriptions, sizes, colors, prices, and images. '
              'This data is used to maintain and display your product catalog within the app.',
            ),

            // Order Booking Section
            _buildSubSection('Order Booking Information'),
            _buildSectionContent(
              'We store customer details (name, contact info), order quantities, selected garments, and order timestamps. '
              'This information is used to process and track order bookings efficiently.',
            ),

            // Order Register Section
            _buildSubSection('Order Register Data'),
            _buildSectionContent(
              'We maintain a register of all orders, including order IDs, customer details, order status, and delivery dates. '
              'This helps in tracking and managing the order lifecycle.',
            ),

            // Stock Report Dashboard Section
            _buildSubSection('Stock Report Dashboard'),
            _buildSectionContent(
              'We collect and analyze stock levels, garment quantities, stock movement history, and replenishment data. '
              'This is used to generate stock reports and dashboards for inventory management and decision-making.',
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('2. Data Sharing'),
            _buildSectionContent(
              'We do not share personal or business information with third parties except:\n'
              '- Payment processors for transaction completion\n'
              '- Legal requirements when mandated by law\n'
              '- Authorized business partners for order fulfillment or logistics, with your consent',
            ),

            _buildSectionTitle('3. Data Security'),
            _buildSectionContent(
              'We implement industry-standard security measures to protect your data, including:\n'
              '- AES-256 encryption for sensitive information\n'
              '- Regular security audits to identify vulnerabilities\n'
              '- Role-based access control for user permissions\n'
              '- SSL/TLS for secure data transmission',
            ),

            _buildSectionTitle('4. User Rights'),
            _buildSectionContent(
              'Users have the right to:\n'
              '- Access their account and business data\n'
              '- Request correction of inaccurate data\n'
              '- Delete account and associated information\n'
              '- Export catalog, order, and stock data for backup or analysis',
            ),

            const SizedBox(height: 20),
            const Text(
              'Last Updated: May 30, 2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            const Text(
              'Contact us at: sales@vrssoftwares.com',
              style: TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ) )  ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildSubSection(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.5),
        textAlign: TextAlign.justify,
      ),
    );
  }
}