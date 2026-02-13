// import 'package:flutter/material.dart';
// import 'package:vrs_erp/catalog/imagezoom.dart';
// import '../constants/app_constants.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class StyleCard extends StatefulWidget {
//   final String styleCode;
//   final List<dynamic> items;
//   final Map<String, Map<String, TextEditingController>> controllers;
//   final VoidCallback onRemove;
//   final VoidCallback updateTotals;
//   final Color Function(String) getColor;
//   final VoidCallback onUpdate;

//   const StyleCard({
//     required this.styleCode,
//     required this.items,
//     required this.controllers,
//     required this.onRemove,
//     required this.updateTotals,
//     required this.getColor,
//     required this.onUpdate,
//     Key? key,
//   }) : super(key: key);

//   @override
//   _StyleCardState createState() => _StyleCardState();
// }

// class _StyleCardState extends State<StyleCard> {
//   final TextEditingController noteController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final firstItem = widget.items.first;
//     return Card(
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildHeaderSection(firstItem),
//             const SizedBox(height: 16),
//             _buildPriceTable(context),
//             _buildActionButtons(context),
//           ],
//         ),
//       ),
//     );
//   }

//   void _openImageZoom(BuildContext context, String imageUrl) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ImageZoomScreen(imageUrl: _getImageUrl(imageUrl)),
//       ),
//     );
//   }

//   Widget _buildHeaderSection(Map<String, dynamic> firstItem) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (firstItem['fullImagePath'] != null)
//           _buildItemImage(firstItem['fullImagePath']),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.styleCode,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primaryColor,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               if (firstItem['itemSubGrpName'] != null)
//                 _buildDetailRow('Category:', firstItem['itemSubGrpName']),
//               if (firstItem['itemName'] != null)
//                 _buildDetailRow('Product:', firstItem['itemName']),
//               if (firstItem['brandName'] != null)
//                 _buildDetailRow('Brand:', firstItem['brandName']),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildItemImage(String imagePath) {
//     return GestureDetector(
//       onDoubleTap: () => _openImageZoom(context, imagePath),
//       child: Container(
//         constraints: const BoxConstraints(maxWidth: 100),
//         child: Image.network(
//           _getImageUrl(imagePath),
//           fit: BoxFit.contain,
//           loadingBuilder:
//               (context, child, loadingProgress) =>
//                   loadingProgress == null
//                       ? child
//                       : const Center(child: CircularProgressIndicator()),
//           errorBuilder:
//               (context, error, stackTrace) => const _ImageErrorWidget(),
//         ),
//       ),
//     );
//   }

