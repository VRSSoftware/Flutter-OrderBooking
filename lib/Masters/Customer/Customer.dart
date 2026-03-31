import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';

class CustomerMaster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerScreen(),
      appBar: AppBar(
        toolbarHeight: 48, // ✅ Decrease height (default is 56)

        title: Text(
          'Customer',
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

      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri("https://erptrading.vrsretail.in/customer"),
          ),
        ),
      ),
    );
  }
}
