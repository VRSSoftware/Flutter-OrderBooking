import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

class TransactionTab3 extends StatefulWidget {
  const TransactionTab3({super.key});

  @override
  State<TransactionTab3> createState() => _TransactionTab3State();
}

class _TransactionTab3State extends State<TransactionTab3> {
  final Map<String, Map<String, Map<String, TextEditingController>>> controllersMap = {};
  final Map<String, List<String>> copiedRowsMap = {};
  final Map<String, List<String>> sizesMap = {};
  final Map<String, Map<String, double>> sizeMrpMap = {};
  final Map<String, Map<String, double>> sizeWspMap = {};
  final Map<String, List<String>> colorsMap = {};
  final int maxSizes = 10; // Adjust based on maximum sizes

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    for (var order in EditOrderData.data) {
      final styleKey = order.catalog.styleKey;
      final shades = order.orderMatrix.shades;
      final sizes = order.orderMatrix.sizes;

      sizesMap[styleKey] = sizes;
      colorsMap[styleKey] = shades;
      sizeMrpMap[styleKey] = {};
      sizeWspMap[styleKey] = {};
      controllersMap.putIfAbsent(styleKey, () => {});
      for (var shade in shades) {
        controllersMap[styleKey]!.putIfAbsent(shade, () => {});
        for (var size in sizes) {
          final value = _getMatrixValue(order, shade, size);
          controllersMap[styleKey]![shade]![size] = TextEditingController(
            text: value['qty'].toString(),
          );
          sizeMrpMap[styleKey]![size] = double.tryParse(value['mrp']) ?? 0;
          sizeWspMap[styleKey]![size] = double.tryParse(value['wsp']) ?? 0;
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
      return {' three': '0', 'wsp': '0', 'qty': '0', 'stock': '0'};
    }

    return {
      'mrp': parts[0],
      'wsp': parts[1],
      'qty': parts[2],
      'stock': parts[3],
    };
  }

  void _setQuantity(String styleKey, String shade, String size, String value) {
    final newQty = int.tryParse(value.isEmpty ? '0' : value) ?? 0;
    if (newQty < 0) return;
    setState(() {
      final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey);
      final shadeIndex = order.orderMatrix.shades.indexOf(shade);
      final sizeIndex = order.orderMatrix.sizes.indexOf(size);
      if (shadeIndex >= 0 && sizeIndex >= 0) {
        final parts = order.orderMatrix.matrix[shadeIndex][sizeIndex].split(',');
        if (parts.length >= 4) {
          parts[2] = newQty.toString();
          order.orderMatrix.matrix[shadeIndex][sizeIndex] = parts.join(',');
        }
      }
      controllersMap[styleKey]?[shade]?[size]?.text = newQty.toString();
    });
  }

