import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';

class TransactionTab2 extends StatefulWidget {
  const TransactionTab2({super.key});

  @override
  State<TransactionTab2> createState() => _TransactionTab2State();
}

class _TransactionTab2State extends State<TransactionTab2> {
  final Map<String, Set<String>> selectedShades = {};
  final Map<String, Map<String, Map<String, TextEditingController>>>
  _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var order in EditOrderData.data) {
      final styleKey = order.catalog.styleKey;
      // Get shades, filter out null/empty
      List<String> shades =
          order.orderMatrix.shades
              .where((shade) => shade.isNotEmpty && shade != 'null')
              .toList();

      // If no valid shades, add placeholder
      if (shades.isEmpty) {
        shades = [''];
      }

      final sizes = order.orderMatrix.sizes;
      selectedShades[styleKey] = shades.toSet();
      _controllers.putIfAbsent(styleKey, () => {});

      for (var shade in shades) {
        _controllers[styleKey]!.putIfAbsent(shade, () => {});
        for (var size in sizes) {
          final value = _getMatrixValue(order, shade, size);
          _controllers[styleKey]![shade]![size] = TextEditingController(
            text: value['qty'].toString(),
          );
        }
      }
    }
  }

  Map<String, dynamic> _getMatrixValue(
    CatalogOrderData order,
    String shade,
    String size,
  ) {
    int shadeIndex = order.orderMatrix.shades.indexOf(shade);
    if (shadeIndex < 0 &&
        shade.isEmpty &&
        order.orderMatrix.shades.isNotEmpty) {
      shadeIndex = 0;
    }
    final sizeIndex = order.orderMatrix.sizes.indexOf(size);

    if (shadeIndex < 0 || sizeIndex < 0) {
      return {'mrp': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
    }

    final matrixEntry = order.orderMatrix.matrix[shadeIndex][sizeIndex];
    final parts = matrixEntry.split(',');
    if (parts.length < 4) {
      return {'mrp': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
    }

    return {
      'mrp': parts[0],
      'wsp': parts[1],
      'qty': parts[2],
      'stock': parts[3],
    };
  }

  void _setQuantity(
    String styleKey,
    String shade,
    String size,
    int newQuantity,
  ) {
    if (newQuantity < 0) return;
    setState(() {
      final order = EditOrderData.data.firstWhere(
        (o) => o.catalog.styleKey == styleKey,
      );
      int shadeIndex = order.orderMatrix.shades.indexOf(shade);
      if (shadeIndex < 0 &&
          shade.isEmpty &&
          order.orderMatrix.shades.isNotEmpty) {
        shadeIndex = 0;
      }
      final sizeIndex = order.orderMatrix.sizes.indexOf(size);
      if (shadeIndex >= 0 && sizeIndex >= 0) {
        final parts = order.orderMatrix.matrix[shadeIndex][sizeIndex].split(
          ',',
        );
        if (parts.length >= 4) {
          parts[2] = newQuantity.toString();
          order.orderMatrix.matrix[shadeIndex][sizeIndex] = parts.join(',');
        }
      }
      _controllers[styleKey]?[shade]?[size]?.text = newQuantity.toString();
    });
  }

  int _calculateCatalogQuantity(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['qty']) ?? 0;
      }
    }
    return total;
  }

  int _calculateCatalogStock(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['stock']) ?? 0;
      }
    }
    return total;
  }

  double _calculateCatalogAmount(String styleKey) {
    double total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        final wsp = double.tryParse(value['wsp']) ?? 0;
        final qty = int.tryParse(value['qty']) ?? 0;
        total += wsp * qty;
      }
    }
    return total;
  }

  int _calculateShadeQuantity(String styleKey, String shade) {
    int total = 0;
    final order = EditOrderData.data.firstWhere(
      (o) => o.catalog.styleKey == styleKey,
    );
    for (var size in order.orderMatrix.sizes) {
      final value = _getMatrixValue(order, shade, size);
      total += int.tryParse(value['qty']) ?? 0;
    }
    return total;
  }

  double _calculateShadeAmount(CatalogOrderData order, String shade) {
    double total = 0;
    int shadeIndex = order.orderMatrix.shades.indexOf(shade);
    if (shadeIndex < 0 &&
        shade.isEmpty &&
        order.orderMatrix.shades.isNotEmpty) {
      shadeIndex = 0;
    }
    if (shadeIndex == -1) return total;
    for (var size in order.orderMatrix.sizes) {
      final sizeIndex = order.orderMatrix.sizes.indexOf(size);
      if (sizeIndex == -1) continue;
      final parts = order.orderMatrix.matrix[shadeIndex][sizeIndex].split(',');
      final wsp = double.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 0;
      final quantity = int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
      total += wsp * quantity;
    }
    return total;
  }

  void _copyStyleQuantities(
    String sourceStyleKey,
    Set<String> targetStyleKeys,
  ) {
    setState(() {
      final sourceOrder = EditOrderData.data.firstWhere(
        (o) => o.catalog.styleKey == sourceStyleKey,
      );

      for (var targetStyleKey in targetStyleKeys) {
        final targetOrder = EditOrderData.data.firstWhere(
          (o) => o.catalog.styleKey == targetStyleKey,
        );
        final targetShades = selectedShades[targetStyleKey] ?? {};
        final validSizes = targetOrder.orderMatrix.sizes;

        // Copy quantities from source to target
        for (int i = 0; i < sourceOrder.orderMatrix.shades.length; i++) {
          final sourceShade = sourceOrder.orderMatrix.shades[i];

          // Check if target has this shade
          if (targetShades.contains(sourceShade)) {
            int targetShadeIndex = targetOrder.orderMatrix.shades.indexOf(
              sourceShade,
            );
            if (targetShadeIndex == -1 &&
                sourceShade.isEmpty &&
                targetOrder.orderMatrix.shades.isNotEmpty) {
              targetShadeIndex = 0;
            }

            if (targetShadeIndex != -1) {
              for (int j = 0; j < sourceOrder.orderMatrix.sizes.length; j++) {
                final size = sourceOrder.orderMatrix.sizes[j];
                int targetSizeIndex = validSizes.indexOf(size);

                if (targetSizeIndex != -1) {
                  // Get source quantity
                  final sourceParts = sourceOrder.orderMatrix.matrix[i][j]
                      .split(',');
                  if (sourceParts.length >= 4) {
                    final sourceQuantity = sourceParts[2];

                    // Update target matrix with source quantity
                    final targetParts = targetOrder
                        .orderMatrix
                        .matrix[targetShadeIndex][targetSizeIndex]
                        .split(',');
                    if (targetParts.length >= 4) {
                      targetParts[2] = sourceQuantity;
                      targetOrder
                              .orderMatrix
                              .matrix[targetShadeIndex][targetSizeIndex] =
                          targetParts.join(',');

                      // Update controller
                      _controllers[targetStyleKey]?[sourceShade]?[size]?.text =
                          sourceQuantity;
                    }
                  }
                }
              }
            }
          }
        }
      }
    });
  }

  void _copyShadeQuantities(
    String styleKey,
    String sourceShade,
    Set<String> targetShades,
  ) {
    setState(() {
      final order = EditOrderData.data.firstWhere(
        (o) => o.catalog.styleKey == styleKey,
      );
      int sourceShadeIndex = order.orderMatrix.shades.indexOf(sourceShade);
      if (sourceShadeIndex == -1 &&
          sourceShade.isEmpty &&
          order.orderMatrix.shades.isNotEmpty) {
        sourceShadeIndex = 0;
      }

      if (sourceShadeIndex == -1) return;

      // Get source quantities for all sizes
      Map<String, String> sourceQuantities = {};
      for (int j = 0; j < order.orderMatrix.sizes.length; j++) {
        final size = order.orderMatrix.sizes[j];
        final parts = order.orderMatrix.matrix[sourceShadeIndex][j].split(',');
        if (parts.length >= 4) {
          sourceQuantities[size] = parts[2];
        }
      }

      // Copy to each target shade
      for (var targetShade in targetShades) {
        int targetShadeIndex = order.orderMatrix.shades.indexOf(targetShade);
        if (targetShadeIndex == -1 &&
            targetShade.isEmpty &&
            order.orderMatrix.shades.isNotEmpty) {
          targetShadeIndex = 0;
        }

        if (targetShadeIndex != -1) {
          for (int j = 0; j < order.orderMatrix.sizes.length; j++) {
            final size = order.orderMatrix.sizes[j];
            final targetParts = order.orderMatrix.matrix[targetShadeIndex][j]
                .split(',');
            if (targetParts.length >= 4 && sourceQuantities.containsKey(size)) {
              targetParts[2] = sourceQuantities[size]!;
              order.orderMatrix.matrix[targetShadeIndex][j] = targetParts.join(
                ',',
              );

              // Update controller
              _controllers[styleKey]?[targetShade]?[size]?.text =
                  sourceQuantities[size]!;
            }
          }
        }
      }
    });
  }

  void _copyShadeToAllSizes(String styleKey, String shade, List<String> sizes) {
    setState(() {
      final order = EditOrderData.data.firstWhere(
        (o) => o.catalog.styleKey == styleKey,
      );
      int shadeIndex = order.orderMatrix.shades.indexOf(shade);
      if (shadeIndex < 0 &&
          shade.isEmpty &&
          order.orderMatrix.shades.isNotEmpty) {
        shadeIndex = 0;
      }

      if (shadeIndex >= 0 && sizes.isNotEmpty) {
        // Get quantity from first size
        String firstSizeQty = '0';
        final firstSizeParts = order.orderMatrix.matrix[shadeIndex][0].split(
          ',',
        );
        if (firstSizeParts.length >= 4) {
          firstSizeQty = firstSizeParts[2];
        }

        // Apply to all sizes
        for (int i = 0; i < sizes.length; i++) {
          final parts = order.orderMatrix.matrix[shadeIndex][i].split(',');
          if (parts.length >= 4) {
            parts[2] = firstSizeQty;
            order.orderMatrix.matrix[shadeIndex][i] = parts.join(',');

            // Update controller
            _controllers[styleKey]?[shade]?[sizes[i]]?.text = firstSizeQty;
          }
        }
      }
    });
  }

  void _deleteStyle(String styleKey) {
    setState(() {
      EditOrderData.data.removeWhere(
        (order) => order.catalog.styleKey == styleKey,
      );
      selectedShades.remove(styleKey);
      _controllers.remove(styleKey);
    });
  }

  Color _getColorCode(String shade) {
    if (shade.isEmpty) return Colors.grey;
    switch (shade.toLowerCase()) {
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
      default:
        return Colors.black;
    }
  }

  String _getImageUrl(CatalogOrderData catalogOrder) {
    final path = catalogOrder.catalog.fullImagePath;
    if (path.isEmpty) return '${AppConstants.BASE_URL}/images/NoImage.jpg';
    if (UserSession.onlineImage == '0') {
      final fileName = path.split('/').last.split('\\').last.split('?').first;
      return fileName.isEmpty
          ? '${AppConstants.BASE_URL}/images/NoImage.jpg'
          : '${AppConstants.BASE_URL}/images/$fileName';
    } else if (UserSession.onlineImage == '1') {
      return path.contains("http")
          ? path
          : '${AppConstants.BASE_URL}/images$path';
    }
    return '${AppConstants.BASE_URL}/images/NoImage.jpg';
  }

  bool _hasValidShades(CatalogOrderData catalogOrder) {
    return catalogOrder.orderMatrix.shades.any(
      (shade) => shade.isNotEmpty && shade != 'null',
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: color.shade700),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
  );

  Widget _buildCell(String text, int flex) => Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(fontSize: 14),
      ),
    ),
  );

  Widget _buildStickyHeader(CatalogOrderData catalogOrder) {
    final styleKey = catalogOrder.catalog.styleKey;
    final catalog = catalogOrder.catalog;
    final imageUrl = _getImageUrl(catalogOrder);
    final totalQty = _calculateCatalogQuantity(styleKey);
    final totalAmount = _calculateCatalogAmount(styleKey);
    final totalStock = _calculateCatalogStock(styleKey);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.primaryColor.withOpacity(0.03),
                AppColors.primaryColor.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ImageZoomScreen(
                              imageUrls: [imageUrl],
                              initialIndex: 0,
                            ),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.broken_image, size: 30),
                            ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.15),
                                  AppColors.primaryColor.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              catalog.styleCode,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          // Action Buttons Row - ADD COPY BUTTON HERE
                          Row(
                            children: [
                              /// Copy Button (from buildOrderCardOnly)
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    // Get all other style keys except current
                                    final otherStyleKeys =
                                        EditOrderData.data
                                            .map(
                                              (order) => order.catalog.styleKey,
                                            )
                                            .where(
                                              (key) => key != catalog.styleKey,
                                            )
                                            .toList();
                                    final otherStyleCodes =
                                        EditOrderData.data
                                            .map(
                                              (order) =>
                                                  order.catalog.styleCode,
                                            )
                                            .where(
                                              (code) =>
                                                  code != catalog.styleCode,
                                            )
                                            .toList();

                                    final result = await showDialog<
                                      Set<String>
                                    >(
                                      context: context,
                                      builder:
                                          (context) => CopyToStylesDialog(
                                            styleKeys: otherStyleKeys,
                                            styleCodes: otherStyleCodes,
                                            sourceStyleKey: catalog.styleKey,
                                            sourceStyleCode: catalog.styleCode,
                                          ),
                                    );
                                    if (result != null && result.isNotEmpty) {
                                      _copyStyleQuantities(
                                        catalog.styleKey,
                                        result,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryColor.withOpacity(
                                            0.15,
                                          ),
                                          AppColors.primaryColor.withOpacity(
                                            0.05,
                                          ),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              /// Delete Button
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _showDeleteDialog(
                                        context,
                                        catalogOrder,
                                      ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'Qty',
                              totalQty.toString(),
                              Icons.shopping_bag,
                              Colors.green,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade300,
                            ),
                            _buildStatItem(
                              'Stock',
                              totalStock.toString(),
                              Icons.inventory,
                              Colors.blue,
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade300,
                            ),
                            _buildStatItem(
                              'Amt',
                              '₹${totalAmount.toStringAsFixed(0)}',
                              Icons.currency_rupee,
                              Colors.purple,
                            ),
                          ],
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
  }

  // No Shade Card (exactly like reference)
  Widget _buildNoShadeCard(CatalogOrderData catalogOrder) {
    final styleKey = catalogOrder.catalog.styleKey;
    final catalog = catalogOrder.catalog;
    final matrix = catalogOrder.orderMatrix;
    final imageUrl = _getImageUrl(catalogOrder);
    final totalQty = _calculateCatalogQuantity(styleKey);
    final totalAmount = _calculateCatalogAmount(styleKey);
    final totalStock = _calculateCatalogStock(styleKey);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.primaryColor.withOpacity(0.03),
                  AppColors.primaryColor.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onDoubleTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ImageZoomScreen(
                                imageUrls: [imageUrl],
                                initialIndex: 0,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      width: 70,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.broken_image, size: 30),
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryColor.withOpacity(0.15),
                                    AppColors.primaryColor.withOpacity(0.08),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                catalog.styleCode,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _showDeleteDialog(
                                      context,
                                      catalogOrder,
                                    ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                'Qty',
                                totalQty.toString(),
                                Icons.shopping_bag,
                                Colors.green,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              _buildStatItem(
                                'Stock',
                                totalStock.toString(),
                                Icons.inventory,
                                Colors.blue,
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.grey.shade300,
                              ),
                              _buildStatItem(
                                'Amt',
                                '₹${totalAmount.toStringAsFixed(0)}',
                                Icons.currency_rupee,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // QUANTITY and AMOUNT Header Row
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(" ", textAlign: TextAlign.center),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      "QUANTITY",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "AMOUNT",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Quantity and Amount Values Row with borders
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text(" ", textAlign: TextAlign.center),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      totalQty.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size Matrix Table Headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                _buildHeader("SIZE", 1),
                _buildHeader("QTY", 2),
                _buildHeader("MRP", 1),
                _buildHeader("WSP", 1),
                _buildHeader("STOCK", 1),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Size rows with horizontal dividers
          for (var i = 0; i < matrix.sizes.length; i++) ...[
            _buildNoShadeSizeRow(
              catalogOrder,
              matrix.sizes[i],
              matrix.matrix[0][i],
            ),
            if (i != matrix.sizes.length - 1)
              Divider(height: 1, color: Colors.grey.shade300),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNoShadeSizeRow(
    CatalogOrderData catalogOrder,
    String size,
    String matrixData,
  ) {
    final styleKey = catalogOrder.catalog.styleKey;
    final matrixParts = matrixData.split(',');
    final rate = matrixParts[0];
    final wsp = matrixParts.length > 1 ? matrixParts[1] : '0';
    final stock = matrixParts.length > 2 ? matrixParts[2] : '0';

    final shadeKey = '';
    final controller = _controllers[styleKey]?[shadeKey]?[size];
    final quantity = int.tryParse(controller?.text ?? '0') ?? 0;

    return Row(
      children: [
        // SIZE column with right border
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              size,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // QTY column with right border
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Add this to minimize width
              children: [
                IconButton(
                  onPressed:
                      () =>
                          _setQuantity(styleKey, shadeKey, size, quantity - 1),
                  icon: const Icon(Icons.remove, size: 16), // Reduced from 18
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ), // Add constraints
                  visualDensity: VisualDensity.compact, // Add this
                ),
                SizedBox(
                  width: 40, // Reduced from 45
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ), // Reduced padding
                      hintText: stock,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      border: InputBorder.none,
                      isDense: true, // Add this to make it more compact
                    ),
                    style: const TextStyle(fontSize: 11),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged:
                        (val) => _setQuantity(
                          styleKey,
                          shadeKey,
                          size,
                          int.tryParse(val) ?? 0,
                        ),
                  ),
                ),
                IconButton(
                  onPressed:
                      () =>
                          _setQuantity(styleKey, shadeKey, size, quantity + 1),
                  icon: const Icon(Icons.add, size: 16), // Reduced from 18
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ), // Add constraints
                  visualDensity: VisualDensity.compact, // Add this
                ),
              ],
            ),
          ),
        ),
        // MRP column with right border
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              rate,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // WSP column with right border
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              wsp,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // STOCK column (no right border)
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              stock,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // Shade Card (exactly like reference)
  Widget _buildShadeCard(CatalogOrderData catalogOrder, String shade) {
    final styleKey = catalogOrder.catalog.styleKey;
    final sizes = catalogOrder.orderMatrix.sizes;
    final totalQty = _calculateShadeQuantity(styleKey, shade);
    final totalAmount = _calculateShadeAmount(catalogOrder, shade);
    final allShades =
        catalogOrder.catalog.shadeName
            .split(',')
            .map((e) => e.trim())
            .where((s) => s.isNotEmpty && s != 'null')
            .toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Header row with SHADE label, copy icon, QUANTITY, AMOUNT
              // Header row with SHADE label, copy icon, QUANTITY, AMOUNT
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                            ), // ADD THIS LINE
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "SHADE",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            // Copy icon next to SHADE label
                            if (allShades.length > 1 && shade.isNotEmpty)
                              const SizedBox(width: 8),
                            if (allShades.length > 1 && shade.isNotEmpty)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    final result =
                                        await showDialog<Map<String, dynamic>>(
                                          context: context,
                                          builder:
                                              (context) => ShadeSelectionDialog(
                                                shades:
                                                    allShades
                                                        .where(
                                                          (s) => s != shade,
                                                        )
                                                        .toList(),
                                                sourceShade: shade,
                                              ),
                                        );
                                    if (result != null) {
                                      if (result['option'] == 'all_sizes') {
                                        _copyShadeToAllSizes(
                                          styleKey,
                                          shade,
                                          sizes,
                                        );
                                      } else if (result['option'] ==
                                          'other_shades') {
                                        final selectedShades =
                                            result['selectedShades']
                                                as Set<String>;
                                        if (selectedShades.isNotEmpty) {
                                          _copyShadeQuantities(
                                            styleKey,
                                            shade,
                                            selectedShades,
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _buildHeader("QUANTITY", 1),
                    _buildHeader("AMOUNT", 1),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),

              // Values row: Shade name, Quantity, Amount
              // Values row: Shade name, Quantity, Amount
              Container(
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                            ), // ADD THIS LINE
                          ),
                        ),
                        child: Text(
                          shade,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getColorCode(shade),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                            ), // ADD THIS LINE
                          ),
                        ),
                        child: Text(
                          totalQty.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),

              // Size headers
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    _buildHeader("SIZE", 1),
                    _buildHeader("QTY", 2),
                    _buildHeader("MRP", 1),
                    _buildHeader("WSP", 1),
                    _buildHeader("STOCK", 1),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade300),

              // Size rows
              for (var size in sizes) ...[
                _buildSizeRow(catalogOrder, shade, size),
                if (size != sizes.last)
                  Divider(height: 1, color: Colors.grey.shade300),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeRow(
    CatalogOrderData catalogOrder,
    String shade,
    String size,
  ) {
    final styleKey = catalogOrder.catalog.styleKey;
    final value = _getMatrixValue(catalogOrder, shade, size);
    final controller = _controllers[styleKey]?[shade]?[size];
    final quantity = int.tryParse(value['qty']) ?? 0;

    return Row(
      children: [
        // SIZE column with right border
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              size,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // QTY column with right border
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap:
                      () => _setQuantity(styleKey, shade, size, quantity - 1),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.remove, size: 14),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 0,
                      ),
                      hintText: value['stock'],
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged:
                        (val) => _setQuantity(
                          styleKey,
                          shade,
                          size,
                          int.tryParse(val) ?? 0,
                        ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap:
                      () => _setQuantity(styleKey, shade, size, quantity + 1),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        // MRP column with right border
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              value['mrp'],
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // WSP column with right border
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Text(
              value['wsp'],
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
        // STOCK column (no right border on last column)
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              value['stock'],
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, CatalogOrderData catalogOrder) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white,
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      catalogOrder.catalog.styleCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete this style?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        backgroundColor: Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _deleteStyle(catalogOrder.catalog.styleKey);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> slivers = [];

    for (var catalogOrder in EditOrderData.data) {
      final hasShades = _hasValidShades(catalogOrder);
      final styleKey = catalogOrder.catalog.styleKey;
      final shades =
          selectedShades[styleKey]
              ?.where((s) => s.isNotEmpty && s != 'null')
              .toList() ??
          [];

      if (!hasShades || shades.isEmpty) {
        // No shades - regular card (non-sticky)
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: _buildNoShadeCard(catalogOrder),
            ),
          ),
        );
      } else {
        // With shades - sticky header
        slivers.add(
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CardHeaderDelegate(
                  minHeight: 140,
                  maxHeight: 140,
                  child: _buildStickyHeader(catalogOrder),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final shade = shades[index];
                  return Column(
                    children: [
                      _buildShadeCard(catalogOrder, shade),
                      const SizedBox(height: 12),
                    ],
                  );
                }, childCount: shades.length),
              ),
            ],
          ),
        );
      }
    }

    return CustomScrollView(slivers: slivers);
  }
}

