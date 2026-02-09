// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/screens/login_screen.dart';

// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _companyIdController = TextEditingController();
//   final TextEditingController _registrationIdController =
//       TextEditingController();
//   bool _isLoading = false;
//   String? deviceId;

//   final FocusNode _emailFocus = FocusNode();
//   final FocusNode _mobileFocus = FocusNode();
//   final FocusNode _companyIdFocus = FocusNode();
//   final FocusNode _registrationIdFocus = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _fetchDeviceInfo();
//   }

//   Future<void> _fetchDeviceInfo() async {
//     final deviceInfoPlugin = DeviceInfoPlugin();
//     try {
//       AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

//       setState(() {
//         deviceId = '${androidInfo.id}';
//       });

//       print("Build ID: ${androidInfo.id}");
//     } catch (e) {
//       print('Failed to get device info: $e');
//     }
//   }

//   Future<void> _saveDeviceIdToPrefs(String deviceId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('deviceId', deviceId);
//       await prefs.setString('isRegistered', '1');
//       print('Device ID saved to SharedPreferences: $deviceId');
//     } catch (e) {
//       print('Error saving device ID: $e');
//     }
//   }

//   Future<String> _register() async {
//     if (!_formKey.currentState!.validate()) {
//       return 'Form validation failed';
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final url = '${AppConstants.BASE_URL}/mobilebilling/register';

//       final requestBody = {
//         'serialNo': _registrationIdController.text.trim(),
//         'mobileNo': _mobileController.text.trim(),
//         'companyId': int.tryParse(_companyIdController.text.trim()) ?? 0,
//         'email': _emailController.text.trim(),
//         'deviceId': deviceId ?? '',
//       };

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(requestBody),
//       );

//       print("🔗 Request URL: $url");
//       print("Request Body: ${jsonEncode(requestBody)}");
//       print("Backend Response: ${response.body}");

//       String message;

//       try {
//         final responseBody = jsonDecode(response.body);
//         message = responseBody['message'] ?? 'Response received';
//       } catch (e) {
//         message = response.body;
//       }

//       await showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: Text("Registration Info"),
//               content: Text(message),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: Text("OK"),
//                 ),
//               ],
//             ),
//       );

//       if (response.statusCode == 200 && response.body == "Device successfully installed and activated.") {
//         // Save deviceId to SharedPreferences upon successful registration
//         if (deviceId != null) {
//           await _saveDeviceIdToPrefs(deviceId!);
//         }

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => LoginScreen()),
//         );
//         return 'Success';
//       } else {
//         return message;
//       }
//     } catch (e) {
//       final error = 'Error: $e';
//       await showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: Text("Error"),
//               content: Text(error),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: Text("OK"),
//                 ),
//               ],
//             ),
//       );
//       return error;
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _handleRegister() async {
//     if (_formKey.currentState!.validate()) {
//       String result = await _register();
//       print("🔍 Register result: $result");
//     } else {
//       // Find the first invalid field and focus on it
//       if (_emailController.text.isEmpty) {
//         _emailFocus.requestFocus();
//       } else if (_mobileController.text.isEmpty ||
//           _mobileController.text.length != 10) {
//         _mobileFocus.requestFocus();
//       } else if (_companyIdController.text.isEmpty) {
//         _companyIdFocus.requestFocus();
//       }
//     }
//   }

//   void goToLoginScreen() async {
//     String deviceId = '';
//     final deviceInfoPlugin = DeviceInfoPlugin();

//     try {
//       AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
//       deviceId = androidInfo.id;
//       print("Device ID: $deviceId");

//       // Save deviceId locally
//       await _saveDeviceIdToPrefs(deviceId);
//     } catch (e) {
//       print('Failed to get device info: $e');
//       return;
//     }

//     try {
//       final response = await http.get(
//         Uri.parse(
//           '${AppConstants.BASE_URL}/mobilebilling/checkDevice?deviceId=$deviceId',
//         ),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (response.statusCode == 200 && response.body.toLowerCase() == 'true') {
//         // Device is registered, go to login screen
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         await prefs.setString('isRegistered', '1');

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => LoginScreen()),
//         );
//       } else {
//         // Device not registered, show dialog
//         _showNotRegisteredDialog();
//       }
//     } catch (e) {
//       print('API error: $e');
//       _showNotRegisteredDialog();
//     }
//   }

