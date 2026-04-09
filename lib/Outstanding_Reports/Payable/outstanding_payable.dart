import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class OutstandingPayablePage extends StatefulWidget {
  const OutstandingPayablePage({super.key});

  @override
  State<OutstandingPayablePage> createState() => _OutstandingPayablePageState();
}

class _OutstandingPayablePageState extends State<OutstandingPayablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        title: Text(
          'Outstanding Payable',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Text(
          'Outstanding Payable Page',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ),
    );
  }
}