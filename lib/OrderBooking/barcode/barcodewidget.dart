// import 'package:flutter/material.dart';
// import 'package:vrs_erp/OrderBooking/barcode/barcode_scanner.dart';
// import 'package:vrs_erp/OrderBooking/barcode/bookonBarcode2.dart';
// import 'package:vrs_erp/constants/app_constants.dart';

// class BarcodeWiseWidget extends StatefulWidget {
//   final ValueChanged<String> onFilterPressed;

//   const BarcodeWiseWidget({super.key, required this.onFilterPressed});

//   @override
//   State<BarcodeWiseWidget> createState() => _BarcodeWiseWidgetState();
// }

// class _BarcodeWiseWidgetState extends State<BarcodeWiseWidget> {
//   final TextEditingController _barcodeController = TextEditingController();
//   List<Map<String, dynamic>> _barcodeResults = [];
//   List<String> addedItems = [];
//   Map<String, bool> _filters = {
//     'WSP': true,
//     'Sizes': true,
//     'Shades': true,
//     'StyleCode': true,
//   };
//   bool _noDataFound = false; // New state variable for no data

//   @override
//   void initState() {
//     super.initState();
//     _barcodeController.addListener(() {
//       final text = _barcodeController.text.toUpperCase();
//       if (_barcodeController.text != text) {
//         _barcodeController.value = _barcodeController.value.copyWith(
//           text: text,
//           selection: TextSelection.collapsed(offset: text.length),
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _barcodeController.dispose();
//     super.dispose();
//   }

//   void _showFilterPopup(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Select Fields to Show'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children:
//                 _filters.keys.map((key) {
//                   return CheckboxListTile(
//                     title: Text(key),
//                     value: _filters[key],
//                     onChanged: (bool? value) {
//                       setState(() {
//                         _filters[key] = value ?? true;
//                       });
//                       Navigator.pop(context);
//                       _showFilterPopup(context);
//                     },
//                   );
//                 }).toList(),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Done'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _scanBarcode() async {
//     final barcode = await Navigator.push<String>(
//       context,
//       MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
//     );

//     if (barcode != null && barcode.isNotEmpty) {
//       final upperBarcode = barcode.toUpperCase();
//       setState(() {
//         _barcodeController.text = upperBarcode;
//         _noDataFound = false; // Reset no data flag
//       });

//       _validateAndNavigate(upperBarcode);
//     }
//   }

//   void _validateAndNavigate(String barcode) async {
//     if (barcode.isEmpty) {
//       _showAlertDialog(
//         context,
//         'Missing Barcode',
//         'Please enter or scan a barcode first.',
//       );
//       return;
//     }

//     String upperBarcode = barcode.toUpperCase();
//     print("Checking barcode: $upperBarcode, addedItems: $addedItems");
//     if (addedItems.contains(upperBarcode)) {
//       _showAlertDialog(
//         context,
//         'Already Added',
//         'This barcode is already added',
//       );
//       return;
//     }

//     print("Navigating to BookOnBarcode2 with barcode: $upperBarcode");
//     final result = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => BookOnBarcode2(
//               barcode: upperBarcode,
//               onSuccess: () {
//                 setState(() {
//                   addedItems.add(upperBarcode);
//                   print(
//                     "Added barcode: $upperBarcode, addedItems: $addedItems",
//                   );
//                   _barcodeController.clear();
//                   _noDataFound = false; // Reset no data flag on success
//                 });
//               },
//               onCancel: () {
//                 _barcodeController
//                     .clear(); // This will clear the barcode text field
//               },
//             ),
//       ),
//     );

//     // Check the result from BookOnBarcode2
//     if (result == false) {
//       setState(() {
//         _noDataFound = true; // Set no data flag
//       });
//     } else {
//       setState(() {
//         _noDataFound = false; // Reset no data flag
//       });
//     }
//   }

