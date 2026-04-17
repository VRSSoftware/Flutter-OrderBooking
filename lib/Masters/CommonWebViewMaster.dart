import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class WebViewMaster extends StatelessWidget {
  final String title;
  final String urlPath;

  const WebViewMaster({
    super.key,
    required this.title,
    required this.urlPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          title,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 3,
        centerTitle: true,
      
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            // url: WebUri("https://erptrading.vrsretail.in/$urlPath"),
                url: WebUri("https://erptrading.vrsretail.in/$urlPath"),
          ),
        ),
      ),
    );
  }
}