//   String _getImageUrl(String fullImagePath) {
//     if (UserSession.onlineImage == '0') {
//       final imageName = fullImagePath.split('/').last.split('?').first;
//       if (imageName.isEmpty) {
//         // Return default image if no valid image name found
//         return '${AppConstants.BASE_URL}/images/NoImage.jpg';
//       }
//       return '${AppConstants.BASE_URL}/images/$imageName';
//     } else if (UserSession.onlineImage == '1') {
//       if (fullImagePath.isEmpty) {
//         // Return default image if empty string
//         return '${AppConstants.BASE_URL}/images/NoImage.jpg';
//       }
//       // Return the full path as it is (assumed to be a valid URL)
//       return fullImagePath;
//     }
//     // Default fallback to no-image URL for invalid onlineImage values
//     return '${AppConstants.BASE_URL}/images/NoImage.jpg';
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: RichText(
//         text: TextSpan(
//           style: TextStyle(fontSize: 14, color: Colors.grey[800]),
//           children: [
//             TextSpan(
//               text: '$label ',
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//             TextSpan(text: value),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPriceTable(BuildContext context) {
//     final sizeDetails = _getSizeDetails(widget.items);
//     final sortedSizes = sizeDetails.keys.toList()..sort();
//     final sortedShades = _getSortedShades(widget.items);

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           minWidth: MediaQuery.of(context).size.width - 64,
//         ),
//         child: Table(
//           border: TableBorder.all(color: Colors.grey.shade300, width: 1),
//           columnWidths: _buildColumnWidths(sortedSizes),
//           children: [
//             _buildTableRow('MRP', sortedSizes, sizeDetails, 'mrp'),
//             _buildTableRow('WSP', sortedSizes, sizeDetails, 'wsp'),
//             _buildHeaderRow(sortedSizes),
//             ...sortedShades.map((shade) => _buildShadeRow(shade, sortedSizes)),
//           ],
//         ),
//       ),
//     );
//   }

//   Map<String, Map<String, num>> _getSizeDetails(List<dynamic> items) {
//     final details = <String, Map<String, num>>{};
//     for (final item in items) {
//       final size = item['sizeName']?.toString() ?? 'N/A';
//       details[size] = {
//         'mrp': (item['mrp'] as num?) ?? 0,
//         'wsp': (item['wsp'] as num?) ?? 0,
//       };
//     }
//     return details;
//   }

//   List<String> _getSortedShades(List<dynamic> items) =>
//       items.map((e) => e['shadeName']?.toString() ?? '').toSet().toList()
//         ..sort();

//   Map<int, TableColumnWidth> _buildColumnWidths(List<String> sizes) => {
//     0: const FixedColumnWidth(100),
//     for (var i = 0; i < sizes.length; i++) i + 1: const FixedColumnWidth(80),
//   };

//   TableRow _buildTableRow(
//     String label,
//     List<String> sizes,
//     Map<String, Map<String, num>> details,
//     String key,
//   ) {
//     return TableRow(
//       children: [
//         TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: Padding(padding: const EdgeInsets.all(8), child: Text(label)),
//         ),
//         ...sizes.map(
//           (size) => TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Center(
//               child: Text(
//                 '${details[size]?[key]?.toStringAsFixed(0) ?? '0'}',
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   TableRow _buildHeaderRow(List<String> sizes) {
//     return TableRow(
//       decoration: BoxDecoration(color: const  Color.fromARGB(255, 236, 212, 204)),
//       children: [
//         const TableCell(
//           verticalAlignment: TableCellVerticalAlignment.middle,
//           child: _TableHeaderCell(),
//         ),
//         ...sizes.map(
//           (size) => TableCell(
//             verticalAlignment: TableCellVerticalAlignment.middle,
//             child: Center(
//               child: Text(
//                 size,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   TableRow _buildShadeRow(String shade, List<String> sizes) {
//     return TableRow(
//       children: [
//         TableCell(
//           child: Padding(
//             padding: const EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 const SizedBox(width: 8),
//                 Text(
//                   shade,
//                   style: TextStyle(
//                     color: widget.getColor(shade),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         ...sizes.map(
//           (size) => Padding(
//             padding: const EdgeInsets.all(4),
//             child: TextField(
//               controller: widget.controllers[shade]?[size],
//               keyboardType: TextInputType.number,
//               textAlign: TextAlign.center,
//               onChanged: (_) => widget.updateTotals(),
//               decoration: const InputDecoration(
//                 contentPadding: EdgeInsets.symmetric(vertical: 8),
//                 hintText: '0',
//                 hintStyle: TextStyle(color: Colors.grey),
//                 border: InputBorder.none,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButtons(BuildContext context) {
//     int styleTotalQty = 0;
//     widget.controllers.forEach((shade, sizes) {
//       sizes.forEach((size, controller) {
//         styleTotalQty += int.tryParse(controller.text) ?? 0;
//       });
//     });

//     return Padding(
//       padding: const EdgeInsets.only(top: 14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           TextField(
//             controller: noteController,
//             decoration: InputDecoration(
//               labelText: 'Note',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextFormField(
//             readOnly: true,
//             decoration: InputDecoration(
//               labelText: 'Style Total Quantity',
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             controller: TextEditingController(text: styleTotalQty.toString())
//               ..selection = TextSelection.collapsed(
//                 offset: styleTotalQty.toString().length,
//               ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildActionButton(
//                   label: 'Update',
//                   icon: Icons.update,
//                   color: AppColors.primaryColor,
//                   onPressed: () => _submitUpdate(context),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildActionButton(
//                   label: 'Remove',
//                   icon: Icons.delete,
//                   color: Colors.grey,
//                   onPressed: () => _submitDelete(context),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButton({
//     required String label,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return Expanded(
//       child: OutlinedButton.icon(
//         icon: Icon(icon, size: 20, color: color),
//         label: Text(label, style: TextStyle(color: color)),
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(color: color),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 16),
//         ),
//         onPressed: onPressed,
//       ),
//     );
//   }

//   Future<void> _submitDelete(BuildContext context) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Confirm Deletion"),
//           content: const Text("Are you sure you want to delete this item?"),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text("Delete", style: TextStyle(color: Colors.red)),
//             ),
//           ],
//         );
//       },
//     );

//     if (confirmed != true) return;
//     String sCode = widget.styleCode;
//     String bCode = "";
//     if (sCode.contains('---')) {
//       List<String> parts = widget.styleCode.split('---');
//       sCode = parts[0];
//       bCode = parts[1];
//     }
//     final payload = {
//       "userId": UserSession.userName ?? '',
//       "coBrId": UserSession.coBrId ?? '',
//       "fcYrId": UserSession.userFcYr ?? '',
//       "data": {
//         "designcode": sCode,
//         "mrp": '0',
//         "WSP": '0',
//         "size": '',
//         "TotQty": '0',
//         "Note": noteController.text,
//         "color": "",
//         "Qty": " ",
//         "cobrid": UserSession.userName ?? '',
//         "user": "admin",
//         "barcode": bCode,
//       },
//       "typ": 2,
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(
//           '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
//         ),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(payload),
//       );

//       if (response.statusCode == 200) {
//         widget.onRemove();
//       } else {
//         _showErrorDialog(context, "Failed to delete item.");
//       }
//     } catch (e) {
//       _showErrorDialog(context, "Error: $e");
//     }
//   }

//   void _showErrorDialog(BuildContext context, String message) {
//     showDialog(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             title: const Text("Error"),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("OK"),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> _submitUpdate(BuildContext context) async {
//     List<Future> apiCalls = [];
//     final sizeDetails = _getSizeDetails(widget.items);
//     int totalQty = 0;
//     List<String> updatedData = [];

//     debugPrint('Submitting update for styleCode: ${widget.styleCode}');
//     String sCode = widget.styleCode;
//     String bCode = "";
//     if (sCode.contains('---')) {
//       List<String> parts = widget.styleCode.split('---');
//       sCode = parts[0];
//       bCode = parts[1];
//     }
//     // Create the initial payload for the first API call
//     final initialPayload = {
//       "userId": UserSession.userName ?? '',
//       "coBrId": UserSession.coBrId ?? '',
//       "fcYrId": UserSession.userFcYr ?? '',
//       "data": {
//         "designcode": sCode,
//         "mrp": '0',
//         "WSP": '0',
//         "size": '',
//         "TotQty": totalQty.toString(),
//         "Note": noteController.text,
//         "color": "",
//         "Qty": " ",
//         "cobrid": UserSession.coBrId ?? '',
//         "user": "admin",
//         "barcode": bCode,
//       },
//       "typ": 1,
//     };

//     // Make the first API call and await the response
//     final firstResponse = await http.post(
//       Uri.parse(
//         '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
//       ),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(initialPayload),
//     );

//     // Check if the first API call is successful (status code 200)
//     if (firstResponse.statusCode != 200) {
//       debugPrint(
//         'First API call failed with status code: ${firstResponse.statusCode}',
//       );
//       showDialog(
//         context: context,
//         builder:
//             (_) => AlertDialog(
//               title: const Text("Error"),
//               content: const Text("Failed to submit initial order details."),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//       );
//       return;
//     }

//     // If the first call is successful, proceed with the for loop
//     for (var shadeEntry in widget.controllers.entries) {
//       String shade = shadeEntry.key;
//       for (var sizeEntry in shadeEntry.value.entries) {
//         String size = sizeEntry.key;
//         String qty = sizeEntry.value.text;
//         if (qty.isNotEmpty && int.tryParse(qty) != null && int.parse(qty) > 0) {
//           totalQty += int.parse(qty);
//           updatedData.add('Shade: $shade, Size: $size, Qty: $qty');
//           String sCode = widget.styleCode;
//           String bCode = "";
//           if (sCode.contains('---')) {
//             List<String> parts = widget.styleCode.split('---');
//             sCode = parts[0];
//             bCode = parts[1];
//           }
//           final payload = {
//             "userId": UserSession.userName ?? '',
//             "coBrId": UserSession.coBrId ?? '',
//             "fcYrId": UserSession.userFcYr ?? '',
//             "data": {
//               "designcode": sCode,
//               "mrp": sizeDetails[size]?['mrp']?.toStringAsFixed(0) ?? '0',
//               "WSP": sizeDetails[size]?['wsp']?.toStringAsFixed(0) ?? '0',
//               "size": size,
//               "TotQty": totalQty.toString(),
//               "Note": noteController.text,
//               "color": shade,
//               "Qty": qty,
//               "cobrid": UserSession.coBrId ?? '',
//               "user": "admin",
//               "barcode": bCode,
//             },
//             "typ": 0,
//           };

//           apiCalls.add(
//             http.post(
//               Uri.parse(
//                 '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
//               ),
//               headers: {'Content-Type': 'application/json'},
//               body: jsonEncode(payload),
//             ),
//           );
//         }
//       }
//     }

//     if (apiCalls.isEmpty) {
//       showDialog(
//         context: context,
//         builder:
//             (_) => AlertDialog(
//               title: const Text("No Updates"),
//               content: const Text("No quantities have been updated."),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//       );
//       return;
//     }

//     if (noteController.text.isNotEmpty) {
//       updatedData.add('Note: ${noteController.text}');
//     }

//     try {
//       final responses = await Future.wait(apiCalls);
//       if (responses.every((r) => r.statusCode == 200)) {
//         debugPrint('Update successful for styleCode: ${widget.styleCode}');
//         widget.onUpdate(); // Trigger refresh without removing card
//         showDialog(
//           context: context,
//           builder:
//               (_) => AlertDialog(
//                 title: const Text("Success"),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text("Order details updated successfully:"),
//                       // const SizedBox(height: 8),
//                       // Text(updatedData.join('\n')),
//                     ],
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text("OK"),
//                   ),
//                 ],
//               ),
//         );
//       } else {
//         debugPrint(
//           'Update failed for some items: ${responses.map((r) => r.statusCode).toList()}',
//         );
//         showDialog(
//           context: context,
//           builder:
//               (_) => AlertDialog(
//                 title: const Text("Error"),
//                 content: const Text("Failed to update some order details."),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context),
//                     child: const Text("OK"),
//                   ),
//                 ],
//               ),
//         );
//       }
//     } catch (e) {
//       debugPrint('Error during update: $e');
//       showDialog(
//         context: context,
//         builder:
//             (_) => AlertDialog(
//               title: const Text("Error"),
//               content: Text("Failed to submit update: $e"),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//       );
//     }
//   }
// }

// class _ImageErrorWidget extends StatelessWidget {
//   const _ImageErrorWidget();

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.image_not_supported, size: 40),
//           SizedBox(height: 8),
//           Text(
//             'Image not available',
//             style: TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TableHeaderCell extends StatelessWidget {
//   const _TableHeaderCell();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 48,
//       child: CustomPaint(
//         painter: _DiagonalLinePainter(),
//         child: const Stack(
//           children: [
//             Positioned(
//               left: 12,
//               top: 20,
//               child: Text(
//                 'Shade',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//             ),
//             Positioned(
//               right: 14,
//               bottom: 20,
//               child: Text(
//                 'Size',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _DiagonalLinePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint =
//         Paint()
//           ..color = Colors.grey.shade400
//           ..strokeWidth = 1
//           ..style = PaintingStyle.stroke;
//     canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/models/CartModel.dart';
import '../constants/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StyleCard extends StatefulWidget {
  final String styleCode;
  final List<dynamic> items;
  final Map<String, Map<String, TextEditingController>> controllers;
  final VoidCallback onRemove;
  final VoidCallback updateTotals;
  final Color Function(String) getColor;
  final VoidCallback onUpdate;

  const StyleCard({
    required this.styleCode,
    required this.items,
    required this.controllers,
    required this.onRemove,
    required this.updateTotals,
    required this.getColor,
    required this.onUpdate,
    Key? key,
  }) : super(key: key);

  @override
  _StyleCardState createState() => _StyleCardState();
}