// Card Header Delegate for sticky header
class _CardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _CardHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: child);
  }

  @override
  bool shouldRebuild(covariant _CardHeaderDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

// Dialog classes
class CopyToStylesDialog extends StatefulWidget {
  final List<String> styleKeys;
  final List<String> styleCodes;
  final String sourceStyleKey;
  final String sourceStyleCode;

  const CopyToStylesDialog({
    super.key,
    required this.styleKeys,
    required this.styleCodes,
    required this.sourceStyleKey,
    required this.sourceStyleCode,
  });

  @override
  State<CopyToStylesDialog> createState() => _CopyToStylesDialogState();
}

class _CopyToStylesDialogState extends State<CopyToStylesDialog> {
  late Set<String> _selectedStyleKeys;

  @override
  void initState() {
    super.initState();
    _selectedStyleKeys = widget.styleKeys.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Copy Qty to Other Styles', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Copying from: ${widget.sourceStyleCode}',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...widget.styleKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final styleKey = entry.value;
              final styleCode = widget.styleCodes[index];
              return CheckboxListTile(
                title: Text(styleCode, style: GoogleFonts.roboto()),
                value: _selectedStyleKeys.contains(styleKey),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedStyleKeys.add(styleKey);
                    } else {
                      _selectedStyleKeys.remove(styleKey);
                    }
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: GoogleFonts.montserrat()),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _selectedStyleKeys);
          },
          child: Text('OK', style: GoogleFonts.montserrat()),
        ),
      ],
    );
  }
}

