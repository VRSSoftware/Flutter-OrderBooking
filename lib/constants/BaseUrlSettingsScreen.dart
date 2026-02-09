import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/login_screen.dart';

class BaseUrlSettingsScreen extends StatefulWidget {
  @override
  _BaseUrlSettingsScreenState createState() => _BaseUrlSettingsScreenState();
}

class _BaseUrlSettingsScreenState extends State<BaseUrlSettingsScreen> {
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _rptBaseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUrls();
  }

  void _loadUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _baseUrlController.text = prefs.getString('BASE_URL') ?? AppConstants.BASE_URL ?? '';
      _rptBaseUrlController.text = prefs.getString('Pdf_url') ?? AppConstants.Pdf_url;
      _baseUrlController.text =  AppConstants.BASE_URL ?? "";
      _rptBaseUrlController.text = AppConstants.Pdf_url ?? "";
    });
  }

  void _saveUrlsAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('BASE_URL', _baseUrlController.text);
    await prefs.setString('Pdf_url', _rptBaseUrlController.text);

    // Update in AppConstants
    AppConstants.BASE_URL = _baseUrlController.text;
    AppConstants.Pdf_url = _rptBaseUrlController.text;

    // Navigate to LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _rptBaseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configure Base URLs"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                labelText: 'API Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _rptBaseUrlController,
              decoration: InputDecoration(
                labelText: 'Report Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveUrlsAndNavigate,
              child: Text('Done'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
