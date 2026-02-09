import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/login_screen.dart';
import 'package:vrs_erp/screens/register_screen.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
          if(!kIsWeb){  
      // isRegistered = '1';
    _fetchDeviceInfo();
      }
  }

  String? deviceId;

  Future<void> _checkPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? coBrId = prefs.getString('coBrId');
    int? userId = prefs.getInt('userId');

    String? isRegistered = prefs.getString('isRegistered');
    if (kIsWeb) {
      isRegistered = '1';
    }

    if (isRegistered == '1') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else if (isRegistered == null || isRegistered == '0') {
      try {
        final response = await http.get(
          Uri.parse(
            '${AppConstants.BASE_URL}/mobilebilling/checkDevice?deviceId=${deviceId}',
          ),
          headers: {'Content-Type': 'application/json'},
        );

        print("Response Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print("responseData");
          print(responseData);
          prefs.setString('isRegistered', '1');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RegisterScreen()),
          );
        }
      } catch (e) {
        print('Error: $e');
        // _showPopupMessage(context, "An error occurred. Please try again.");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RegisterScreen()),
      );
    }

    // if (userId != null) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => HomeScreen()),
    //   );
    // } else {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => LoginScreen()),
    //   );
    // }
  }

  Future<void> _fetchDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

      setState(() {
        deviceId = '${androidInfo.id}';
      });

      print("Build ID: ${androidInfo.id}");
      _checkPreferences();
    } catch (e) {
      print('Failed to get device info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/new_logo.png', width: 150, height: 150),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
