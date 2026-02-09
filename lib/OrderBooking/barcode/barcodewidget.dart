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
//                         borderRadius: BorderRadius.circular(0),
//                         borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(0),
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
//                     borderRadius: BorderRadius.circular(0),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vrs_erp/OrderBooking/barcode/QRCodeScannerScreen.dart';
import 'package:vrs_erp/OrderBooking/barcode/barcode_scanner.dart';
import 'package:vrs_erp/OrderBooking/barcode/bookonBarcode2.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class BarcodeWiseWidget extends StatefulWidget {
  final ValueChanged<String> onFilterPressed;
  final bool edit;

  const BarcodeWiseWidget({
    super.key,
    required this.onFilterPressed,
    this.edit = false,
  });

  @override
  State<BarcodeWiseWidget> createState() => _BarcodeWiseWidgetState();
}

class _BarcodeWiseWidgetState extends State<BarcodeWiseWidget> {
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode(); // Add FocusNode
  List<Map<String, dynamic>> _barcodeResults = [];
  List<String> addedItems = [];
  Map<String, bool> _filters = {
    'WSP': true,
    'Sizes': true,
    'Shades': true,
    'StyleCode': true,
  };
  bool _noDataFound = false;

  @override
  void initState() {
    super.initState();
    _barcodeController.addListener(_handleBarcodeInput);
    // Request focus when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocusNode.dispose(); // Dispose FocusNode
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
      final barcode = _barcodeController.text.trim();
      if (barcode.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _barcodeController.clear();
          _validateAndNavigate(barcode);
        });
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
      // MaterialPageRoute(builder: (context) => QRCodeScannerScreen()),
    );

    if (barcode != null && barcode.isNotEmpty) {
      final upperBarcode = barcode.toUpperCase();
      setState(() {
        _barcodeController.text = upperBarcode;
        _noDataFound = false;
      });
      _validateAndNavigate(upperBarcode);
    }
    // Request focus after scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }
  Future<void> _scanQRCode() async {
    final barcode = await Navigator.push<String>(
      context,
      // MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
      MaterialPageRoute(builder: (context) => QRCodeScannerScreen()),
    );

    if (barcode != null && barcode.isNotEmpty) {
      final upperBarcode = barcode.toUpperCase();
      setState(() {
        _barcodeController.text = upperBarcode;
        _noDataFound = false;
      });
      _validateAndNavigate(upperBarcode);
    }
    // Request focus after scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  void _validateAndNavigate(String barcode) async {
    if (barcode.isEmpty) {
      _showAlertDialog(
        context,
        'Missing Barcode',
        'Please enter or scan a barcode first.',
      );
      _barcodeFocusNode.requestFocus(); // Request focus on error
      return;
    }

    String upperBarcode = barcode.toUpperCase();
    print("Checking barcode: $upperBarcode, addedItems: $addedItems");
    if (addedItems.contains(upperBarcode)) {
      _showAlertDialog(
        context,
        'Already Added',
        'This barcode is already added',
      );
      _barcodeFocusNode.requestFocus(); // Request focus on error
      return;
    }

    print("Navigating to BookOnBarcode2 with barcode: $upperBarcode");
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BookOnBarcode2(
              barcode: upperBarcode,
              onSuccess: () {
                setState(() {
                  addedItems.add(upperBarcode);
                  print(
                    "Added barcode: $upperBarcode, addedItems: $addedItems",
                  );
                  _barcodeController.clear();
                  _noDataFound = false;
                });
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
              edit: widget.edit, // Pass edit parameter
            ),
      ),
    );

    // Check the result from BookOnBarcode2
    if (result == false) {
      setState(() {
        _noDataFound = true;
      });
    } else {
      setState(() {
        _noDataFound = false;
      });
    }
    // Request focus after navigation returns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  void _showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _barcodeFocusNode
                      .requestFocus(); // Request focus after dialog dismissed
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      focusNode: _barcodeFocusNode, // Assign FocusNode
                      autofocus: true, // Keep autofocus true
                      maxLines: 1,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.none,
                      decoration: InputDecoration(
                        labelText: "Enter Barcode",
                        labelStyle: const TextStyle(fontSize: 14),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 14.0,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(0),
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
                      size: 35, // Optional size
                      color: Colors.black, // Optional color
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _validateAndNavigate(_barcodeController.text.trim());
                },
                child: Container(
                  height: 38,
                  width: 140,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Row(
                    children: [
                      // Left diagonal area with "SEARCH"
                      Expanded(
                        child: ClipPath(
                          clipper: DiagonalClipper(),
                          child: Container(
                            color: AppColors.primaryColor,
                            alignment: Alignment.center,
                            child: const Text(
                              'SEARCH',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Icon section
                      Container(
                        width: 38,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.search,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Show "No Data Found" message if applicable
          if (_noDataFound)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(
                child: Text(
                  "No Data Found",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          // Only show results if _barcodeResults is not empty
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