class ShadeSelectionDialog extends StatefulWidget {
  final List<String> shades;
  final String sourceShade;

  const ShadeSelectionDialog({
    super.key,
    required this.shades,
    required this.sourceShade,
  });

  @override
  State<ShadeSelectionDialog> createState() => _ShadeSelectionDialogState();
}

class _ShadeSelectionDialogState extends State<ShadeSelectionDialog> {
  final Set<String> _selectedShades = {};
  bool _isAllSizesChecked = false;
  bool _showShadeSelection = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Copy Quantities', style: GoogleFonts.poppins()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showShadeSelection) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Copy quantity in all sizes of "${widget.sourceShade}"',
                    style: GoogleFonts.roboto(),
                  ),
                  value: _isAllSizesChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isAllSizesChecked = value ?? false;
                    });
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showShadeSelection = true;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Copy quantities of "${widget.sourceShade}" in other shades',
                          style: GoogleFonts.roboto(),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_showShadeSelection) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Copying from: ${widget.sourceShade}',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...widget.shades.map((shade) {
                return CheckboxListTile(
                  title: Text(shade, style: GoogleFonts.roboto()),
                  value: _selectedShades.contains(shade),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedShades.add(shade);
                      } else {
                        _selectedShades.remove(shade);
                      }
                    });
                  },
                );
              }).toList(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: GoogleFonts.montserrat()),
        ),
        TextButton(
          onPressed: () {
            if (_isAllSizesChecked && !_showShadeSelection) {
              Navigator.pop(context, {
                'option': 'all_sizes',
                'sourceShade': widget.sourceShade,
              });
            } else if (_showShadeSelection && _selectedShades.isNotEmpty) {
              Navigator.pop(context, {
                'option': 'other_shades',
                'selectedShades': _selectedShades,
              });
            }
          },
          child: Text('OK', style: GoogleFonts.montserrat()),
        ),
      ],
    );
  }
}
