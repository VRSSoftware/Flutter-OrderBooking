// import 'package:flutter/material.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/catalog/imagezoom.dart';

// class OrderStatusCard extends StatelessWidget {
//   final String productName;
//   final String orderNo;
//   final List<dynamic> items;
//   final bool showImage;

//   const OrderStatusCard({
//     required this.productName,
//     required this.orderNo,
//     required this.items,
//     required this.showImage,
//     super.key,
//   });

//   Color _getColorCode(String color) {
//     switch (color.toLowerCase()) {
//       case 'red':
//         return Colors.red;
//       case 'green':
//         return Colors.green;
//       case 'blue':
//         return Colors.blue;
//       case 'yellow':
//         return Colors.yellow[800]!;
//       case 'black':
//         return Colors.black;
//       case 'white':
//         return Colors.grey;
//       default:
//         return Colors.black;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildHeaderSection(context),
//             const SizedBox(height: 16),
//             _buildOrderTable(context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeaderSection(BuildContext context) {
//     final firstItem = items.first;
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (showImage &&
//             firstItem['Style_Image'] != null &&
//             firstItem['Style_Image'].isNotEmpty)
//           _buildItemImage(context, firstItem['Style_Image']),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 productName,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               _buildDetailRow('Order No:', orderNo),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildItemImage(BuildContext context, String imageUrl) {
//     return GestureDetector(
//       onDoubleTap: () => _openImageZoom(context, imageUrl),
//       child: Container(
//         constraints: const BoxConstraints(maxWidth: 100),
//         child: Image.network(
//           _getImageUrl(imageUrl),
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

//   void _openImageZoom(BuildContext context, String imageUrl) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ImageZoomScreen(imageUrl: _getImageUrl(imageUrl)),
//       ),
//     );
//   }

//   // String _getImageUrl(String imagePath) =>
//   //     imagePath.startsWith('http')
//   //         ? imagePath
//   //         : '${AppConstants.BASE_URL}/images/${imagePath.split('/').last.split('?').first}';

//   String _getImageUrl(String imagePath) {
//     if (imagePath.isEmpty) {
//       return '';
//     }

//     if (UserSession.onlineImage == '0') {
//       final imageName = imagePath.split('/').last.split('?').first;
//       if (imageName.isEmpty) {
//         return '';
//       }
//       return '${AppConstants.BASE_URL}/images/$imageName';
//     } else if (UserSession.onlineImage == '1') {
//       return imagePath;
//     }

//     return '';
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

//   Widget _buildOrderTable(BuildContext context) {
//     final Map<String, List<dynamic>> groupedItems = {};
//     for (var item in items) {
//       final color = item['Color'] ?? 'Unknown';
//       groupedItems.putIfAbsent(color, () => []).add(item);
//     }

//     // Dynamically build table rows
//     final List<TableRow> tableRows = [];

//     // Table header
//     tableRows.add(
//       TableRow(
//         decoration: BoxDecoration(color: Colors.grey.shade100),
//         children: [
//           _buildTableHeader('Shade'),
//           _buildTableHeader('Size'),
//           _buildTableHeader('Party'),
//           _buildTableHeader('Order Qty'),
//           _buildTableHeader('Delv Qty'),
//           _buildTableHeader('Settle Qty'),
//           _buildTableHeader('Pending Qty'),
//           _buildTableHeader('Order No'),
//         ],
//       ),
//     );

//     final entries = groupedItems.entries.toList();
//     for (int groupIndex = 0; groupIndex < entries.length; groupIndex++) {
//       final entry = entries[groupIndex];
//       final isLastGroup = groupIndex == entries.length - 1;

//       for (int i = 0; i < entry.value.length; i++) {
//         final item = entry.value[i];
//         tableRows.add(
//           TableRow(
//             children: [
//               if (i == 0)
//                 TableCell(
//                   verticalAlignment: TableCellVerticalAlignment.middle,
//                   child: Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: Text(
//                       entry.key,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: _getColorCode(entry.key),
//                       ),
//                     ),
//                   ),
//                 )
//               else
//                 const SizedBox(),
//               _buildTableCell(item['Size'] ?? ''),
//               _buildTableCell(item['Party'] ?? ''),
//               _buildTableCell(item['OrderQty']?.toString() ?? '0'),
//               _buildTableCell(item['DelvQty']?.toString() ?? '0'),
//               _buildTableCell(item['SettleQty']?.toString() ?? '0'),
//               _buildTableCell(item['PendingQty']?.toString() ?? '0'),
//               _buildTableCell(item['OrderNo'] ?? ''),
//             ],
//           ),
//         );
//       }

//       if (!isLastGroup) {
//         tableRows.add(
//           TableRow(
//             children: List.generate(
//               8,
//               (_) => Container(
//                 height: 1,
//                 color: const Color.fromARGB(255, 124, 124, 124),
//               ),
//             ),
//           ),
//         );
//       }
//     }

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           minWidth: MediaQuery.of(context).size.width - 64,
//         ),
//         child: Table(
//           border: TableBorder.all(color: Colors.grey.shade300, width: 1),
//           columnWidths: const {
//             0: FixedColumnWidth(100),
//             1: FixedColumnWidth(80),
//             2: FixedColumnWidth(120),
//             3: FixedColumnWidth(80),
//             4: FixedColumnWidth(80),
//             5: FixedColumnWidth(80),
//             6: FixedColumnWidth(80),
//             7: FixedColumnWidth(100),
//           },
//           children: tableRows,
//         ),
//       ),
//     );
//   }

//   Widget _buildTableHeader(String text) {
//     return TableCell(
//       verticalAlignment: TableCellVerticalAlignment.middle,
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Text(
//           text,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }

//   Widget _buildTableCell(String text) {
//     return TableCell(
//       verticalAlignment: TableCellVerticalAlignment.middle,
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Text(text, textAlign: TextAlign.center),
//       ),
//     );
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

import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';

class OrderStatusCard extends StatelessWidget {
  final String productName;
  final String orderNo;
  final List<dynamic> items;
  final bool showImage;

  const OrderStatusCard({
    required this.productName,
    required this.orderNo,
    required this.items,
    required this.showImage,
    super.key,
  });

  Color _getColorCode(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow[800]!;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getShadeName(dynamic item) {
    // First try to get ColorName (if you've mapped it in the main screen)
    if (item['ColorName'] != null && item['ColorName'].toString().isNotEmpty && item['ColorName'] != 'NA') {
      return item['ColorName'].toString();
    }
    
    // If ColorName is not available, use the color code
    if (item['Color'] != null && item['Color'].toString().isNotEmpty) {
      return item['Color'].toString();
    }
    
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Gradient
          _buildGradientHeader(context),
          // Table Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildOrderTable(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    final firstItem = items.first;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
   colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (showImage &&
              firstItem['Style_Image'] != null &&
              firstItem['Style_Image'].isNotEmpty)
            _buildItemImage(context, firstItem['Style_Image']),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order: ${_extractOrderNumber(orderNo)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _extractOrderNumber(String orderNo) {
    // Extract only the order number without date
    if (orderNo.contains('\n')) {
      return orderNo.split('\n')[0];
    }
    return orderNo;
  }

  Widget _buildItemImage(BuildContext context, String imagePath) {
    final imageUrls = _getImageUrls(imagePath);
    final imageUrl = imageUrls.isNotEmpty && imageUrls[0].isNotEmpty ? imageUrls[0] : '';

    return GestureDetector(
      onDoubleTap: () => _openImageZoom(context, imagePath),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) =>
                      loadingProgress == null
                          ? child
                          : const Center(child: CircularProgressIndicator(strokeWidth: 1)),
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              )
            : const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
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

  List<String> _getImageUrls(String imagePath) {
    if (imagePath.isEmpty) {
      return [''];
    }

    final imageEntries = imagePath.split(',').map((entry) => entry.trim()).toList();
    List<String> imageUrls = [];

    for (var entry in imageEntries) {
      final parts = entry.split(':');
      if (parts.length < 2) {
        final path = entry.trim();
        if (path.isNotEmpty) {
          final fileName = path.split('/').last.split('\\').last;
          if (fileName.isNotEmpty) {
            imageUrls.add('${AppConstants.BASE_URL}/images/$fileName');
          }
        }
        continue;
      }

      final path = parts.sublist(1).join(':').trim();
      if (path.isEmpty) continue;

      final fileName = path.split('/').last.split('\\').last;
      if (fileName.isEmpty) continue;

      final url = '${AppConstants.BASE_URL}/images/$fileName';
      imageUrls.add(url);
    }

    return imageUrls.isEmpty ? [''] : imageUrls;
  }

  Widget _buildOrderTable(BuildContext context) {
    // Group items by shade first
    final Map<String, List<dynamic>> groupedByShade = {};
    
    for (var item in items) {
      final shade = _getShadeName(item);
      groupedByShade.putIfAbsent(shade, () => []).add(item);
    }

    // Build table rows
    final List<TableRow> tableRows = [];

    // Table header
    tableRows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          _buildTableHeader('Shade'),
          _buildTableHeader('Party'),
          _buildTableHeader('Size'),
          _buildTableHeader('Order Qty'),
          _buildTableHeader('Delv Qty'),
          _buildTableHeader('Settle Qty'),
          _buildTableHeader('Pending Qty'),
        ],
      ),
    );

    final shadeEntries = groupedByShade.entries.toList();
    
    for (int shadeIndex = 0; shadeIndex < shadeEntries.length; shadeIndex++) {
      final shadeEntry = shadeEntries[shadeIndex];
      final isLastShade = shadeIndex == shadeEntries.length - 1;
      
      // Get unique sizes for this shade and aggregate quantities
      final Map<String, Map<String, dynamic>> sizeData = {};
      String party = '';
      
      for (var item in shadeEntry.value) {
        party = item['Party'] ?? 'Unknown';
        final size = item['Size']?.toString() ?? 'Unknown';
        
        if (!sizeData.containsKey(size)) {
          sizeData[size] = {
            'orderQty': 0.0,
            'delvQty': 0.0,
            'settleQty': 0.0,
            'pendingQty': 0.0,
          };
        }
        
        sizeData[size]!['orderQty'] += (item['OrderQty'] as num?)?.toDouble() ?? 0;
        sizeData[size]!['delvQty'] += (item['DelvQty'] as num?)?.toDouble() ?? 0;
        sizeData[size]!['settleQty'] += (item['SettleQty'] as num?)?.toDouble() ?? 0;
        sizeData[size]!['pendingQty'] += (item['PendingQty'] as num?)?.toDouble() ?? 0;
      }

      final sizeEntries = sizeData.entries.toList();
      
      // Create rows for each size
      for (int sizeIndex = 0; sizeIndex < sizeEntries.length; sizeIndex++) {
        final sizeEntry = sizeEntries[sizeIndex];
        
        tableRows.add(
          TableRow(
            children: [
              // Shade column - only show in first row of this shade group
              if (sizeIndex == 0)
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _getColorCode(shadeEntry.key),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            shadeEntry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getColorCode(shadeEntry.key),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const TableCell(child: SizedBox()),
              
              // Party column - only show in first row of this shade group
              if (sizeIndex == 0)
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      party,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                )
              else
                const TableCell(child: SizedBox()),
              
              // Size column
              _buildTableCell(sizeEntry.key),
              
              // Quantity columns
              _buildTableCell(sizeEntry.value['orderQty'].toStringAsFixed(0)),
              _buildTableCell(
                sizeEntry.value['delvQty'].toStringAsFixed(0),
                color: Colors.green[700],
              ),
              _buildTableCell(
                sizeEntry.value['settleQty'].toStringAsFixed(0),
                color: Colors.orange[700],
              ),
              _buildTableCell(
                sizeEntry.value['pendingQty'].toStringAsFixed(0),
                color: sizeEntry.value['pendingQty'] > 0 
                    ? Colors.red[700] 
                    : sizeEntry.value['pendingQty'] < 0 
                        ? Colors.orange[700] 
                        : Colors.green[700],
                isBold: true,
              ),
            ],
          ),
        );
      }

      // Add separator between shades (except after last shade)
      if (!isLastShade) {
        tableRows.add(
          TableRow(
            children: List.generate(
              7,
              (_) => Container(
                height: 2,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        );
      }
    }

    // Add totals row
    tableRows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          _buildTableCell('TOTAL', isBold: true),
          const TableCell(child: SizedBox()),
          const TableCell(child: SizedBox()),
          _buildTableCell(
            _calculateTotal('OrderQty').toStringAsFixed(0),
            isBold: true,
          ),
          _buildTableCell(
            _calculateTotal('DelvQty').toStringAsFixed(0),
            color: Colors.green[700],
            isBold: true,
          ),
          _buildTableCell(
            _calculateTotal('SettleQty').toStringAsFixed(0),
            color: Colors.orange[700],
            isBold: true,
          ),
          _buildTableCell(
            _calculateTotal('PendingQty').toStringAsFixed(0),
            color: _calculateTotal('PendingQty') > 0 ? Colors.red[700] : Colors.green[700],
            isBold: true,
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
          columnWidths: const {
            0: FixedColumnWidth(90),  // Shade
            1: FixedColumnWidth(100), // Party
            2: FixedColumnWidth(60),  // Size
            3: FixedColumnWidth(70),  // Order Qty
            4: FixedColumnWidth(70),  // Delv Qty
            5: FixedColumnWidth(70),  // Settle Qty
            6: FixedColumnWidth(70),  // Pending Qty
          },
          children: tableRows,
        ),
      ),
    );
  }

  double _calculateTotal(String field) {
    double total = 0;
    for (var item in items) {
      total += (item[field] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Widget _buildTableHeader(String text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    Color? color,
    bool isBold = false,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}