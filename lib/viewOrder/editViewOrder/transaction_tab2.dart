import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

class TransactionTab2 extends StatefulWidget {
  const TransactionTab2({super.key});

  @override
  State<TransactionTab2> createState() => _TransactionTab2State();
}

class _TransactionTab2State extends State<TransactionTab2> {
  final Map<String, Set<String>> selectedShades = {};
  final Map<String, Map<String, Map<String, TextEditingController>>> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var order in EditOrderData.data) {
      final styleKey = order.catalog.styleKey;
      final shades = order.orderMatrix.shades;
      final sizes = order.orderMatrix.sizes;

      selectedShades[styleKey] = shades.toSet();;

      _controllers.putIfAbsent(styleKey, () => {});
      for (var shade in shades) {
        _controllers[styleKey]!.putIfAbsent(shade, () => {});
        for (var size in sizes) {
          _controllers[styleKey]![shade]![size] =
              TextEditingController(text: _getMatrixValue(order, shade, size)['qty'].toString());
        }
      }
    }
  }

  Map<String, dynamic> _getMatrixValue(CatalogOrderData order, String shade, String size) {
    final shadeIndex = order.orderMatrix.shades.indexOf(shade);
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

  void _setQuantity(String styleKey, String shade, String size, int newQuantity) {
    if (newQuantity < 0) return;
    setState(() {
      final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey);
      final shadeIndex = order.orderMatrix.shades.indexOf(shade);
      final sizeIndex = order.orderMatrix.sizes.indexOf(size);
      if (shadeIndex >= 0 && sizeIndex >= 0) {
        final parts = order.orderMatrix.matrix[shadeIndex][sizeIndex].split(',');
        if (parts.length >= 4) {
          parts[2] = newQuantity.toString();
          order.orderMatrix.matrix[shadeIndex][sizeIndex] = parts.join(',');
        }
      }
    });
  }

  int _calculateCatalogQuantity(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey);
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['qty']) ?? 0;
      }
    }
    return total;
  }

  int _calculateShadeQuantity(String styleKey, String shade) {
    int total = 0;
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey);
    for (var size in order.orderMatrix.sizes) {
      final value = _getMatrixValue(order, shade, size);
      total += int.tryParse(value['qty']) ?? 0;
    }
    return total;
  }

  double _calculateShadePrice(CatalogOrderData order, String shade) {
    double total = 0;
    final styleKey = order.catalog.styleKey;
    final matrix = order.orderMatrix;
    final shadeIndex = matrix.shades.indexOf(shade.trim());
    if (shadeIndex == -1) return total;
    for (var size in matrix.sizes) {
      final sizeIndex = matrix.sizes.indexOf(size.trim());
      if (sizeIndex == -1) continue;
      final parts = matrix.matrix[shadeIndex][sizeIndex].split(',');
      final rate = double.tryParse(parts[0]) ?? 0;
      final quantity = int.tryParse(parts[2]) ?? 0;
      total += rate * quantity;
    }
    return total;
  }

  void _copyStyleQuantities(String sourceStyleKey, Set<String> targetStyleKeys) {
    // Placeholder: Implement copying logic based on your requirements
    setState(() {
      // Example: Copy quantities from source to target style keys
    });
  }

  void _copyShadeQuantities(String styleKey, String sourceShade, Set<String> targetShades) {
    // Placeholder: Implement copying shade quantities
    setState(() {
      // Example: Copy quantities for selected shades
    });
  }

  void _deleteStyle(String styleKey) {
    setState(() {
      EditOrderData.data.removeWhere((order) => order.catalog.styleKey == styleKey);
      selectedShades.remove(styleKey);
      _controllers.remove(styleKey);
    });
  }

  Color _getColorCode(String shade) {
    // Placeholder: Return color based on shade name
    return Colors.black;
  }

  Widget _buildCatalogInfoCard(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;
    final imageUrl = catalog.fullImagePath.contains("http")
        ? catalog.fullImagePath
        : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 60),
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
                    Expanded(
                      child: Text(
                        catalog.styleCode,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // IconButton(
                        //   icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                        //   padding: EdgeInsets.zero,
                        //   constraints: const BoxConstraints(),
                        //   onPressed: () async {
                        //     final result = await showDialog<Set<String>>(
                        //       context: context,
                        //       builder: (context) => CopyToStylesDialog(
                        //         styleKeys: EditOrderData.data
                        //             .map((order) => order.catalog.styleKey)
                        //             .where((key) => key != catalog.styleKey)
                        //             .toList(),
                        //         styleCodes: EditOrderData.data
                        //             .map((order) => order.catalog.styleCode)
                        //             .toList(),
                        //         sourceStyleKey: catalog.styleKey,
                        //         sourceStyleCode: catalog.styleCode,
                        //       ),
                        //     );
                        //     if (result != null && result.isNotEmpty) {
                        //       _copyStyleQuantities(catalog.styleKey, result);
                        //     }
                        //   },
                        // ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _deleteStyle(catalog.styleKey);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Qty: ${_calculateCatalogQuantity(catalog.styleKey)}',
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
                Text(
                  'Pending Qty: 0 | Wip Stock: 0',
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final styleKey = catalogOrder.catalog.styleKey;
    final allShades = catalogOrder.catalog.shadeName.split(',').map((e) => e.trim()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Shade",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lora(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // IconButton(
                          //   icon: const Icon(Icons.copy_all_outlined, size: 16, color: Colors.grey),
                          //   padding: EdgeInsets.zero,
                          //   constraints: const BoxConstraints(),
                          //   onPressed: () async {
                          //     final result = await showDialog<Map<String, dynamic>>(
                          //       context: context,
                          //       builder: (context) => ShadeSelectionDialog(
                          //         shades: allShades.where((s) => s != shade).toList(),
                          //         sourceShade: shade,
                          //       ),
                          //     );
                          //     if (result != null) {
                          //       if (result['option'] == 'all_sizes') {
                          //         _copyShadeToAllSizes(styleKey, shade, sizes);
                          //       } else if (result['option'] == 'other_shades') {
                          //         final selectedShades = result['selectedShades'] as Set<String>;
                          //         if (selectedShades.isNotEmpty) {
                          //           _copyShadeQuantities(styleKey, shade, selectedShades);
                          //         }
                          //       }
                          //     }
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
                  _buildHeader("Quantity", 1),
                  _buildHeader("Price", 1),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        shade,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: _getColorCode(shade),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        _calculateShadeQuantity(styleKey, shade).toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Text(
                        '₹${_calculateShadePrice(catalogOrder, shade).toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              Row(
                children: [
                  _buildHeader("Size", 1),
                  _buildHeader("Qty", 2),
                  _buildHeader("Rate", 1),
                  _buildHeader("WSP", 1),
                  _buildHeader("Stock", 1),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              for (var size in sizes) ...[
                _buildSizeRow(catalogOrder, shade, size),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            ],
          ),
        ),
      ],
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

  Widget _buildSizeRow(CatalogOrderData catalogOrder, String shade, String size) {
    final styleKey = catalogOrder.catalog.styleKey;
    final value = _getMatrixValue(catalogOrder, shade, size);
    final controllerKey = '$styleKey-$shade-$size';
    final controller = _controllers[styleKey]![shade]!.putIfAbsent(
      size,
      () => TextEditingController(text: value['qty']),
    );
    if (controller.text != value['qty']) {
      controller.text = value['qty'];
    }

    return Row(
      children: [
        _buildCell(size, 1),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    final qty = int.tryParse(value['qty']) ?? 0;
                    _setQuantity(styleKey, shade, size, qty - 1);
                    controller.text = _getMatrixValue(catalogOrder, shade, size)['qty'];
                  },
                  icon: const Icon(Icons.remove, size: 20),
                ),
                SizedBox(
                  width: 22,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: GoogleFonts.roboto(fontSize: 14),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onChanged: (valueText) {
                      final newQuantity = int.tryParse(valueText.isEmpty ? '0' : valueText) ?? 0;
                      _setQuantity(styleKey, shade, size, newQuantity);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final qty = int.tryParse(value['qty']) ?? 0;
                    _setQuantity(styleKey, shade, size, qty + 1);
                    controller.text = _getMatrixValue(catalogOrder, shade, size)['qty'];
                  },
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
        ),
        _buildCell(value['mrp'], 1),
        _buildCell(value['wsp'], 1),
        _buildCell(value['stock'], 1),
      ],
    );
  }

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

  void _copyShadeToAllSizes(String styleKey, String shade, List<String> sizes) {
    // Placeholder: Implement copying shade quantities to all sizes
    setState(() {
      // Example: Copy quantities to all sizes
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          ...EditOrderData.data.map((catalogOrder) {
            final styleKey = catalogOrder.catalog.styleKey;
            final selectedColors = selectedShades[styleKey] ?? {};

            return Column(
              children: [
                _buildCatalogInfoCard(catalogOrder),
                const Divider(),
                ...selectedColors.map((shade) => Column(
                      children: [
                        _buildColorSection(catalogOrder, shade),
                        const SizedBox(height: 15),
                      ],
                    )),
                const SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Placeholder dialog classes to match first code's functionality
class CopyToStylesDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Copy to Styles'),
      content: Text('Select styles to copy quantities from $sourceStyleCode'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {}),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, styleKeys.toSet()),
          child: const Text('Copy'),
        ),
      ],
    );
  }
}

class ShadeSelectionDialog extends StatelessWidget {
  final List<String> shades;
  final String sourceShade;

  const ShadeSelectionDialog({
    super.key,
    required this.shades,
    required this.sourceShade,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Copy Shade: $sourceShade'),
      content: Text('Select shades or sizes to copy quantities'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'option': 'all_sizes'}),
          child: const Text('All Sizes'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, {'option': 'other_shades', 'selectedShades': shades.toSet()}),
          child: const Text('Other Shades'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}