//   void _showAlertDialog(BuildContext context, String title, String message) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text(title),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextFormField(
//                     controller: _barcodeController,
//                     decoration: InputDecoration(
//                       labelText: "Enter Barcode",
//                       labelStyle: const TextStyle(fontSize: 14),
//                       isDense: true,
//                       contentPadding: const EdgeInsets.symmetric(
//                         vertical: 6.0,
//                         horizontal: 14.0,
//                       ),
//                       filled: true,
//                       fillColor: const Color(0xFFF6F8FA),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 GestureDetector(
//                   onTap: _scanBarcode,
//                   child: Image.asset(
//                     'assets/images/barcode.png',
//                     width: 40,
//                     height: 40,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 12.0,
//               vertical: 12.0,
//             ),
//             child: Center(
//               child: GestureDetector(
//                 onTap: () {
//                   _validateAndNavigate(_barcodeController.text.trim());
//                 },
//                 child: Container(
//                   height: 38,
//                   width: 140,
//                   decoration: BoxDecoration(
//                     border: Border.all(
//                       color: AppColors.primaryColor,
//                       width: 1.5,
//                     ),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       // Left diagonal area with "SEARCH"
//                       Expanded(
//                         child: ClipPath(
//                           clipper: DiagonalClipper(),
//                           child: Container(
//                             color: AppColors.primaryColor,
//                             alignment: Alignment.center,
//                             child: const Text(
//                               'SEARCH',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                                 letterSpacing: 1.2,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       // Icon section
//                       Container(
//                         width: 38,
//                         alignment: Alignment.center,
//                         child: Icon(
//                           Icons.search,
//                           color: AppColors.primaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // Show "No Data Found" message if applicable
//           if (_noDataFound)
//             const Padding(
//               padding: EdgeInsets.all(12.0),
//               child: Center(
//                 child: Text(
//                   "No Data Found",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.red,
//                   ),
//                 ),
//               ),
//             ),
//           // Only show results if _barcodeResults is not empty
//           if (_barcodeResults.isNotEmpty) ...[
//             const Padding(
//               padding: EdgeInsets.all(12.0),
//               child: Text(
//                 "Barcode Results:",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 columns: [
//                   if (_filters['StyleCode'] == true)
//                     const DataColumn(label: Text("Style Code")),
//                   if (_filters['WSP'] == true)
//                     const DataColumn(label: Text("WSP")),
//                   if (_filters['Sizes'] == true)
//                     const DataColumn(label: Text("Size")),
//                   if (_filters['Shades'] == true)
//                     const DataColumn(label: Text("Shade")),
//                 ],
//                 rows:
//                     _barcodeResults.map((result) {
//                       return DataRow(
//                         cells: [
//                           if (_filters['StyleCode'] == true)
//                             DataCell(
//                               Text(result['StyleCode']?.toString() ?? ''),
//                             ),
//                           if (_filters['WSP'] == true)
//                             DataCell(Text(result['WSP']?.toString() ?? '')),
//                           if (_filters['Sizes'] == true)
//                             DataCell(Text(result['Size']?.toString() ?? '')),
//                           if (_filters['Shades'] == true)
//                             DataCell(Text(result['Shade']?.toString() ?? '')),
//                         ],
//                       );
//                     }).toList(),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// class DiagonalClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();
//     path.lineTo(size.width - 20, 0);
//     path.lineTo(size.width, size.height);
//     path.lineTo(0, size.height);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/OrderBooking/barcode/QRCodeScannerScreen.dart';
import 'package:vrs_erp/OrderBooking/barcode/barcode_scanner.dart';
import 'package:vrs_erp/OrderBooking/barcode/bookOnBarcode1.dart';
import 'package:vrs_erp/OrderBooking/barcode/bookonBarcode2.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class BarcodeWiseWidget extends StatefulWidget {
  final ValueChanged<String> onFilterPressed;
  final VoidCallback? onOrderConfirmed;
  final bool edit;

  const BarcodeWiseWidget({
    super.key,
    required this.onFilterPressed,
    this.onOrderConfirmed,
    this.edit = false,
  });

  @override
  State<BarcodeWiseWidget> createState() => _BarcodeWiseWidgetState();
}

