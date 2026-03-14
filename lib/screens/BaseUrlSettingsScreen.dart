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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedUrl = prefs.getString('base_url');
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _urlController.text = savedUrl;
      } else {
        _urlController.text = AppConstants.BASE_URL ?? '';
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBaseUrl() async {
    String inputUrl = _urlController.text.trim();
    if (inputUrl.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('base_url', inputUrl);
        AppConstants.BASE_URL = inputUrl;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid URL'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon Section
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.shade100,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: 60,
                      color: AppColors.primaryColor.shade700,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Base URL Configuration',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor.shade800,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Enter your server URL to connect',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // URL Input Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // URL Label with Icon
                          Row(
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 20,
                                color: AppColors.primaryColor.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Server URL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // URL TextField
                          TextField(
                            controller: _urlController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'https://your-server.com/api',
                              prefixIcon: Icon(
                                Icons.public_rounded,
                                color: Colors.grey.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Hint Text
                          Text(
                            'Include http:// or https://',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveBaseUrl,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor.shade700,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Confirm & Continue',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer Note
                  Text(
                    'This setting will be saved for future sessions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
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