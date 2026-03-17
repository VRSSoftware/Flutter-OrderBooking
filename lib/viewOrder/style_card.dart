import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/models/CartModel.dart';
import '../constants/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Add this color class at the top of your file
class TableColors {
  static const Color headerBg = Color(0xFF2C3E50); // Dark blue-grey
  static const Color headerText = Colors.white;
  static const Color priceRowBg = Color(0xFFF8F9FA); // Very light grey
  static const Color evenRowBg = Colors.white;
  static const Color oddRowBg = Color(0xFFF8F9FA); // Alternating row colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color accentColor = Color(0xFF3498DB); // Blue accent
  static const Color totalRowBg = Color(0xFFE8F4FD); // Light blue for totals
}

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

  int _calculateTotalQty() {
    int total = 0;
    widget.controllers.forEach((shade, sizeMap) {
      sizeMap.forEach((size, controller) {
        total += int.tryParse(controller.text) ?? 0;
      });
    });
    return total;
  }

  double _calculateTotalAmount() {
    double total = 0;
    widget.controllers.forEach((shade, sizeMap) {
      sizeMap.forEach((size, controller) {
        final qty = int.tryParse(controller.text) ?? 0;
        final item = widget.items.firstWhere(
          (item) =>
              (item['shadeName']?.toString() ?? '') == shade &&
              (item['sizeName']?.toString() ?? '') == size,
          orElse: () => {},
        );
        if (item.isNotEmpty) {
          final mrp = (item['mrp'] as num?)?.toDouble() ?? 0.0;
          total += qty * mrp;
        }
      });
    });
    return total;
  }

  int _calculateTotalStock() {
    int total = 0;
    for (var item in widget.items) {
      total += int.tryParse(item['clqty']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = widget.items.first;
    final totalQty = _calculateTotalQty();
    final totalAmount = _calculateTotalAmount();
    final totalStock = _calculateTotalStock();

    return Card(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with image and details - with padding
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildHeaderSection(firstItem),
          ),
          
          const SizedBox(height: 4),
          
          // Stats in single line - with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Expanded(
                //   child: _buildStatRow('Stock', totalStock.toString(), Icons.inventory, Colors.blue.shade700),
                // ),
                // const SizedBox(width: 6),
                Expanded(
                  child: _buildStatRow('Qty', totalQty.toString(), Icons.shopping_bag, Colors.orange.shade700),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildStatRow('Amt', '${totalAmount.toStringAsFixed(0)}', Icons.currency_rupee, Colors.green.shade700),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Enhanced Price Table - FULL WIDTH (no horizontal padding)
          _buildEnhancedPriceTable(context),
          
          const SizedBox(height: 5),
          
          // Action buttons - with padding
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildActionButtons(context),
          ),
        ],
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
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combined Style Code and Details in one container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.08),
                    Colors.white,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style Code (prominent)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'STYLE CODE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.styleCode,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Divider
                  Divider(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    height: 1,
                    thickness: 1,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Details in a grid-like layout
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (firstItem['itemSubGrpName'] != null)
                        _buildCompactDetailChip('Category', firstItem['itemSubGrpName']),
                      if (firstItem['itemName'] != null)
                        _buildCompactDetailChip('Product', firstItem['itemName']),
                      if (firstItem['brandName'] != null)
                        _buildCompactDetailChip('Brand', firstItem['brandName']),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Helper method for compact detail chips
Widget _buildCompactDetailChip(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: TableColors.priceRowBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: TableColors.borderColor.withOpacity(0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(String imagePath) {
    final imageUrls = _getImageUrls(imagePath);
    final imageUrl =
        imageUrls.isNotEmpty && imageUrls[0].isNotEmpty
            ? imageUrls[0]
            : '${AppConstants.BASE_URL}/images/NoImage.jpg';

    return GestureDetector(
      onTap: () => _openImageZoom(context, imagePath),
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: TableColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder:
                (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
            errorBuilder:
                (context, error, stackTrace) => const _ImageErrorWidget(),
          ),
        ),
      ),
    );
  }

  List<String> _getImageUrls(String imagePath) {
    if (imagePath.isEmpty) {
      return ['${AppConstants.BASE_URL}/images/NoImage.jpg'];
    }

    if (UserSession.onlineImage == '0') {
      final imageEntries =
          imagePath.split(',').map((entry) => entry.trim()).toList();
      List<String> imageUrls = [];
      for (var entry in imageEntries) {
        final parts = entry.split(':');
        if (parts.length < 2) {
          final path = entry.trim();
          if (path.isNotEmpty) {
            final fileName =
                path.split('/').last.split('\\').last.split('?').first;
            if (fileName.isNotEmpty) {
              imageUrls.add('${AppConstants.BASE_URL}/images/$fileName');
            }
          }
          continue;
        }
        final path = parts.sublist(1).join(':').trim();
        if (path.isEmpty) continue;
        final fileName = path.split('/').last.split('\\').last.split('?').first;
        if (fileName.isEmpty) continue;
        final url = '${AppConstants.BASE_URL}/images/$fileName';
        imageUrls.add(url);
      }
      return imageUrls.isEmpty
          ? ['${AppConstants.BASE_URL}/images/NoImage.jpg']
          : imageUrls;
    } else if (UserSession.onlineImage == '1') {
      final urls = imagePath.split(',').map((url) => url.trim()).toList();
      return urls.isEmpty || urls.every((url) => url.isEmpty)
          ? ['${AppConstants.BASE_URL}/images/NoImage.jpg']
          : urls;
    }

    return ['${AppConstants.BASE_URL}/images/NoImage.jpg'];
  }

  // ENHANCED PRICE TABLE - FULL WIDTH
  Widget _buildEnhancedPriceTable(BuildContext context) {
    final sizeDetails = _getSizeDetails(widget.items);
    final sortedSizes = sizeDetails.keys.toList();
    final sortedShades = _getSortedShades(widget.items);

    return Container(
      width: double.infinity, // Take full width
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: TableColors.borderColor),
          bottom: BorderSide(color: TableColors.borderColor),
        ),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width, // Full screen width
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.all(color: TableColors.borderColor, width: 0.5),
              columnWidths: _buildColumnWidths(sortedSizes),
              children: [
                // Header row with diagonal cell (no gradient)
                _buildEnhancedHeaderRow(sortedSizes),
                
                // MRP row with improved styling
                _buildEnhancedPriceRow('MRP', sortedSizes, sizeDetails, 'mrp'),
                
                // WSP row with improved styling
                _buildEnhancedPriceRow('WSP', sortedSizes, sizeDetails, 'wsp'),
                
                // Shade rows with alternating colors
                ...sortedShades.asMap().entries.map((entry) {
                  final index = entry.key;
                  final shade = entry.value;
                  return _buildEnhancedShadeRow(shade, sortedSizes, index);
                }),
              ],
            ),
          ),
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
      items.map((e) => e['shadeName']?.toString() ?? '').toSet().toList();

  Map<int, TableColumnWidth> _buildColumnWidths(List<String> sizes) {
    double screenWidth = MediaQuery.of(context).size.width;
    double firstColumnWidth = 140;
    double remainingWidth = screenWidth - firstColumnWidth;
    double sizeColumnWidth = remainingWidth / (sizes.length > 0 ? sizes.length : 1);

    if (sizeColumnWidth < 70) {
      sizeColumnWidth = 70;
    }

    return {
      0: FixedColumnWidth(firstColumnWidth),
      for (var i = 0; i < sizes.length; i++) i + 1: FixedColumnWidth(sizeColumnWidth),
    };
  }

  TableRow _buildEnhancedPriceRow(
    String label,
    List<String> sizes,
    Map<String, Map<String, num>> details,
    String key,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        color: TableColors.priceRowBg,
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: TableColors.accentColor.withOpacity(0.1),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: TableColors.accentColor,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: TableColors.borderColor, width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  '${details[size]?[key]?.toStringAsFixed(0) ?? '0'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildEnhancedHeaderRow(List<String> sizes) {
    return TableRow(
      decoration: BoxDecoration(
        color: TableColors.headerBg, // Solid color, no gradient
      ),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            height: 50,
            child: CustomPaint(
              painter: _SimpleDiagonalPainter(), // Simple painter without gradient
              child: const Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 22,
                    child: Text(
                      'SHADE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 22,
                    child: Text(
                      'SIZE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ...sizes.map(
          (size) => TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white.withOpacity(0.2), width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  size,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _clearShadeQuantities(String shade) {
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Clear Shade Quantities',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to set all quantities for shade "$shade" to zero?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Set all quantity controllers for this shade to "0"
              if (widget.controllers.containsKey(shade)) {
                widget.controllers[shade]!.forEach((size, controller) {
                  controller.text = '0';
                });
                
                // Update totals after clearing
                widget.updateTotals();
                
                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cleared all quantities for shade "$shade"'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}

 TableRow _buildEnhancedShadeRow(String shade, List<String> sizes, int rowIndex) {
  final isEvenRow = rowIndex % 2 == 0;
  final imageUrl = _getShadeImageUrl(shade);

  return TableRow(
    decoration: BoxDecoration(
      color: isEvenRow ? TableColors.evenRowBg : TableColors.oddRowBg,
    ),
    children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: TableColors.borderColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // ADD THIS - Clear icon for each shade
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => _clearShadeQuantities(shade),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.clear_all,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              // END OF ADDED CODE
              
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        shade,
                        style: TextStyle(
                          color: widget.getColor(shade),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (imageUrl != null)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageZoomScreen(
                                    imageUrls: [imageUrl],
                                    initialIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.image,
                                size: 12,
                                color: TableColors.accentColor,
                              ),
                            ),
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
      ...sizes.map(
        (size) => TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: TableColors.borderColor, width: 0.5),
              ),
            ),
            child: TextField(
              controller: widget.controllers[shade]?[size],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => widget.updateTotals(),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: TableColors.accentColor, width: 1),
                ),
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    ],
  );
}
  String? _getShadeImageUrl(String shadeName) {
    // Implement this based on your data structure
    // This is a placeholder - you'll need to implement based on how shade images are stored
    final item = widget.items.firstWhere(
      (item) => (item['shadeName']?.toString() ?? '') == shadeName,
      orElse: () => {},
    );
    
    if (item.isNotEmpty && item['shadeImagePath'] != null) {
      final imagePath = item['shadeImagePath'].toString();
      if (imagePath.isNotEmpty) {
        // Process image path similar to _getImageUrls
        if (UserSession.onlineImage == '0') {
          final fileName = imagePath.split('/').last.split('\\').last.split('?').first;
          return fileName.isEmpty ? null : '${AppConstants.BASE_URL}/images/$fileName';
        } else if (UserSession.onlineImage == '1') {
          return imagePath;
        }
      }
    }
    return null;
  }

  void _showShadeCopyOptions(String shade) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Copy Options for $shade',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _buildCopyOption(
                icon: Icons.copy_all,
                title: 'Copy Qty in shade only',
                description: 'Copy first quantity to all sizes in this shade',
                color: TableColors.accentColor,
                onTap: () {
                  Navigator.pop(context);
                  final firstQty = widget.controllers[shade]?.values.first.text;
                  for (var size in widget.controllers[shade]!.keys) {
                    widget.controllers[shade]![size]?.text = firstQty ?? '0';
                  }
                  widget.updateTotals();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCopyOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
    );
  }
Widget _buildActionButtons(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: noteController,
        decoration: InputDecoration(
          labelText: 'Note',
          labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: TableColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7, // Reduced vertical padding
          ),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 11),
      ),
      const SizedBox(height: 8), // Reduced spacing
      Row(
        children: [
          // Update Button
          Expanded(
            child: _buildCompactGradientButton(
              label: 'Update',
              icon: Icons.update,
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: () => _submitUpdate(context),
            ),
          ),
          const SizedBox(width: 8), // Reduced spacing
          // Remove Button
          Expanded(
            child: _buildCompactGradientButton(
              label: 'Remove',
              icon: Icons.delete,
              gradient: const LinearGradient(
                colors: [Color(0xFFf44336), Color(0xFFd32f2f)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onPressed: () => _submitDelete(context),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildCompactGradientButton({
  required String label,
  required IconData icon,
  required LinearGradient gradient,
  required VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    height: 32, // Fixed height - reduced from 36 to 28
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8), // Minimal padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        minimumSize: const Size(double.infinity, 32), // Reduced height
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces tap target size
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14), // Slightly smaller icon
          const SizedBox(width: 4), // Reduced spacing
          Text(
            label,
            style: const TextStyle(
              fontSize: 11, // Smaller font
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    ),
  );
}
  // Keep your existing _submitDelete and _submitUpdate methods as they are
  Future<void> _submitDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion", style: TextStyle(fontSize: 16)),
          content: const Text("Are you sure you want to delete this item?", style: TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(fontSize: 14)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 14)),
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
        Provider.of<CartModel>(context, listen: false).removeItem(sCode);
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
      builder:
          (_) => AlertDialog(
            title: const Text("Error", style: TextStyle(fontSize: 16)),
            content: Text(message, style: const TextStyle(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
    );
  }

  Future<void> _submitUpdate(BuildContext context) async {
    List<Future> apiCalls = [];
    final sizeDetails = _getSizeDetails(widget.items);
    int totalQty = 0;

    debugPrint('Submitting update for styleCode: ${widget.styleCode}');
    String sCode = widget.styleCode;
    String bCode = "";
    if (sCode.contains('---')) {
      List<String> parts = widget.styleCode.split('---');
      sCode = parts[0];
      bCode = parts[1];
    }
    
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

    final firstResponse = await http.post(
      Uri.parse(
        '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(initialPayload),
    );

    if (firstResponse.statusCode != 200) {
      debugPrint(
        'First API call failed with status code: ${firstResponse.statusCode}',
      );
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Error", style: TextStyle(fontSize: 16)),
              content: const Text("Failed to submit initial order details.", style: TextStyle(fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
      );
      return;
    }

    for (var shadeEntry in widget.controllers.entries) {
      String shade = shadeEntry.key;
      for (var sizeEntry in shadeEntry.value.entries) {
        String size = sizeEntry.key;
        String qty = sizeEntry.value.text;
        if (qty.isNotEmpty && int.tryParse(qty) != null && int.parse(qty) > 0) {
          totalQty += int.parse(qty);
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
        builder:
            (_) => AlertDialog(
              title: const Text("No Updates", style: TextStyle(fontSize: 16)),
              content: const Text("No quantities have been updated.", style: TextStyle(fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
      );
      return;
    }

    try {
      final responses = await Future.wait(apiCalls);
      if (responses.every((r) => r.statusCode == 200)) {
        debugPrint('Update successful for styleCode: ${widget.styleCode}');
        widget.onUpdate();
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Success", style: TextStyle(fontSize: 16)),
                content: const Text("Order details updated successfully.", style: TextStyle(fontSize: 14)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK", style: TextStyle(fontSize: 14)),
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
          builder:
              (_) => AlertDialog(
                title: const Text("Error", style: TextStyle(fontSize: 16)),
                content: const Text("Failed to update some order details.", style: TextStyle(fontSize: 14)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint('Error during update: $e');
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Error", style: TextStyle(fontSize: 16)),
              content: Text("Failed to submit update: $e", style: const TextStyle(fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(fontSize: 14)),
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
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
            SizedBox(height: 2),
            Text(
              'No Image',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple diagonal painter without gradient
class _SimpleDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3) // Simple white color with opacity
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}