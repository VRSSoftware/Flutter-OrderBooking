// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../constants/app_constants.dart';
// import 'login_screen.dart';

// class BaseUrlSettingsScreen extends StatefulWidget {
//   @override
//   State<BaseUrlSettingsScreen> createState() => _BaseUrlSettingsScreenState();
// }

// class _BaseUrlSettingsScreenState extends State<BaseUrlSettingsScreen> {
//   final TextEditingController _urlController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadBaseUrl();
//   }

//   Future<void> _loadBaseUrl() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? url = prefs.getString('base_url');
//     if (url != null) {
//       _urlController.text = url;
//     }
//   }

//   Future<void> _saveBaseUrl() async {
//     String inputUrl = _urlController.text.trim();
//     if (inputUrl.isNotEmpty) {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString('base_url', inputUrl);
//       AppConstants.BASE_URL = inputUrl;

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => LoginScreen()),
//         (route) => false,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Base URL Setting"),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               TextFormField(
//                 controller: _urlController,
//                 decoration: InputDecoration(
//                   labelText: 'Base URL',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveBaseUrl,
//                 child: const Text('Confirm'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'login_screen.dart';

class BaseUrlSettingsScreen extends StatefulWidget {
  @override
  State<BaseUrlSettingsScreen> createState() => _BaseUrlSettingsScreenState();
}

class _BaseUrlSettingsScreenState extends State<BaseUrlSettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('base_url');
    
    // If saved URL exists, use it; otherwise use the default from AppConstants
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _urlController.text = savedUrl;
    } else {
      // Set the default URL from AppConstants
      _urlController.text = AppConstants.BASE_URL ?? '';
    }
  }

  Future<void> _saveBaseUrl() async {
    String inputUrl = _urlController.text.trim();
    if (inputUrl.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('base_url', inputUrl);
      AppConstants.BASE_URL = inputUrl;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } else {
      // Show error if URL is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Base URL Setting"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'Enter base URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBaseUrl,
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}