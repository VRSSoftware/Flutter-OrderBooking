// 🔥 FINAL MERGED VERSION (CREATE UI + EDIT LOGIC EXACT)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';

class TransactionTabSticky extends StatefulWidget {
  final VoidCallback? onUpdate;

  const TransactionTabSticky({super.key, this.onUpdate});

  @override
  State<TransactionTabSticky> createState() => _TransactionTabStickyState();
}

class _TransactionTabStickyState extends State<TransactionTabSticky> {

  final Map<String, Map<String, Map<String, TextEditingController>>> controllersMap = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (var order in EditOrderData.data) {
      final styleKey = order.catalog.styleKey;

      controllersMap.putIfAbsent(styleKey, () => {});

      for (var shade in order.orderMatrix.shades) {
        controllersMap[styleKey]!.putIfAbsent(shade, () => {});

        for (var size in order.orderMatrix.sizes) {
          final val = _getMatrixValue(order, shade, size);

          controllersMap[styleKey]![shade]![size] =
              TextEditingController(text: val['qty'].toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ...EditOrderData.data.map((e) => _buildStickySection(e)),
      ],
    );
  }

  // ================= STICKY =================

  Widget _buildStickySection(CatalogOrderData catalogOrder) {
    final shades = catalogOrder.orderMatrix.shades;

    return SliverMainAxisGroup(
      slivers: [

        /// 🔥 EXACT SAME CARD
        SliverPersistentHeader(
          pinned: true,
          delegate: _CardHeaderDelegate(
            height: 140,
            child: buildOrderCardOnly(catalogOrder),
          ),
        ),

        /// 🔥 EXACT SAME SHADE FLOW
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final shade = shades[index];

            return Column(
              children: [
                _buildColorSection(catalogOrder, shade),
                const SizedBox(height: 12),
              ],
            );
          }, childCount: shades.length),
        ),
      ],
    );
  }

  // ================= CARD =================

  Widget buildOrderCardOnly(CatalogOrderData catalogOrder) {
    final catalog = catalogOrder.catalog;

    final imageUrl =
        catalog.fullImagePath.contains("http")
            ? catalog.fullImagePath
            : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Image.network(imageUrl, width: 60),
          title: Text(
            catalog.styleCode,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("Qty: ${_calculateCatalogQty(catalog.styleKey)}"),
        ),
      ),
    );
  }

  // ================= COLOR SECTION (EXACT UI) =================

  Widget _buildColorSection(CatalogOrderData catalogOrder, String shade) {
    final sizes = catalogOrder.orderMatrix.sizes;
    final styleKey = catalogOrder.catalog.styleKey;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [

          /// HEADER
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(child: Text("SHADE")),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _calculateShadeQty(styleKey, shade).toString(),
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "₹${_calculateShadeAmount(catalogOrder, shade).toStringAsFixed(0)}",
                      style: TextStyle(color: Colors.purple),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// SHADE NAME
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              shade,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),

          /// SIZE HEADER
          Container(
            color: Colors.grey.shade200,
            child: Row(
              children: [
                _cell("SIZE"),
                _cell("QTY"),
                _cell("MRP"),
                _cell("WSP"),
                _cell("STOCK"),
              ],
            ),
          ),

          /// SIZE ROWS
          ...sizes.map((size) {
            return _buildSizeRow(catalogOrder, shade, size);
          }),
        ],
      ),
    );
  }

  Widget _buildSizeRow(
      CatalogOrderData catalogOrder,
      String shade,
      String size,
      ) {
    final matrix = catalogOrder.orderMatrix;
    final styleKey = catalogOrder.catalog.styleKey;

    final i = matrix.shades.indexOf(shade);
    final j = matrix.sizes.indexOf(size);

    final parts = matrix.matrix[i][j].split(',');

    final mrp = parts[0];
    final wsp = parts[1];
    final stock = parts.length > 3 ? parts[3] : "0";

    final controller = controllersMap[styleKey]?[shade]?[size];

    return Row(
      children: [
        _cell(size),

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  final v = int.tryParse(controller?.text ?? "0") ?? 0;
                  controller?.text = (v - 1).toString();
                  _setQty(styleKey, shade, size);
                },
                icon: const Icon(Icons.remove, size: 18),
              ),

              SizedBox(
                width: 30,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _setQty(styleKey, shade, size),
                ),
              ),

              IconButton(
                onPressed: () {
                  final v = int.tryParse(controller?.text ?? "0") ?? 0;
                  controller?.text = (v + 1).toString();
                  _setQty(styleKey, shade, size);
                },
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),

        _cell(mrp),
        _cell(wsp),
        _cell(stock),
      ],
    );
  }

  Widget _cell(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  // ================= LOGIC =================

  void _setQty(String styleKey, String shade, String size) {
    final txt = controllersMap[styleKey]?[shade]?[size]?.text ?? '0';
    final qty = int.tryParse(txt) ?? 0;

    final order = EditOrderData.data.firstWhere(
          (e) => e.catalog.styleKey == styleKey,
    );

    final i = order.orderMatrix.shades.indexOf(shade);
    final j = order.orderMatrix.sizes.indexOf(size);

    final parts = order.orderMatrix.matrix[i][j].split(',');
    parts[2] = qty.toString();

    order.orderMatrix.matrix[i][j] = parts.join(',');

    widget.onUpdate?.call();
  }

  Map<String, dynamic> _getMatrixValue(
      CatalogOrderData o,
      String shade,
      String size,
      ) {
    final i = o.orderMatrix.shades.indexOf(shade);
    final j = o.orderMatrix.sizes.indexOf(size);

    final parts = o.orderMatrix.matrix[i][j].split(',');

    return {
      "mrp": parts[0],
      "wsp": parts[1],
      "qty": parts[2],
      "stock": parts[3],
    };
  }

  int _calculateCatalogQty(String key) {
    int t = 0;
    final o = EditOrderData.data.firstWhere((e) => e.catalog.styleKey == key);

    for (var s in o.orderMatrix.shades) {
      for (var sz in o.orderMatrix.sizes) {
        t += int.tryParse(_getMatrixValue(o, s, sz)['qty']) ?? 0;
      }
    }
    return t;
  }

  int _calculateShadeQty(String styleKey, String shade) {
    int t = 0;
    final o = EditOrderData.data.firstWhere(
          (e) => e.catalog.styleKey == styleKey,
    );

    for (var size in o.orderMatrix.sizes) {
      t += int.tryParse(_getMatrixValue(o, shade, size)['qty']) ?? 0;
    }
    return t;
  }

  double _calculateShadeAmount(CatalogOrderData catalogOrder, String shade) {
    double total = 0;
    final styleKey = catalogOrder.catalog.styleKey;

    for (var size in catalogOrder.orderMatrix.sizes) {
      final val = _getMatrixValue(catalogOrder, shade, size);
      final wsp = double.tryParse(val['wsp']) ?? 0;
      final qty =
          int.tryParse(controllersMap[styleKey]?[shade]?[size]?.text ?? '0') ?? 0;

      total += wsp * qty;
    }
    return total;
  }
}

// ================= HEADER =================

class _CardHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CardHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(color: Colors.white, child: child);
  }

  @override
  bool shouldRebuild(_) => false;
}