class _BarcodeWiseWidgetState extends State<BarcodeWiseWidget> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();
  List<Map<String, dynamic>> _barcodeResults = [];
  List<String> addedItems = [];
  Map<String, bool> _filters = {
    'WSP': true,
    'Sizes': true,
    'Shades': true,
    'StyleCode': true,
  };

  // Continuous scan variables
  bool _continuousScan = false;
  List<Map<String, dynamic>> _scannedBarcodes =
      []; // Store with validation status
  Set<String> _scannedSet = {};
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _barcodeController.addListener(_handleBarcodeInput);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _handleBarcodeInput() {
    final text = _barcodeController.text;
    final upperText = text.toUpperCase();
    if (text != upperText) {
      _barcodeController.value = _barcodeController.value.copyWith(
        text: upperText,
        selection: TextSelection.collapsed(offset: upperText.length),
      );
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      bool isDialogOpen = ModalRoute.of(context)?.isCurrent != true;

      if (!isDialogOpen) {
        final barcode = _barcodeController.text.trim();
        if (barcode.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeController.clear();
            if (_continuousScan) {
              _addBarcodeToList(barcode);
            } else {
              _validateAndNavigate(barcode);
            }
          });
        }
      }
    }
  }

  // NEW: Add barcode to continuous scan list
  Future<void> _addBarcodeToList(String barcode) async {
    if (_isValidating) return;

    String upperBarcode = barcode.toUpperCase();

    // Check if already added in current session (in cart)
    if (addedItems.contains(upperBarcode)) {
      _showAlertDialog(
        context,
        'Already Added',
        'This barcode is already in cart: $upperBarcode',
      );
      return;
    }

    // Check if already in current scan list
    if (_scannedSet.contains(upperBarcode)) {
      _showAlertDialog(
        context,
        'Already in List',
        'Already scanned: $upperBarcode',
      );
      return;
    }

    // Add with pending status
    setState(() {
      _scannedBarcodes.add({'barcode': upperBarcode, 'status': 'pending'});
      _scannedSet.add(upperBarcode);
    });

    // Validate the barcode
    _validateBarcode(upperBarcode);
  }

  // NEW: Validate a barcode and update its status
  Future<void> _validateBarcode(String barcode) async {
    setState(() {
      _isValidating = true;
    });

    String status = await _checkBarcodeExists(barcode);

    if (!mounted) return;

    setState(() {
      int index = _scannedBarcodes.indexWhere(
        (item) => item['barcode'] == barcode,
      );
      if (index != -1) {
        if (status == "1") {
          _scannedBarcodes[index]['status'] = 'valid';
        } else if (status == "2" || status == "10") {
          _scannedBarcodes[index]['status'] = 'already_added';
        } else {
          _scannedBarcodes[index]['status'] = 'invalid';
        }
      }
      _isValidating = false;
    });

    // Show feedback
    if (status == "1") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Added: $barcode'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: Colors.green,
        ),
      );
    } else if (status == "2" || status == "10") {
      _showAlertDialog(context, 'Already Added', 'Already in cart: $barcode');
    } else {
      _showAlertDialog(context, 'Invalid', 'No data found: $barcode');
    }
  }

  // NEW: Show scanned barcodes list in bottom sheet
  void _showScannedList() {
    if (_scannedBarcodes.isEmpty) {
      _showAlertDialog(context, 'Empty List', 'No barcodes scanned yet.');
      return;
    }

    // Filter only valid barcodes
    List<Map<String, dynamic>> validBarcodes =
        _scannedBarcodes.where((item) => item['status'] == 'valid').toList();

    if (validBarcodes.isEmpty) {
      _showAlertDialog(
        context,
        'No Valid Barcodes',
        'No valid barcodes to process.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Scanned Barcodes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${validBarcodes.length} valid',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // List of barcodes
                    Expanded(
                      child: ListView.builder(
                        itemCount: _scannedBarcodes.length,
                        itemBuilder: (context, index) {
                          final item = _scannedBarcodes[index];
                          final barcode = item['barcode'];
                          final status = item['status'];

                          Color statusColor;
                          IconData statusIcon;
                          String statusText;

                          switch (status) {
                            case 'valid':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              statusText = 'Valid';
                              break;
                            case 'pending':
                              statusColor = Colors.orange;
                              statusIcon = Icons.hourglass_empty;
                              statusText = 'Checking...';
                              break;
                            case 'already_added':
                              statusColor = Colors.red;
                              statusIcon = Icons.warning;
                              statusText = 'Already in Cart';
                              break;
                            default:
                              statusColor = Colors.red;
                              statusIcon = Icons.error;
                              statusText = 'Invalid';
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(color: statusColor),
                              ),
                            ),
                            title: Text(
                              barcode,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 14,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _scannedSet.remove(barcode);
                                      _scannedBarcodes.removeAt(index);
                                    });
                                    setStateSheet(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    // Action buttons with bottom padding for home indicator
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Clear All'),
                                        content: Text(
                                          'Clear all ${_scannedBarcodes.length} barcodes?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _scannedBarcodes.clear();
                                                _scannedSet.clear();
                                              });
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            child: const Text(
                                              'Clear',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _processValidBarcodes();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                              ),
                              child: Text(
                                'Confirm (${validBarcodes.length})',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // NEW: Process all valid barcodes and open BookOnBarcode1
  Future<void> _processValidBarcodes() async {
    List<String> validBarcodes =
        _scannedBarcodes
            .where((item) => item['status'] == 'valid')
            .map((item) => item['barcode'] as String)
            .toList();

    if (validBarcodes.isEmpty) {
      _showAlertDialog(
        context,
        'No Valid Barcodes',
        'No valid barcodes to process.',
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Prepare barcodes string (comma-separated for API)
    String allBarcodes = validBarcodes.join(',');

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    Widget screen;

    if (AppConstants.bookingType == "1") {
      screen = BookOnBarcode1(
        barcode: allBarcodes,
        onSuccess: () {
          setState(() {
            // Add all valid barcodes to added items
            for (String barcode in validBarcodes) {
              addedItems.add(barcode);
            }
            // Clear the scanned list
            _scannedBarcodes.clear();
            _scannedSet.clear();
            _barcodeController.clear();
          });

          if (widget.onOrderConfirmed != null) {
            widget.onOrderConfirmed!();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        onCancel: () {
          _barcodeController.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        edit: widget.edit,
      );
    } else {
      screen = BookOnBarcode2(
        barcode: allBarcodes,
        onSuccess: () {
          setState(() {
            for (String barcode in validBarcodes) {
              addedItems.add(barcode);
            }
            _scannedBarcodes.clear();
            _scannedSet.clear();
            _barcodeController.clear();
          });

          if (widget.onOrderConfirmed != null) {
            widget.onOrderConfirmed!();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        onCancel: () {
          _barcodeController.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        edit: widget.edit,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // UPDATED: Scan barcode with continuous scan support
  Future<void> _scanBarcode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
    );

    if (result != null && result.isNotEmpty) {
      for (String barcode in result) {
        if (_continuousScan) {
          _addBarcodeToList(barcode);
        } else {
          _validateAndNavigate(barcode);
          break; // Only process first barcode in single mode
        }
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _barcodeFocusNode.requestFocus();
      });
    }
  }

  // UPDATED: Scan QR code with continuous scan support
  Future<void> _scanQRCode() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(builder: (context) => QRCodeScannerScreen()),
    );

    if (result != null && result.isNotEmpty) {
      for (String barcode in result) {
        if (_continuousScan) {
          _addBarcodeToList(barcode);
        } else {
          _validateAndNavigate(barcode);
          break; // Only process first barcode in single mode
        }
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _barcodeFocusNode.requestFocus();
      });
    }
  }

  // EXISTING: Single barcode validation (unchanged)
  void _validateAndNavigate(String barcode) async {
    if (barcode.isEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();
      _showAlertDialog(
        context,
        'Missing Barcode',
        'Please enter or scan a barcode first.',
      );
      return;
    }

    String upperBarcode = barcode.toUpperCase();

    if (addedItems.contains(upperBarcode)) {
      FocusManager.instance.primaryFocus?.unfocus();
      _showAlertDialog(
        context,
        'Already Added',
        'This barcode is already added: $upperBarcode',
      );
      _barcodeController.clear();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Checking barcode...'),
                ],
              ),
            ),
          ),
    );

    String barcodeStatus = await _checkBarcodeExists(upperBarcode);

    if (!mounted) return;
    Navigator.pop(context);

    if (barcodeStatus == "0") {
      FocusManager.instance.primaryFocus?.unfocus();
      _showAlertDialog(
        context,
        'No Data Found',
        'No data found for barcode: $upperBarcode',
      );
      _barcodeController.clear();
      return;
    } else if (barcodeStatus == "2" || barcodeStatus == "10") {
      FocusManager.instance.primaryFocus?.unfocus();
      _showAlertDialog(
        context,
        'Already Added',
        'This barcode is already added in the cart.',
      );
      _barcodeController.clear();
      return;
    } else if (barcodeStatus.contains("already added in cart")) {
      // Already added in cart (from API)
      FocusManager.instance.primaryFocus?.unfocus();
      _showAlertDialog(context, 'Already Added', barcodeStatus);
      _barcodeController.clear();
      return;
    } else if (barcodeStatus.contains("No data found for barcode")) {
      // Already added in cart (from API)
      FocusManager.instance.primaryFocus?.unfocus();
      _showAlertDialog(context, 'Already Added', barcodeStatus);
      _barcodeController.clear();
      return;
    }

    Widget screen;

    if (AppConstants.bookingType == "1") {
      screen = BookOnBarcode1(
        barcode: upperBarcode,
        onSuccess: () {
          setState(() {
            addedItems.add(upperBarcode);
            _barcodeController.clear();
          });

          if (widget.onOrderConfirmed != null) {
            widget.onOrderConfirmed!();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        onCancel: () {
          _barcodeController.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        edit: widget.edit,
      );
    } else {
      screen = BookOnBarcode2(
        barcode: upperBarcode,
        onSuccess: () {
          setState(() {
            addedItems.add(upperBarcode);
            _barcodeController.clear();
          });

          if (widget.onOrderConfirmed != null) {
            widget.onOrderConfirmed!();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        onCancel: () {
          _barcodeController.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _barcodeFocusNode.requestFocus();
          });
        },
        edit: widget.edit,
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // EXISTING: Check barcode exists (unchanged)
  Future<String> _checkBarcodeExists(String barcode) async {
    String apiUrl = '';
    if (widget.edit) {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetailsUpdated';
    } else {
      apiUrl = '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails';
    }

    final Map<String, dynamic> requestBody = {
      "coBrId": UserSession.coBrId ?? '',
      "userId": UserSession.userName ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "barcode": barcode,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return "1";
        } else {
          return "0";
        }
      } else if (response.statusCode == 409) {
        return response.body.isNotEmpty
            ? response.body
            : "Something went wrong";
      } else if (response.statusCode == 404) {
        return response.body.isNotEmpty
            ? response.body
            : "Something went wrong";
      } else if (response.statusCode == 500) {
        if (response.body.contains('Barcode already added')) {
          return "2";
        }
      }
      debugPrint(
        "Unexpected response: ${response.statusCode} - ${response.body}",
      );
    } catch (e) {
      print('Error checking barcode: $e');
    }

    return "0";
  }

  // EXISTING: Show alert dialog (unchanged)
  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _barcodeFocusNode.requestFocus();
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
              child: const Text('OK'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  // EXISTING: Refresh added items (unchanged)
  Future<void> _refreshAddedItems() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/GetViewOrder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "coBrId": UserSession.coBrId ?? '',
          "userId": UserSession.userName ?? '',
          "fcYrId": UserSession.userFcYr ?? '',
          "barcode": "true",
        }),
      );

      if (response.statusCode == 200) {
        final List cartItems = json.decode(response.body);
        Set<String> currentBarcodes = {};
        for (var item in cartItems) {
          if (item['barcode'] != null &&
              item['barcode'].toString().isNotEmpty) {
            currentBarcodes.add(item['barcode'].toString().toUpperCase());
          }
        }

        setState(() {
          addedItems = currentBarcodes.toList();
        });
      }
    } catch (e) {
      print('Error refreshing added items: $e');
    }
  }

  // UPDATED: Build method with dynamic button
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Continuous Scan Checkbox - Matching the "Order Booking Barcode Wise" style
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
            ), // Changed from 12 to 8 to match
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _continuousScan,
                  onChanged: (value) {
                    setState(() {
                      _continuousScan = value ?? false;
                      if (!_continuousScan && _scannedBarcodes.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Clear List?'),
                                content: Text(
                                  'You have ${_scannedBarcodes.length} barcode(s). Clear them?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _scannedBarcodes.clear();
                                        _scannedSet.clear();
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Clear'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Keep'),
                                  ),
                                ],
                              ),
                        );
                      }
                    });
                  },
                  activeColor: AppColors.primaryColor,
                ),
                const Text(
                  'Continuous Scan Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w600, // Added to match
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (_continuousScan && _scannedBarcodes.isNotEmpty)
                  GestureDetector(
                    onTap: _showScannedList,
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: 8,
                      ), // Added for spacing
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_scannedBarcodes.length} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: _handleKeyEvent,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      focusNode: _barcodeFocusNode,
                      autofocus: true,
                      maxLines: 1,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.none,
                      decoration: InputDecoration(
                        labelText:
                            _continuousScan
                                ? "Enter Barcode (Press Enter to Add)"
                                : "Enter Barcode",
                        labelStyle: const TextStyle(fontSize: 13),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 14.0,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _scanBarcode,
                    child: Image.asset(
                      'assets/images/barcode.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _scanQRCode,
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 35,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Dynamic button - changes based on mode
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final barcode = _barcodeController.text.trim();
                  if (barcode.isNotEmpty) {
                    if (_continuousScan) {
                      _addBarcodeToList(barcode);
                      _barcodeController.clear();
                    } else {
                      _validateAndNavigate(barcode);
                    }
                  }
                },
                child: Container(
                  height: 38,
                  width: _continuousScan ? 120 : 140,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipPath(
                          clipper: DiagonalClipper(),
                          child: Container(
                            color: AppColors.primaryColor,
                            alignment: Alignment.center,
                            child: Text(
                              _continuousScan ? 'ADD' : 'SEARCH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        alignment: Alignment.center,
                        child: Icon(
                          _continuousScan ? Icons.add : Icons.search,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Show scanned barcodes preview (quick view)
          if (_continuousScan && _scannedBarcodes.isNotEmpty && !_isValidating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Quick Preview:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        _scannedBarcodes.take(3).map((item) {
                          Color statusColor =
                              item['status'] == 'valid'
                                  ? Colors.green
                                  : (item['status'] == 'pending'
                                      ? Colors.orange
                                      : Colors.red);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              item['barcode'],
                              style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  if (_scannedBarcodes.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${_scannedBarcodes.length - 3} more',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          if (_barcodeResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                "Barcode Results:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  if (_filters['StyleCode'] == true)
                    const DataColumn(label: Text("Style Code")),
                  if (_filters['WSP'] == true)
                    const DataColumn(label: Text("WSP")),
                  if (_filters['Sizes'] == true)
                    const DataColumn(label: Text("Size")),
                  if (_filters['Shades'] == true)
                    const DataColumn(label: Text("Shade")),
                ],
                rows:
                    _barcodeResults.map((result) {
                      return DataRow(
                        cells: [
                          if (_filters['StyleCode'] == true)
                            DataCell(
                              Text(result['StyleCode']?.toString() ?? ''),
                            ),
                          if (_filters['WSP'] == true)
                            DataCell(Text(result['WSP']?.toString() ?? '')),
                          if (_filters['Sizes'] == true)
                            DataCell(Text(result['Size']?.toString() ?? '')),
                          if (_filters['Shades'] == true)
                            DataCell(Text(result['Shade']?.toString() ?? '')),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width - 20, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
