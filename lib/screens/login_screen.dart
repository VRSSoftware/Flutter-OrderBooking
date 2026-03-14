import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/BaseUrlSettingsScreen.dart';
import 'package:vrs_erp/screens/home_screen.dart';
import 'package:vrs_erp/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Map<String, dynamic>? _selectedCompany;
  Map<String, dynamic>? _selectedYear;

  final List<Map<String, dynamic>> _companies = [];
  final List<Map<String, dynamic>> _years = [];

  bool _isLoadingCompanies = true;
  bool _isLoading = false;

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _companyFocus = FocusNode();
  final FocusNode _yearFocus = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? isRegistered;

  @override
  void initState() {
    super.initState();
    _checkPreferences();
    _fetchCompanies();
    _fetchFinancialYears();
    setState(() {
      _passwordController.text = 'Admin';
      _usernameController.text = 'admin';
    });
  }

  Future<void> _checkPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isRegistered = prefs.getString('isRegistered');
      if (kIsWeb) {
        isRegistered = '1';
      }
    });
  }

  Future<void> _fetchCompanies() async {
    final url = '${AppConstants.BASE_URL}/users/cobr';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print("responsebody: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Initialize SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          _companies.clear();
          _companies.addAll(
            data.map((e) => e as Map<String, dynamic>).toList(),
          );
          _isLoadingCompanies = false;

          if (_companies.isNotEmpty && _companies.length == 1) {
            _selectedCompany = _companies[0];
            // Save to SharedPreferences and UserSession
            prefs.setString('coBrId', _selectedCompany?["coBrId"] ?? '');
            prefs.setString('coBrName', _selectedCompany?["coBr_name"] ?? '');
            UserSession.coBrId = _selectedCompany?["coBrId"];
            UserSession.coBrName = _selectedCompany?["coBr_name"];
          }
        });
      } else if (response.statusCode == 404) {
        await Future.delayed(const Duration(seconds: 2));
        _fetchCompanies(); // Retry on 404
      }
    } on SocketException catch (_) {
      // Retry on no internet
      await Future.delayed(const Duration(seconds: 2));
      _fetchCompanies();
    } on TimeoutException catch (_) {
      // Retry on request timeout
      await Future.delayed(const Duration(seconds: 2));
      _fetchCompanies();
    } catch (e) {
      setState(() {
        _isLoadingCompanies = false;
      });
      _showPopupMessage(context, "Error fetching companies: $e");
    }
  }

  Future<void> _fetchFinancialYears() async {
    final url = '${AppConstants.BASE_URL}/users/fcyr';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _years.clear();
          _years.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        });

        if (_years.isNotEmpty && _years.length == 1) {
          _selectedYear = _years[0];
        }
      } else if (response.statusCode == 404) {
        _fetchFinancialYears(); // Retry on 404
      }
    } on SocketException catch (_) {
      // Retry on no internet
      await Future.delayed(const Duration(seconds: 2));
      _fetchFinancialYears();
    } on TimeoutException catch (_) {
      // Retry on request timeout
      await Future.delayed(const Duration(seconds: 2));
      _fetchFinancialYears();
    } catch (e) {
      // Optionally log error
    }
  }

  Future<void> fetchOnlineImageSetting() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/images/isOnlineImage'),
      );
      if (response.statusCode == 200) {
        setState(() {
          if (response.body != '1') {
            UserSession.onlineImage = '0';
          } else {
            UserSession.onlineImage = response.body.trim();
          }
          print("Online Image Setting: ${UserSession.onlineImage}");
        });
      }
    } catch (e) {
      print("Error fetching online image setting: $e");
    }
  }

  Future<String> fetchAppSetting(String appSettId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/users/app-setting/$appSettId'),
      );

      if (response.statusCode == 200) {
        final String body = response.body.trim();

        // Optionally store in prefs or a session variable
        await prefs.setString('appSetting_$appSettId', body);

        return body; // ✅ returning the raw body
      } else {
        print(
          "Failed to fetch app setting ($appSettId): ${response.statusCode}",
        );
        if (context.mounted) {
          _showPopupMessage(
            context,
            "Failed to fetch app setting for ID: $appSettId",
          );
        }
      }
    } catch (e) {
      print("Error fetching app setting ($appSettId): $e");
      if (context.mounted) {
        _showPopupMessage(
          context,
          "Error fetching app setting. Please try again.",
        );
      }
    }

    return ""; // Return empty string if any failure
  }

  Future<void> fetchDatabaseCredentials() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/users/database-credentials'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          UserSession.dbName = data['dbName'];
          UserSession.dbUser = data['dbUserName'];
          UserSession.dbPassword = data['dbPassword'];
          UserSession.dbSource = data['dbSource'];
          // UserSession.dbSourceForRpt = data['dbSourceForRpt'];
          UserSession.dbSourceForRpt = data['dbSourceForRpt'];
        });

        // Print for debugging (remove in production)
        print('Database Credentials Loaded:');
        print('Name: ${UserSession.dbName}');
        print('User: ${UserSession.dbUser}');
        print('Source: ${UserSession.dbSource}');
        print('SourceForRpt: ${UserSession.dbSourceForRpt}');
      } else {
        print('Failed to load database credentials: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching database credentials: $e');
    }
  }

  Future<void> login(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (isRegistered == '1' || true) {
      if (_formKey.currentState?.validate() ?? false) {
        final url = '${AppConstants.BASE_URL}/users/login';
        final Map<String, String> headers = {
          'Content-Type': 'application/json',
        };
        final Map<String, String> body = {
          'userName': _usernameController.text.trim(),
          'userPwd': _passwordController.text.trim(),
        };

        try {
          final response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(body),
          );
          print("response body :${response.body}");
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = json.decode(
              response.body,
            );

            await prefs.setInt('userId', responseData["userId"]);
            await prefs.setString('coBrId', _selectedCompany?["coBrId"]);
            await prefs.setString('userType', responseData["userType"]);
            await prefs.setString('userName', responseData["userName"]);
            await prefs.setString('userLedKey', responseData["ledKey"]);

            UserSession.userId = responseData["userId"];
            UserSession.coBrId = _selectedCompany?["coBrId"];
            UserSession.userFcYr = _selectedYear?["fcYrId"];
            UserSession.userType = responseData["userType"];
            UserSession.userName = responseData["userName"];
            UserSession.userLedKey = responseData["ledKey"];
            UserSession.name = responseData["name"];

            if ((responseData['userName'] as String).trim() ==
                _usernameController.text.trim()) {
              await fetchOnlineImageSetting(); // API CALL HERE
              UserSession.rptPath = await fetchAppSetting('606');
              UserSession.imageDependsOn = await fetchAppSetting('577');
              AppConstants.whatsappKey = await fetchAppSetting('541');
              AppConstants.bookingType = await fetchAppSetting('731');
              AppConstants.whatsappType = await fetchAppSetting('732');
            //  AppConstants.bookingType = await fetchAppSetting('633');
              await fetchDatabaseCredentials();
              // print("Whatsapp Key: ${AppConstants.whatsappKey}");
              // print("RPT Path: ${UserSession.rptPath}");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else {
              _showPopupMessage(context, "Invalid Username or Password");
            }
          } else {
            final Map<String, dynamic> errorResponse = json.decode(
              response.body,
            );
            String errorMessage =
                errorResponse['errorMessage'] ?? "An error occurred";

            if (errorMessage.contains('Invalid UserName')) {
              _showPopupMessage(context, "Invalid Username");
            } else if (errorMessage.contains('Invalid Password')) {
              _showPopupMessage(context, "Invalid Password");
            } else {
              _showPopupMessage(context, errorMessage);
            }
          }
        } catch (e) {
          _showPopupMessage(context, "An error occurred. Please try again.");
        }
      } else {
        if (_usernameController.text.isEmpty) {
          _usernameFocus.requestFocus();
        } else if (_passwordController.text.isEmpty) {
          _passwordFocus.requestFocus();
        } else if (_selectedCompany == null) {
          _companyFocus.requestFocus();
        } else if (_selectedYear == null) {
          _yearFocus.requestFocus();
        }
      }
    } else {
      _showPopupMessage(
        context,
        "You have to register first. Device not registered",
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showPopupMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Login Failed"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _companyFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     resizeToAvoidBottomInset: false,
  //     body: SafeArea(
  //       child: LayoutBuilder(
  //         builder: (context, constraints) {
  //           return SingleChildScrollView(
  //             physics: constraints.maxHeight < 600
  //                 ? AlwaysScrollableScrollPhysics()
  //                 : NeverScrollableScrollPhysics(),
  //             child: ConstrainedBox(
  //               constraints: BoxConstraints(minHeight: constraints.maxHeight),
  //               child: IntrinsicHeight(
  //                 child: Form(
  //                   key: _formKey,
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.max,
  //                     children: [
  //                       Stack(
  //                         alignment: Alignment.bottomCenter,
  //                         clipBehavior: Clip.none,
  //                         children: [
  //                           Image.asset(
  //                             "assets/images/background.png",
  //                             width: double.infinity,
  //                             height: constraints.maxHeight * 0.23,
  //                             fit: BoxFit.cover,
  //                           ),
  //                           Positioned(
  //                             bottom: -40,
  //                             child: CircleAvatar(
  //                               radius: 50,
  //                               backgroundColor: Colors.white,
  //                               child: ClipOval(
  //                                 child: Image.asset(
  //                                   "assets/images/logo.png",
  //                                   width: 300,
  //                                   height: 350,
  //                                   fit: BoxFit.contain,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       SizedBox(height: 50),
  //                       Padding(
  //                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                         child: Column(
  //                           children: [
  //                             Text("Login Now", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //                             SizedBox(height: 8),
  //                             _buildTextField("User", "Enter your username", controller: _usernameController, focusNode: _usernameFocus, nextFocus: _passwordFocus, validator: (value) => value == null || value.isEmpty ? 'Username is required' : null),
  //                             _buildTextField("Password", "Enter your password", obscureText: true, controller: _passwordController, focusNode: _passwordFocus, nextFocus: _companyFocus, validator: (value) => value == null || value.isEmpty ? 'Password is required' : null),
  //                             _buildDropdown("Company", "Select your Company", items: _companies, value: _selectedCompany, focusNode: _companyFocus, nextFocus: _yearFocus, onChanged: (val) => setState(() => _selectedCompany = val), validator: (value) => value == null ? 'Please select a company' : null),
  //                             _buildDropdown("Year", "Select Year", items: _years, value: _selectedYear, focusNode: _yearFocus, onChanged: (val) => setState(() => _selectedYear = val), validator: (value) => value == null ? 'Please select a year' : null),
  //                             SizedBox(height: 8),
  //                             Container(
  //                               width: double.infinity,
  //                               height: 45,
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(30),
  //                                 gradient: LinearGradient(
  //                                   colors: [AppColors.primaryColor, AppColors.maroon],
  //                                   begin: Alignment.centerLeft,
  //                                   end: Alignment.centerRight,
  //                                 ),
  //                               ),
  //                               child: ElevatedButton(
  //                                 onPressed: () => login(context),
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: Colors.transparent,
  //                                   shadowColor: Colors.transparent,
  //                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //                                 ),
  //                                 child: Text("Log in", style: TextStyle(fontSize: 16, color: Colors.white)),
  //                               ),
  //                             ),
  //                             isRegistered == '1'
  //                                 ? Container()
  //                                 : TextButton(
  //                                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen())),
  //                                     child: RichText(
  //                                       text: TextSpan(
  //                                         text: "New user? ",
  //                                         style: TextStyle(color: Colors.black, fontSize: 14),
  //                                         children: [
  //                                           TextSpan(text: "Register here", style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ),
  //                           ],
  //                         ),
  //                       ),
  //                       Spacer(),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }
 // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white,
  //     resizeToAvoidBottomInset: false,
  //     appBar: AppBar(
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       actions: [
  //         IconButton(
  //           icon: Icon(Icons.settings, color: Colors.black),
  //           onPressed: () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(builder: (_) => BaseUrlSettingsScreen()),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //     body: SafeArea(
  //       child: LayoutBuilder(
  //         builder: (context, constraints) {
  //           return SingleChildScrollView(
  //             physics:
  //                 constraints.maxHeight < 600
  //                     ? AlwaysScrollableScrollPhysics()
  //                     : NeverScrollableScrollPhysics(),
  //             child: ConstrainedBox(
  //               constraints: BoxConstraints(minHeight: constraints.maxHeight),
  //               child: IntrinsicHeight(
  //                 child: Form(
  //                   key: _formKey,
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.max,
  //                     mainAxisAlignment:
  //                         MainAxisAlignment
  //                             .center, // Center the form vertically
  //                     children: [
  //                       Stack(
  //                         alignment: Alignment.bottomCenter,
  //                         clipBehavior: Clip.none,
  //                         children: [
  //                           Image.asset(
  //                             "assets/images/background.png",
  //                             width: double.infinity,
  //                             height: constraints.maxHeight * 0.23,
  //                             fit: BoxFit.cover,
  //                           ),
  //                           Positioned(
  //                             bottom: -40,
  //                             child: CircleAvatar(
  //                               radius: 50,
  //                               backgroundColor: Colors.white,
  //                               child: ClipOval(
  //                                 child: Image.asset(
  //                                   "assets/images/logo.png",
  //                                   width: 300,
  //                                   height: 350,
  //                                   fit: BoxFit.contain,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       SizedBox(height: 50),
  //                       Padding(
  //                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //                         child: Column(
  //                           children: [
  //                             Text(
  //                               "Login Now",
  //                               style: TextStyle(
  //                                 fontSize: 20,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                             SizedBox(height: 8),
  //                             _buildTextField(
  //                               "User",
  //                               "Enter your username",
  //                               controller: _usernameController,
  //                               focusNode: _usernameFocus,
  //                               nextFocus: _passwordFocus,
  //                               validator:
  //                                   (value) =>
  //                                       value == null || value.isEmpty
  //                                           ? 'Username is required'
  //                                           : null,
  //                             ),
  //                             _buildTextField(
  //                               "Password",
  //                               "Enter your password",
  //                               obscureText: true,
  //                               controller: _passwordController,
  //                               focusNode: _passwordFocus,
  //                               nextFocus: _companyFocus,
  //                               validator:
  //                                   (value) =>
  //                                       value == null || value.isEmpty
  //                                           ? 'Password is required'
  //                                           : null,
  //                             ),
  //                             _buildDropdown(
  //                               "Company",
  //                               "Select your Company",
  //                               items: _companies,
  //                               value: _selectedCompany,
  //                               focusNode: _companyFocus,
  //                               nextFocus: _yearFocus,
  //                               onChanged:
  //                                   (val) =>
  //                                       setState(() => _selectedCompany = val),
  //                               validator:
  //                                   (value) =>
  //                                       value == null
  //                                           ? 'Please select a company'
  //                                           : null,
  //                             ),
  //                             _buildDropdown(
  //                               "Year",
  //                               "Select Year",
  //                               items: _years,
  //                               value: _selectedYear,
  //                               focusNode: _yearFocus,
  //                               onChanged:
  //                                   (val) =>
  //                                       setState(() => _selectedYear = val),
  //                               validator:
  //                                   (value) =>
  //                                       value == null
  //                                           ? 'Please select a year'
  //                                           : null,
  //                             ),
  //                             SizedBox(height: 8),
  //                             Container(
  //                               width: double.infinity,
  //                               height: 45,
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(8),
  //                                 gradient: LinearGradient(
  //                                   colors: [
  //                                     AppColors.primaryColor,
  //                                     AppColors.maroon,
  //                                   ],
  //                                   begin: Alignment.centerLeft,
  //                                   end: Alignment.centerRight,
  //                                 ),
  //                               ),
  //                               child: ElevatedButton(
  //                                 onPressed:
  //                                     _isLoading
  //                                         ? null
  //                                         : () => login(
  //                                           context,
  //                                         ), // Disable button when loading
  //                                 style: ElevatedButton.styleFrom(
  //                                   backgroundColor: Colors.transparent,
  //                                   shadowColor: Colors.transparent,
  //                                   shape: RoundedRectangleBorder(
  //                                     borderRadius: BorderRadius.circular(8),
  //                                   ),
  //                                 ),
  //                                 child:
  //                                     _isLoading
  //                                         ? Row(
  //                                           mainAxisAlignment:
  //                                               MainAxisAlignment.center,
  //                                           mainAxisSize: MainAxisSize.min,
  //                                           children: [
  //                                             const Text(
  //                                               'Log in...',
  //                                               style: TextStyle(
  //                                                 fontSize: 16,
  //                                                 fontWeight: FontWeight.w500,
  //                                                 color:
  //                                                     Colors
  //                                                         .white, // Changed to white to match button theme
  //                                               ),
  //                                             ),
  //                                             const SizedBox(width: 12),
  //                                             const SizedBox(
  //                                               width: 20,
  //                                               height: 20,
  //                                               child: CircularProgressIndicator(
  //                                                 strokeWidth: 2.5,
  //                                                 color:
  //                                                     Colors
  //                                                         .white, // Changed to white to match button theme
  //                                               ),
  //                                             ),
  //                                           ],
  //                                         )
  //                                         : const Text(
  //                                           "Log in",
  //                                           style: TextStyle(
  //                                             fontSize: 16,
  //                                             color: Colors.white,
  //                                           ),
  //                                         ),
  //                               ),
  //                             ),
  //                             isRegistered == '1'
  //                                 ? Container()
  //                                 : TextButton(
  //                                   onPressed:
  //                                       () => Navigator.push(
  //                                         context,
  //                                         MaterialPageRoute(
  //                                           builder:
  //                                               (context) => RegisterScreen(),
  //                                         ),
  //                                       ),
  //                                   child: RichText(
  //                                     text: TextSpan(
  //                                       text: "New user? ",
  //                                       style: TextStyle(
  //                                         color: Colors.black,
  //                                         fontSize: 14,
  //                                       ),
  //                                       children: [
  //                                         TextSpan(
  //                                           text: "Register here",
  //                                           style: TextStyle(
  //                                             color: AppColors.primaryColor,
  //                                             fontWeight: FontWeight.bold,
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                 ),
  //                           ],
  //                         ),
  //                       ),
  //                       // Removed Spacer() to allow centering
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[300],
    resizeToAvoidBottomInset: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BaseUrlSettingsScreen()),
            );
          },
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 900;
          final isDesktop = screenWidth >= 900;
          
          // Responsive container width
          double containerWidth = isMobile 
              ? double.infinity 
              : (isTablet ? 500 : 450);
          
          // Responsive spacing
          double horizontalMargin = isMobile ? 16 : (isTablet ? 40 : 0);
          double verticalMargin = isMobile ? 8 : 20;
          
          return Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: containerWidth,
                margin: EdgeInsets.symmetric(
                  horizontal: horizontalMargin,
                  vertical: verticalMargin,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isMobile ? 0.08 : 0.1),
                      spreadRadius: isMobile ? 1 : 2,
                      blurRadius: isMobile ? 20 : 30,
                      offset: Offset(0, isMobile ? 10 : 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Responsive top decorative section
                      Container(
                        height: isMobile ? 60 : (isTablet ? 80 : 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryColor,
                              AppColors.Prime,
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(isMobile ? 16 : 30),
                            bottomRight: Radius.circular(isMobile ? 16 : 30),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Responsive decorative circles
                            Positioned(
                              top: -15,
                              right: -15,
                              child: Container(
                                width: isMobile ? 60 : (isTablet ? 80 : 100),
                                height: isMobile ? 40 : (isTablet ? 60 : 80),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -20,
                              left: -20,
                              child: Container(
                                width: isMobile ? 70 : (isTablet ? 90 : 120),
                                height: isMobile ? 70 : (isTablet ? 90 : 120),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                "VRS SOFTWARE",
                                style: TextStyle(
                                  fontSize: isMobile ? 20 : (isTablet ? 24 : 28),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form content with responsive padding
                      Form(
                        key: _formKey,
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 20 : 24)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Login header
                              // Text(
                              //   isMobile ? "LOGIN" : "LOGIN TO CONTINUE",
                              //   style: TextStyle(
                              //     fontSize: isMobile ? 16 : (isTablet ? 17 : 18),
                              //     fontWeight: FontWeight.w600,
                              //     color: Colors.grey.shade800,
                              //     letterSpacing: 1,
                              //   ),
                              // ),
                              
                              SizedBox(height: isMobile ? 4 : (isTablet ? 6 : 8)),
                              
                              // Subtitle - hide on mobile to save space
                              if (!isMobile)
                                Text(
                                  "Please enter your credentials",
                                  style: TextStyle(
                                    fontSize: isTablet ? 13 : 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              
                              SizedBox(height: isMobile ? 12 : (isTablet ? 16 : 24)),

                              // Form fields with responsive spacing
                              _buildResponsiveTextField(
                                "Username",
                                isMobile ? "Username" : "Enter your username",
                                controller: _usernameController,
                                focusNode: _usernameFocus,
                                nextFocus: _passwordFocus,
                                prefixIcon: Icons.person_outline,
                                validator: (value) => 
                                    value == null || value.isEmpty ? 'Required' : null,
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),

                              _buildResponsiveTextField(
                                "Password",
                                isMobile ? "Password" : "Enter your password",
                                obscureText: true,
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                nextFocus: _companyFocus,
                                prefixIcon: Icons.lock_outline,
                                validator: (value) => 
                                    value == null || value.isEmpty ? 'Required' : null,
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),

                              _buildResponsiveDropdown(
                                "Company",
                                isMobile ? "Select" : "Select your Company",
                                items: _companies,
                                value: _selectedCompany,
                                focusNode: _companyFocus,
                                nextFocus: _yearFocus,
                                prefixIcon: Icons.business_center_outlined,
                                onChanged: (val) => setState(() => _selectedCompany = val),
                                validator: (value) => value == null ? 'Required' : null,
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),

                              _buildResponsiveDropdown(
                                "Financial Year",
                                isMobile ? "Select" : "Select Year",
                                items: _years,
                                value: _selectedYear,
                                focusNode: _yearFocus,
                                prefixIcon: Icons.calendar_today_outlined,
                                onChanged: (val) => setState(() => _selectedYear = val),
                                validator: (value) => value == null ? 'Required' : null,
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),

                              SizedBox(height: isMobile ? 12 : (isTablet ? 14 : 16)),

                              // Responsive login button
                              Container(
                                width: double.infinity,
                                height: isMobile ? 44 : (isTablet ? 48 : 52),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.Prime,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryColor.withOpacity(isMobile ? 0.2 : 0.3),
                                      blurRadius: isMobile ? 6 : 10,
                                      offset: Offset(0, isMobile ? 3 : 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => login(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isLoading
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isMobile ? 'LOGIN...' : 'LOGGING IN...',
                                              style: TextStyle(
                                                fontSize: isMobile ? 14 : (isTablet ? 15 : 16),
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: isMobile ? 6 : 8),
                                            SizedBox(
                                              width: isMobile ? 16 : 18,
                                              height: isMobile ? 16 : 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: isMobile ? 2 : 2.5,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          isMobile ? "LOGIN" : "LOG IN",
                                          style: TextStyle(
                                            fontSize: isMobile ? 15 : (isTablet ? 15 : 16),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              SizedBox(height: isMobile ? 8 : (isTablet ? 10 : 12)),

                              // Register link
                              if (isRegistered != '1')
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isMobile ? 4 : 6,
                                      horizontal: 12,
                                    ),
                                    minimumSize: Size(0, isMobile ? 28 : 32),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      text: isMobile ? "New user? " : "New user? ",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: isMobile ? "Register" : "Register here",
                                          style: TextStyle(
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
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

// Responsive TextField
Widget _buildResponsiveTextField(
  String label,
  String hint, {
  bool obscureText = false,
  TextEditingController? controller,
  String? Function(String?)? validator,
  FocusNode? focusNode,
  FocusNode? nextFocus,
  IconData? prefixIcon,
  required bool isMobile,
  required bool isTablet,
}) {
  double verticalPadding = isMobile ? 10 : (isTablet ? 12 : 14);
  double fontSize = isMobile ? 13 : (isTablet ? 13 : 14);
  double iconSize = isMobile ? 18 : 20;
  double bottomPadding = isMobile ? 10 : (isTablet ? 12 : 16);
  
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: isMobile ? 4 : (isTablet ? 5 : 6)),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (value) => nextFocus?.requestFocus(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: fontSize,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 12,
            ),
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: AppColors.primaryColor, size: iconSize)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: isMobile ? 1.5 : 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            errorStyle: TextStyle(height: 1, fontSize: fontSize - 2),
          ),
          validator: validator,
        ),
      ],
    ),
  );
}

// Responsive Dropdown
Widget _buildResponsiveDropdown(
  String label,
  String hint, {
  required List<Map<String, dynamic>> items,
  required Map<String, dynamic>? value,
  required Function(Map<String, dynamic>?) onChanged,
  String? Function(Map<String, dynamic>?)? validator,
  FocusNode? focusNode,
  FocusNode? nextFocus,
  IconData? prefixIcon,
  required bool isMobile,
  required bool isTablet,
}) {
  double verticalPadding = isMobile ? 10 : (isTablet ? 12 : 14);
  double fontSize = isMobile ? 13 : (isTablet ? 13 : 14);
  double iconSize = isMobile ? 18 : 20;
  double bottomPadding = isMobile ? 10 : (isTablet ? 12 : 16);
  
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: isMobile ? 4 : (isTablet ? 5 : 6)),
        DropdownButtonFormField<Map<String, dynamic>>(
          value: value,
          focusNode: focusNode,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: fontSize,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 12,
            ),
            prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: AppColors.primaryColor, size: iconSize)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: isMobile ? 1.5 : 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          icon: Icon(
            Icons.arrow_drop_down, 
            color: AppColors.primaryColor, 
            size: iconSize + 2
          ),
          dropdownColor: Colors.white,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: fontSize,
          ),
          items: items.map((item) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: item,
              child: Text(
                item.containsKey('coBr_name')
                    ? item['coBr_name']
                    : item['fcYrName'],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize),
              ),
            );
          }).toList(),
          onChanged: (val) {
            onChanged(val);
            if (nextFocus != null) nextFocus.requestFocus();
          },
          validator: validator,
        ),
      ],
    ),
  );
}
}