  int getTotalQty(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey, );
    if (order == null) return 0;
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['qty']) ?? 0;
      }
    }
    return total;
  }

  int getTotalStock(String styleKey) {
    int total = 0;
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey, );
    if (order == null) return 0;
    for (var shade in order.orderMatrix.shades) {
      for (var size in order.orderMatrix.sizes) {
        final value = _getMatrixValue(order, shade, size);
        total += int.tryParse(value['stock']) ?? 0;
      }
    }
    return total;
  }

  double getTotalAmount(String styleKey) {
    double total = 0;
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey, );
    if (order == null) return 0;
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

  void _copyQtyInAllShade(String styleKey) {
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey, );
    if (order == null) return;
    final firstShade = order.orderMatrix.shades.first;
    final sizes = order.orderMatrix.sizes;
    setState(() {
      for (var size in sizes) {
        final firstQty = controllersMap[styleKey]?[firstShade]?[size]?.text ?? '0';
        for (var shade in order.orderMatrix.shades) {
          controllersMap[styleKey]?[shade]?[size]?.text = firstQty;
          _setQuantity(styleKey, shade, size, firstQty);
        }
      }
    });
  }

  void _copySizeQtyInAllShade(String styleKey) {
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == styleKey, );
    if (order == null) return;
    final shades = order.orderMatrix.shades;
    final sizes = order.orderMatrix.sizes;
    setState(() {
      for (var shade in shades) {
        for (var size in sizes) {
          final qty = controllersMap[styleKey]?[shades.first]?[size]?.text ?? '0';
          controllersMap[styleKey]?[shade]?[size]?.text = qty;
          _setQuantity(styleKey, shade, size, qty);
        }
      }
    });
  }

  void _copySizeQtyToOtherStyles(String sourceStyleKey) {
    final order = EditOrderData.data.firstWhere((o) => o.catalog.styleKey == sourceStyleKey, );
    if (order == null) return;
    final sizes = order.orderMatrix.sizes;
    setState(() {
      for (var targetOrder in EditOrderData.data) {
        if (targetOrder.catalog.styleKey == sourceStyleKey) continue;
        final targetShades = targetOrder.orderMatrix.shades;
        for (var shade in targetShades) {
          for (var size in sizes) {
            if (targetOrder.orderMatrix.sizes.contains(size)) {
              final qty = controllersMap[sourceStyleKey]?[order.orderMatrix.shades.first]?[size]?.text ?? '0';
              controllersMap[targetOrder.catalog.styleKey]?[shade]?[size]?.text = qty;
              _setQuantity(targetOrder.catalog.styleKey, shade, size, qty);
            }
          }
        }
      }
    });
  }

  void _deleteCatalog(CatalogOrderData catalog) {
    setState(() {
      EditOrderData.data.removeWhere((order) => order.catalog.styleKey == catalog.catalog.styleKey);
      controllersMap.remove(catalog.catalog.styleKey);
      copiedRowsMap.remove(catalog.catalog.styleKey);
      sizesMap.remove(catalog.catalog.styleKey);
      sizeMrpMap.remove(catalog.catalog.styleKey);
      sizeWspMap.remove(catalog.catalog.styleKey);
      colorsMap.remove(catalog.catalog.styleKey);
    });
  }



  Color _getColorCode(String color) {
    // Placeholder: Map color names to Color objects
    return Colors.black;
  }

  String _getImageUrl(CatalogOrderData catalog) {
    return catalog.catalog.fullImagePath.contains("http")
        ? catalog.catalog.fullImagePath
        : '${AppConstants.BASE_URL}/images${catalog.catalog.fullImagePath}';
  }

  Widget _buildItemBookingSection(BuildContext context, CatalogOrderData catalog) {
    final styleKey = catalog.catalog.styleKey;
    if (catalog.orderMatrix.shades.isEmpty) {
      return const Center(child: Text("Empty"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16, top: 8),
              width: 100,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getImageUrl(catalog),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.error)),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            catalog.catalog.styleCode,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
title: const Text('Select an Action'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        _copyQtyInAllShade(styleKey);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Copy Qty in All Shade',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        _copySizeQtyInAllShade(styleKey);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Copy Size Qty in All Shade',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        _copySizeQtyToOtherStyles(styleKey);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Copy Size Qty to other Styles',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                        onPressed: () => _deleteCatalog(catalog),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          'Total Qty: ${getTotalQty(styleKey)}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Total Stock: ${getTotalStock(styleKey)}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Amt: ${getTotalAmount(styleKey).toStringAsFixed(0)}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCatalogTable(catalog),
      ],
    );
  }

  Widget _buildCatalogTable(CatalogOrderData catalog) {
    final sizes = catalog.orderMatrix.sizes;
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTableWidth = 100 + (80 * sizes.length);
    final requiredTableWidth = screenWidth > baseTableWidth ? screenWidth : baseTableWidth.toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16,
      vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade500),
        borderRadius: BorderRadius.circular(0),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: requiredTableWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              columnWidths: _buildColumnWidths(),
              children: [
                _buildPriceRow("MRP", sizeMrpMap[catalog.catalog.styleKey] ?? {}, FontWeight.w600, sizes),
                _buildPriceRow("WSP", sizeWspMap[catalog.catalog.styleKey] ?? {}, FontWeight.w400, sizes),
                _buildHeaderRow(catalog.catalog.styleKey, sizes),
                for (var i = 0; i < (colorsMap[catalog.catalog.styleKey]?.length ?? 0); i++)
                  _buildQuantityRow(catalog, colorsMap[catalog.catalog.styleKey]![i], i, sizes),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths() {
    const baseWidth = 100.0;
    return {
      0: const FixedColumnWidth(baseWidth),
      for (int i = 0; i < maxSizes; i++) (i + 1): const FixedColumnWidth(baseWidth * 0.8),
    };
  }

  TableRow _buildPriceRow(String label, Map<String, double> sizePriceMap, FontWeight weight, List<String> sizes) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: TextStyle(fontWeight: weight)),
          ),
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            final size = sizes[index];
            final price = sizePriceMap[size] ?? 0.0;
            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(
                child: Text(
                  price.toStringAsFixed(0),
                  style: TextStyle(fontWeight: weight),
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

  TableRow _buildHeaderRow(String styleKey, List<String> sizes) {
    return TableRow(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 236, 212, 204),
      ),
      children: [
        const TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: _TableHeaderCell(),
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(
                child: Text(
                  sizes[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

  TableRow _buildQuantityRow(CatalogOrderData catalog, String color, int i, List<String> sizes) {
    final styleKey = catalog.catalog.styleKey;
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  child: const Icon(Icons.copy_all, size: 12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: const Text('Select an Action'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  final firstQty = controllersMap[styleKey]?[color]?.values.first.text ?? '0';
                                  for (var size in sizesMap[styleKey] ?? []) {
                                    controllersMap[styleKey]?[color]?[size]?.text = firstQty;
                                    _setQuantity(styleKey, color, size, firstQty);
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Copy Qty in shade only',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  List<String> copiedRow = [];
                                  for (var size in sizesMap[styleKey] ?? []) {
                                    final qty = controllersMap[styleKey]?[color]?[size]?.text ?? '0';
                                    copiedRow.add(qty);
                                  }
                                  copiedRowsMap[styleKey] = copiedRow;
                                  setState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Copy Row',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  final copiedRow = copiedRowsMap[styleKey] ?? [];
                                  for (int j = 0; j < (sizesMap[styleKey]?.length ?? 0); j++) {
                                    controllersMap[styleKey]?[color]?[sizesMap[styleKey]![j]]?.text = copiedRow[j];
                                    _setQuantity(styleKey, color, sizesMap[styleKey]![j], copiedRow[j]);
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Paste Row',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    color,
                    style: TextStyle(
                      color: _getColorCode(color),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            final size = sizes[index];
            final controller = controllersMap[styleKey]?[color]?[size];
            final originalQty = int.tryParse(_getMatrixValue(catalog, color, size)['qty']) ?? 0;

            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: originalQty > 0 ? originalQty.toString() : '0',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (value) => _setQuantity(styleKey, color, size, value),
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                ...EditOrderData.data.map((catalogOrder) {
                  return Column(
                    children: [
                      _buildItemBookingSection(context, catalogOrder),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
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