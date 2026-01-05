import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static String BASE_URL = "http://192.168.0.20:8080/api/v1";
  static bool isLive = true;
//  static  String BASE_URL = "https://vrserp.com/vrs_erp_tjs/api/v1";
//  static  String BASE_URL = "https://vrserp.com/vrs_erp_tjs/api/v1";
  static  String? whatsappKey;
  // static  String Pdf_url = "http://gcubepdf.uniretailsoftware.com";
  // static  String Pdf_url = "https://localhost:44303";
  // static  String Pdf_url = "http://gcubepdf.uniretailsoftware.com/";
  static  String Pdf_url = "http://pdf.uniretailsoftware.com/";

}

class AppColors {
  // Primary color
  // static const Color primaryColor = Color(0xFF4A3780); // Primary (Purple shade)
  static const Color primaryColor = Colors.blue; // Primary (Purple shade)

  // Secondary color
  static const Color secondaryColor = Color.fromARGB(255, 249, 249, 250); // Secondary (Light Purple shade)

  // Base colors
  static const Color baseColor =  Color(0xFFbcb8ce);  // Base 

  // Additional colors
  static const Color darkBrown = Color(0xFF403100); // Dark Brown
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color lightBlue = Color(0xFFDBECF6); // Light Blue
  static const Color lightGray = Color(0xFFE5E9ED); // Light Gray
  static const Color veryLightGray = Color(0xFFF1F5F9); // Very Light Gray
  static const Color paleYellow = Color(0xFFFEF5D3); // Pale Yellow
  static const Color black = Color(0xFF000000); // Black
  static const Color darkPurple = Color(0xFF19062C); // Dark Purple shade
  static const Color softPurple = Color(0xFFd5ddef); // Soft Purple shade
  static const Color blue =Color(0xFF194A66); // Muted Lavender shade
  static const Color mutedPink = Color(0xFF917898); // Muted Pink shade
  static const Color deepPurple = Color(0xFF4c394f); // Deep Purple shade
  static const Color maroon = Color(0xFF2e1a1e); // Maroon shade
  static const Color red = Colors.red;
  static const Color accentColor = Colors.green;
  static const Color background = Colors.white;
  static const Color textColor = Colors.black87;
}
class UserSession {
  static int? userId=1;
  static String? coBrId='01';
  static String? userType='A';
  static String? userName='admin';
  static String? userLedKey='0159';
  static String? userFcYr='25';
  static String? name='Admin';
  static String? onlineImage='0';
  static String? imageDependsOn='D';
  static String? rptPath;
  static String? dbName;
  static String? dbUser;
  static String? dbPassword;
  static String? dbSource;
  static String? dbSourceForRpt;
  static String? coBrName;
  
  // static int? userId=1;
  // static String? coBrId='01';
  // static String? userType='A';
  // static String? userName='admin';
  // static String? userLedKey='0159';
  // static String? userFcYr='24';

  // Load from SharedPreferences after login
  // static Future<void> loadSession() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   userId = prefs.getInt("userId");
  //   coBrId = prefs.getString('coBrId');
  //   userType = prefs.getString('userType');
  //   userName = prefs.getString('userName');
  //   userLedKey = prefs.getString('ledKey');
  // }
}

