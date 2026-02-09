import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isTermsAccepted = false;
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> _deleteAccount(BuildContext dialogContext) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/deleteUserAccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "userName": UserSession.userName,
          "userPwd": _passwordController.text,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Use a stable context for the success dialog
        _showSuccessDialog(dialogContext);
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete account: ${response.statusCode} ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 60, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Confirm Delete',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Are you sure you want to permanently delete your account? This action cannot be undone.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -30,
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 30,
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showPasswordDialog(context);
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirm Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_passwordController.text.isNotEmpty) {
                        Navigator.of(context).pop();
                        // Pass a stable context (root navigator) to _deleteAccount
                        _deleteAccount(Navigator.of(context, rootNavigator: true).context);
                      } else {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your password'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 60, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Account Deleted',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your account has been successfully deleted.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: -30,
              child: CircleAvatar(
                backgroundColor: Colors.green,
                radius: 30,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to LoginScreen using root navigator
                        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     return WillPopScope(
      onWillPop: () async {
        // Navigate to DrawerScreen when back button is pressed
        Navigator.pushReplacementNamed(context, '/home');
        return false; // Prevent default back behavior
      },
      child:ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Delete Account', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Deletion Terms and Conditions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'By requesting to delete your account, you acknowledge and agree to the following:\n\n'
                      '1. **Permanent Data Removal**: All personal data associated with your account, including profile information, transaction history, and saved preferences, will be permanently deleted from our systems, except where retention is required by law.\n'
                      '2. **Loss of Access**: You will immediately lose access to all services, features, and benefits associated with your account, including any subscriptions, credits, or rewards.\n'
                      '3. **Irreversible Action**: Account deletion is permanent and cannot be undone. You will need to create a new account to use our services again.\n'
                      '4. **Legal Obligations**: Certain data may be retained as required by applicable laws or regulations (e.g., tax or audit purposes). Anonymized data may be used for analytics.\n'
                      '5. **Third-Party Services**: If your account is linked to third-party services, you are responsible for managing those connections separately.\n'
                      '6. **No Refunds**: Any remaining account balance, active subscriptions, or purchases will be forfeited without refund, unless otherwise required by law.\n\n'
                      'Please review these terms carefully before proceeding.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isTermsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _isTermsAccepted = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and agree to the account deletion terms and conditions',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _isTermsAccepted
                    ? () => _showConfirmationDialog(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Delete Account'),
              ),
            ),
          ],
        ),
      ),
     ));
  }
}