//   void _showNotRegisteredDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible:
//           false, // Prevent dismissing the dialog when tapping outside
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Device Not Registered'),
//           content: const Text(
//             'This device is not registered. Please register first.',
//           ),
//           actions: [
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.pop(context); // Close dialog
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => RegisterScreen()),
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _emailFocus.dispose();
//     _mobileFocus.dispose();
//     _companyIdFocus.dispose();
//     _registrationIdFocus.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               physics:
//                   constraints.maxHeight < 600
//                       ? AlwaysScrollableScrollPhysics()
//                       : NeverScrollableScrollPhysics(),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         Stack(
//                           alignment: Alignment.bottomCenter,
//                           clipBehavior: Clip.none,
//                           children: [
//                             Image.asset(
//                               "assets/images/background.png",
//                               width: double.infinity,
//                               height: constraints.maxHeight * 0.23,
//                               fit: BoxFit.cover,
//                             ),
//                             Positioned(
//                               bottom: -40,
//                               child: CircleAvatar(
//                                 radius: 50,
//                                 backgroundColor: Colors.white,
//                                 child: ClipOval(
//                                   child: Image.asset(
//                                     "assets/images/new_logo.png",
//                                     width: 90,
//                                     height: 90,
//                                     fit: BoxFit.contain,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 50),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Text(
//                                 "Register Now",
//                                 style: TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               SizedBox(height: 8),
//                               _buildTextField(
//                                 "Email ID",
//                                 "",
//                                 _emailController,
//                                 (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Email is required';
//                                   }
//                                   return null;
//                                 },
//                                 focusNode: _emailFocus,
//                                 nextFocus: _mobileFocus,
//                               ),
//                               _buildTextField(
//                                 "Mobile No",
//                                 "",
//                                 _mobileController,
//                                 (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Mobile number is required';
//                                   }
//                                   if (value.length != 10) {
//                                     return 'Enter a valid 10-digit mobile number';
//                                   }
//                                   return null;
//                                 },
//                                 focusNode: _mobileFocus,
//                                 nextFocus: _companyIdFocus,
//                               ),
//                               _buildTextField(
//                                 "Company ID",
//                                 "",
//                                 _companyIdController,
//                                 (value) {
//                                   if (value!.isEmpty)
//                                     return 'Company Name is required';
//                                   return null;
//                                 },
//                                 focusNode: _companyIdFocus,
//                                 nextFocus: _registrationIdFocus,
//                               ),
//                               _buildTextField(
//                                 "Serial No",
//                                 "",
//                                 _registrationIdController,
//                                 (value) {
//                                   if (value == null || value.trim().isEmpty)
//                                     return 'Serial No is required';
//                                   return null;
//                                 },
//                                 focusNode: _registrationIdFocus,
//                                 isLastField: true,
//                                 textInputAction: TextInputAction.done,
//                               ),
//                               SizedBox(height: 15),
//                               if (deviceId != null)
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 10.0),
//                                   child: Text(
//                                     "Device ID: $deviceId",
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                       color: const Color.fromARGB(
//                                         221,
//                                         104,
//                                         103,
//                                         103,
//                                       ),
//                                     ),
//                                   ),
//                                 ),

//                               _buildRegisterButton(),
//                               TextButton(
//                                 onPressed: () {
//                                   goToLoginScreen();
//                                 },
//                                 child: RichText(
//                                   text: TextSpan(
//                                     text: "Already Registered? ",
//                                     style: TextStyle(
//                                       color: Colors.black,
//                                       fontSize: 14,
//                                     ),
//                                     children: [
//                                       TextSpan(
//                                         text: "Login here",
//                                         style: TextStyle(
//                                           color: AppColors.primaryColor,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Spacer(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     String hint,
//     TextEditingController controller,
//     String? Function(String?) validator, {
//     FocusNode? focusNode,
//     FocusNode? nextFocus,
//     bool isLastField = false,
//     TextInputAction textInputAction = TextInputAction.next,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//           ),
//           SizedBox(height: 3),
//           TextFormField(
//             controller: controller,
//             focusNode: focusNode,
//             textInputAction: textInputAction,
//             onFieldSubmitted: (value) {
//               if (!isLastField) {
//                 nextFocus?.requestFocus();
//               } else {
//                 // If it's the last field, remove focus
//                 focusNode?.unfocus();
//               }
//             },
//             decoration: InputDecoration(
//               hintText: hint,
//               contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: AppColors.primaryColor, width: 3.0),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide(color: AppColors.primaryColor, width: 2.0),
//               ),
//               isDense: true,
//               errorStyle: TextStyle(height: 0.9),
//             ),
//             validator: validator,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRegisterButton() {
//     return Container(
//       width: double.infinity,
//       height: 45,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(30),
//         gradient: LinearGradient(colors: [AppColors.primaryColor, AppColors.maroon]),
//       ),

//       child: ElevatedButton(
//         onPressed: _handleRegister,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(30),
//           ),
//         ),
//         child: Text(
//           "Register",
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _companyIdController = TextEditingController();
  final TextEditingController _registrationIdController =
      TextEditingController();
  bool _isLoading = false;
  String? deviceId;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _companyIdFocus = FocusNode();
  final FocusNode _registrationIdFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchDeviceInfo();
  }

  Future<void> _fetchDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;

      setState(() {
        deviceId = '${androidInfo.id}';
      });

      print("Build ID: ${androidInfo.id}");
    } catch (e) {
      print('Failed to get device info: $e');
    }
  }

  Future<void> _saveDeviceIdToPrefs(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deviceId', deviceId);
      await prefs.setString('isRegistered', '1');
      print('Device ID saved to SharedPreferences: $deviceId');
    } catch (e) {
      print('Error saving device ID: $e');
    }
  }

  Future<String> _register() async {
    if (!_formKey.currentState!.validate()) {
      return 'Form validation failed';
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${AppConstants.BASE_URL}/mobilebilling/register';

      final requestBody = {
        'serialNo': _registrationIdController.text.trim(),
        'mobileNo': _mobileController.text.trim(),
        'companyId': int.tryParse(_companyIdController.text.trim()) ?? 0,
        'email': _emailController.text.trim(),
        'deviceId': deviceId ?? '',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print("🔗 Request URL: $url");
      print("Request Body: ${jsonEncode(requestBody)}");
      print("Backend Response: ${response.body}");

      String message;

      try {
        final responseBody = jsonDecode(response.body);
        message = responseBody['message'] ?? 'Response received';
      } catch (e) {
        message = response.body;
      }

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Registration Info"),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
      );

      if (response.statusCode == 200 &&
          response.body == "Device successfully installed and activated.") {
        // Save deviceId to SharedPreferences upon successful registration
        if (deviceId != null) {
          await _saveDeviceIdToPrefs(deviceId!);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return 'Success';
      } else {
        return message;
      }
    } catch (e) {
      final error = 'Error: $e';
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text("Error"),
              content: Text(error),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            ),
      );
      return error;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      String result = await _register();
      print("🔍 Register result: $result");
    } else {
      // Find the first invalid field and focus on it
      if (_emailController.text.isEmpty) {
        _emailFocus.requestFocus();
      } else if (_mobileController.text.isEmpty ||
          _mobileController.text.length != 10) {
        _mobileFocus.requestFocus();
      } else if (_companyIdController.text.isEmpty) {
        _companyIdFocus.requestFocus();
      }
    }
  }

  void goToLoginScreen() async {
    String deviceId = '';
    final deviceInfoPlugin = DeviceInfoPlugin();

    try {
      // AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      // deviceId = androidInfo.id;
      // print("Device ID: $deviceId");
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = androidInfo.id;
        print("Android Device ID: ${androidInfo.id}");
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        print("iOS Identifier: ${iosInfo.identifierForVendor}");
      }

      // Save deviceId locally
      await _saveDeviceIdToPrefs(deviceId);
    } catch (e) {
      print('Failed to get device info: $e');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.BASE_URL}/mobilebilling/checkDevice?deviceId=$deviceId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.toLowerCase() == 'true') {
        // Device is registered, go to login screen
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('isRegistered', '1');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        // Device not registered, show dialog
        _showNotRegisteredDialog();
      }
    } catch (e) {
      print('API error: $e');
      _showNotRegisteredDialog();
    }
  }

  void _showNotRegisteredDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog when tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Device Not Registered'),
          content: const Text(
            'This device is not registered. Please register first.',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _companyIdFocus.dispose();
    _registrationIdFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics:
                  constraints.maxHeight < 600
                      ? AlwaysScrollableScrollPhysics()
                      : NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center vertically
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              "assets/images/background.png",
                              width: double.infinity,
                              height: constraints.maxHeight * 0.23,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: -40,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: Image.asset(
                                    "assets/images/new_logo.png",
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 50),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Register Now",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField(
                                "Email ID",
                                "",
                                _emailController,
                                (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  return null;
                                },
                                focusNode: _emailFocus,
                                nextFocus: _mobileFocus,
                              ),
                              _buildTextField(
                                "Mobile No",
                                "",
                                _mobileController,
                                (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mobile number is required';
                                  }
                                  if (value.length != 10) {
                                    return 'Enter a valid 10-digit mobile number';
                                  }
                                  return null;
                                },
                                focusNode: _mobileFocus,
                                nextFocus: _companyIdFocus,
                              ),
                              _buildTextField(
                                "Company ID",
                                "",
                                _companyIdController,
                                (value) {
                                  if (value!.isEmpty)
                                    return 'Company Name is required';
                                  return null;
                                },
                                focusNode: _companyIdFocus,
                                nextFocus: _registrationIdFocus,
                              ),
                              _buildTextField(
                                "Serial No",
                                "",
                                _registrationIdController,
                                (value) {
                                  if (value == null || value.trim().isEmpty)
                                    return 'Serial No is required';
                                  return null;
                                },
                                focusNode: _registrationIdFocus,
                                isLastField: true,
                                textInputAction: TextInputAction.done,
                              ),
                              SizedBox(height: 15),
                              if (deviceId != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Text(
                                    "Device ID: $deviceId",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color.fromARGB(
                                        221,
                                        104,
                                        103,
                                        103,
                                      ),
                                    ),
                                  ),
                                ),
                              _buildRegisterButton(),
                              TextButton(
                                onPressed: () {
                                  goToLoginScreen();
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: "Already Registered? ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Login here",
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool isLastField = false,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 3),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onFieldSubmitted: (value) {
              if (!isLastField) {
                nextFocus?.requestFocus();
              } else {
                focusNode?.unfocus();
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero, // Remove rounded corners
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero, // Remove rounded corners
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 3.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero, // Remove rounded corners
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 2.0,
                ),
              ),
              isDense: true,
              errorStyle: TextStyle(height: 0.9),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor, // Solid color, no gradient
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Remove rounded corners
          ),
        ),
        child:
            _isLoading
                ? CircularProgressIndicator()
                : Text(
                  "Register",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
      ),
    );
  }
}