class _StyleCardState extends State<StyleCard> {
  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final firstItem = widget.items.first;
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderSection(firstItem),
            const SizedBox(height: 16),
            _buildPriceTable(context),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  void _openImageZoom(BuildContext context, String imagePath) {
    final imageUrls = _getImageUrls(imagePath);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageZoomScreen(imageUrls: imageUrls),
      ),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> firstItem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstItem['fullImagePath'] != null)
          _buildItemImage(firstItem['fullImagePath']),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.styleCode,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              if (firstItem['itemSubGrpName'] != null)
                _buildDetailRow('Category:', firstItem['itemSubGrpName']),
              if (firstItem['itemName'] != null)
                _buildDetailRow('Product:', firstItem['itemName']),
              if (firstItem['brandName'] != null)
                _buildDetailRow('Brand:', firstItem['brandName']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(String imagePath) {
    final imageUrls = _getImageUrls(imagePath);
    final imageUrl = imageUrls.isNotEmpty && imageUrls[0].isNotEmpty ? imageUrls[0] : '${AppConstants.BASE_URL}/images/NoImage.jpg';

    return GestureDetector(
      onDoubleTap: () => _openImageZoom(context, imagePath),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        height: 100,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) =>
              loadingProgress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stackTrace) => const _ImageErrorWidget(),
        ),
      ),
    );
  }

  List<String> _getImageUrls(String imagePath) {
    if (imagePath.isEmpty) {
      return ['${AppConstants.BASE_URL}/images/NoImage.jpg'];
    }

    if (UserSession.onlineImage == '0') {
      // Handle multi-image format like "shadeName:path, shadeName:path"
      final imageEntries = imagePath.split(',').map((entry) => entry.trim()).toList();
      List<String> imageUrls = [];
      for (var entry in imageEntries) {
        // Split entry by last colon to separate shadeName and path
        final parts = entry.split(':');
        if (parts.length < 2) {
          // Handle single path without shadeName
          final path = entry.trim();
          if (path.isNotEmpty) {
            final fileName = path.split('/').last.split('\\').last.split('?').first;
            if (fileName.isNotEmpty) {
              imageUrls.add('${AppConstants.BASE_URL}/images/$fileName');
            }
          }
          continue;
        }

        // The path is everything after the first colon
        final path = parts.sublist(1).join(':').trim();
        if (path.isEmpty) continue;

        // Extract filename from path
        final fileName = path.split('/').last.split('\\').last.split('?').first;
        if (fileName.isEmpty) continue;

        // Construct URL
        final url = '${AppConstants.BASE_URL}/images/$fileName';
        imageUrls.add(url);
      }
      return imageUrls.isEmpty ? ['${AppConstants.BASE_URL}/images/NoImage.jpg'] : imageUrls;
    } else if (UserSession.onlineImage == '1') {
      // Handle direct URLs, possibly comma-separated
      final urls = imagePath.split(',').map((url) => url.trim()).toList();
      return urls.isEmpty || urls.every((url) => url.isEmpty)
          ? ['${AppConstants.BASE_URL}/images/NoImage.jpg']
          : urls;
    }

    return ['${AppConstants.BASE_URL}/images/NoImage.jpg'];
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTable(BuildContext context) {
    final sizeDetails = _getSizeDetails(widget.items);
    final sortedSizes = sizeDetails.keys.toList()..sort();
    final sortedShades = _getSortedShades(widget.items);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 64,
        ),
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
          columnWidths: _buildColumnWidths(sortedSizes),
          children: [
            _buildTableRow('MRP', sortedSizes, sizeDetails, 'mrp'),
            _buildTableRow('WSP', sortedSizes, sizeDetails, 'wsp'),
            _buildHeaderRow(sortedSizes),
            ...sortedShades.map((shade) => _buildShadeRow(shade, sortedSizes)),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, num>> _getSizeDetails(List<dynamic> items) {
    final details = <String, Map<String, num>>{};
    for (final item in items) {
      final size = item['sizeName']?.toString() ?? 'N/A';
      details[size] = {
        'mrp': (item['mrp'] as num?) ?? 0,
        'wsp': (item['wsp'] as num?) ?? 0,
      };
    }
    return details;
  }

  List<String> _getSortedShades(List<dynamic> items) =>
      items.map((e) => e['shadeName']?.toString() ?? '').toSet().toList()
        ..sort();

  Map<int, TableColumnWidth> _buildColumnWidths(List<String> sizes) => {
        0: const FixedColumnWidth(100),
        for (var i = 0; i < sizes.length; i++) i + 1: const FixedColumnWidth(80),
      };

  TableRow _buildTableRow(
    String label,
    List<String> sizes,
    Map<String, Map<String, num>> details,
    String key,
  ) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(padding: const EdgeInsets.all(8), child: Text(label)),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Text(
                '${details[size]?[key]?.toStringAsFixed(0) ?? '0'}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildHeaderRow(List<String> sizes) {
    return TableRow(
      decoration: BoxDecoration(color: const Color.fromARGB(255, 236, 212, 204)),
      children: [
        const TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: _TableHeaderCell(),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(
              child: Text(
                size,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildShadeRow(String shade, List<String> sizes) {
    return TableRow(
      children: [
        TableCell(
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      children: [
        const SizedBox(width: 8),
        Expanded( // ⬅️ This allows wrapping inside the row
          child: Text(
            shade,
            style: TextStyle(
              color: widget.getColor(shade),
              fontWeight: FontWeight.bold,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    ),
  ),
),

        ...sizes.map(
          (size) => Padding(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: widget.controllers[shade]?[size],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => widget.updateTotals(),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    int styleTotalQty = 0;
    widget.controllers.forEach((shade, sizes) {
      sizes.forEach((size, controller) {
        styleTotalQty += int.tryParse(controller.text) ?? 0;
      });
    });

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Style Total Quantity',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            controller: TextEditingController(text: styleTotalQty.toString())
              ..selection = TextSelection.collapsed(
                offset: styleTotalQty.toString().length,
              ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Update',
                  icon: Icons.update,
                  color: AppColors.primaryColor,
                  onPressed: () => _submitUpdate(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'Remove',
                  icon: Icons.delete,
                  color: Colors.grey,
                  onPressed: () => _submitDelete(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 20, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _submitDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    String sCode = widget.styleCode;
    String bCode = "";
    if (sCode.contains('---')) {
      List<String> parts = widget.styleCode.split('---');
      sCode = parts[0];
      bCode = parts[1];
    }
    final payload = {
      "userId": UserSession.userName ?? '',
      "coBrId": UserSession.coBrId ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "data": {
        "designcode": sCode,
        "mrp": '0',
        "WSP": '0',
        "size": '',
        "TotQty": '0',
        "Note": noteController.text,
        "color": "",
        "Qty": " ",
        "cobrid": UserSession.userName ?? '',
        "user": "admin",
        "barcode": bCode,
      },
      "typ": 2,
    };

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        widget.onRemove();
                  Provider.of<CartModel>(
            context,
            listen: false,
          ).removeItem(sCode); 
      } else {
        _showErrorDialog(context, "Failed to delete item.");
      }
    } catch (e) {
      _showErrorDialog(context, "Error: $e");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate(BuildContext context) async {
    List<Future> apiCalls = [];
    final sizeDetails = _getSizeDetails(widget.items);
    int totalQty = 0;
    List<String> updatedData = [];

    debugPrint('Submitting update for styleCode: ${widget.styleCode}');
    String sCode = widget.styleCode;
    String bCode = "";
    if (sCode.contains('---')) {
      List<String> parts = widget.styleCode.split('---');
      sCode = parts[0];
      bCode = parts[1];
    }
    // Create the initial payload for the first API call
    final initialPayload = {
      "userId": UserSession.userName ?? '',
      "coBrId": UserSession.coBrId ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "data": {
        "designcode": sCode,
        "mrp": '0',
        "WSP": '0',
        "size": '',
        "TotQty": totalQty.toString(),
        "Note": noteController.text,
        "color": "",
        "Qty": " ",
        "cobrid": UserSession.coBrId ?? '',
        "user": "admin",
        "barcode": bCode,
      },
      "typ": 1,
    };

    // Make the first API call and await the response
    final firstResponse = await http.post(
      Uri.parse(
        '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(initialPayload),
    );

    // Check if the first API call is successful (status code 200)
    if (firstResponse.statusCode != 200) {
      debugPrint(
        'First API call failed with status code: ${firstResponse.statusCode}',
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Failed to submit initial order details."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // If the first call is successful, proceed with the for loop
    for (var shadeEntry in widget.controllers.entries) {
      String shade = shadeEntry.key;
      for (var sizeEntry in shadeEntry.value.entries) {
        String size = sizeEntry.key;
        String qty = sizeEntry.value.text;
        if (qty.isNotEmpty && int.tryParse(qty) != null && int.parse(qty) > 0) {
          totalQty += int.parse(qty);
          updatedData.add('Shade: $shade, Size: $size, Qty: $qty');
          String sCode = widget.styleCode;
          String bCode = "";
          if (sCode.contains('---')) {
            List<String> parts = widget.styleCode.split('---');
            sCode = parts[0];
            bCode = parts[1];
          }
          final payload = {
            "userId": UserSession.userName ?? '',
            "coBrId": UserSession.coBrId ?? '',
            "fcYrId": UserSession.userFcYr ?? '',
            "data": {
              "designcode": sCode,
              "mrp": sizeDetails[size]?['mrp']?.toStringAsFixed(0) ?? '0',
              "WSP": sizeDetails[size]?['wsp']?.toStringAsFixed(0) ?? '0',
              "size": size,
              "TotQty": totalQty.toString(),
              "Note": noteController.text,
              "color": shade,
              "Qty": qty,
              "cobrid": UserSession.coBrId ?? '',
              "user": "admin",
              "barcode": bCode,
            },
            "typ": 0,
          };

          apiCalls.add(
            http.post(
              Uri.parse(
                '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ),
          );
        }
      }
    }

    if (apiCalls.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("No Updates"),
          content: const Text("No quantities have been updated."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    if (noteController.text.isNotEmpty) {
      updatedData.add('Note: ${noteController.text}');
    }

    try {
      final responses = await Future.wait(apiCalls);
      if (responses.every((r) => r.statusCode == 200)) {
        debugPrint('Update successful for styleCode: ${widget.styleCode}');
        widget.onUpdate(); // Trigger refresh without removing card
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Order details updated successfully:"),
                  // const SizedBox(height: 8),
                  // Text(updatedData.join('\n')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        debugPrint(
          'Update failed for some items: ${responses.map((r) => r.statusCode).toList()}',
        );
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Failed to update some order details."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during update: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Failed to submit update: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}

class _ImageErrorWidget extends StatelessWidget {
  const _ImageErrorWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 40),
          SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      child: CustomPaint(
        painter: _DiagonalLinePainter(),
        child: const Stack(
          children: [
            Positioned(
              left: 12,
              top: 20,
              child: Text(
                'Shade',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 20,
              child: Text(
                'Size',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
