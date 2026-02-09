import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

class TransactionBarcode2 extends StatefulWidget {
  const TransactionBarcode2({super.key, required });

  @override
  State<TransactionBarcode2> createState() => _TransactionBarcode2State();
}

class _TransactionBarcode2State extends State<TransactionBarcode2> {
  final Map<String, Map<String, TextEditingController>> controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var item in EditOrderData.data) {
      final styleKey = item.catalog.styleCode;
      controllers[styleKey] = {};
      for (var size in item.orderMatrix.sizes) {
        controllers[styleKey]![size] = TextEditingController(
          text: _getQty(item, size),
        );
      }
    }
  }

  String _getQty(CatalogOrderData data, String size) {
    final sizeIndex = data.orderMatrix.sizes.indexOf(size);
    if (sizeIndex == -1) return '0';
    final qtyList = data.orderMatrix.matrix;
    final qty = qtyList.expand((i) => i).elementAt(sizeIndex).split(',');
    return qty.length > 2 ? qty[2] : '0';
  }

  @override
  void dispose() {
    for (var ctrl in controllers.values) {
      for (var c in ctrl.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditOrderData.data.isEmpty
        ? const Center(child: Text('No items found'))
        : ListView.builder(
            itemCount: EditOrderData.data.length,
            itemBuilder: (context, index) {
              final catalogOrder = EditOrderData.data[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: buildOrderItem(catalogOrder, context),
                ),
              );
            },
          );
  }

  Widget buildOrderItem(CatalogOrderData catalogOrder, BuildContext context) {
    final catalog = catalogOrder.catalog;
    final matrix = catalogOrder.orderMatrix;
    final styleKey = catalog.styleCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onDoubleTap: () {
                final imageUrl = catalog.fullImagePath.contains("http")
                    ? catalog.fullImagePath
                    : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageZoomScreen(imageUrls: [imageUrl]),
                  ),
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.28,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.network(
                  catalog.fullImagePath.contains("http")
                      ? catalog.fullImagePath
                      : '${AppConstants.BASE_URL}/images${catalog.fullImagePath}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catalog.styleCode,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900),
                  ),
                  Text(
                    catalog.shadeName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 6),
                  Table(
                    columnWidths: const {
                      0: FixedColumnWidth(100),
                      1: FixedColumnWidth(10),
                      2: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: [
                      _buildTableRow('Remark', catalog.remark),
                      _buildTableRow('Stk Type',
                          catalog.upcoming_Stk == '1' ? 'Upcoming' : 'Ready'),
                      _buildTableRow('Stock Qty',
                          _calculateStockQty(catalogOrder).toString(),
                          valueColor: Colors.green[700]),
                      _buildTableRow('Order Qty',
                          _calculateOrderQty(catalogOrder).toString(),
                          valueColor: Colors.orange[800]),
                      _buildTableRow('Order Amount',
                          _calculateOrderAmount(catalogOrder).toStringAsFixed(2),
                          valueColor: Colors.purple[800]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Divider(height: 1, color: Colors.grey.shade300),
              Row(
                children: [
                  _buildHeaderCell("Size", 2),
                  _buildHeaderCell("Qty", 2),
                  _buildHeaderCell("MRP", 1),
                  _buildHeaderCell("WSP", 1),
                  _buildHeaderCell("Stock", 1),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              for (var size in matrix.sizes) ...[
                _buildMatrixRow(catalogOrder, size),
                Divider(height: 1, color: Colors.grey.shade300),
              ],
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, {Color? valueColor}) {
    return TableRow(children: [
      Align(
          alignment: Alignment.topLeft,
          child: Text(label, style: const TextStyle(fontSize: 14))),
      const Align(
          alignment: Alignment.center,
          child: Text(":", style: TextStyle(fontSize: 14))),
      Align(
        alignment: Alignment.topLeft,
        child: Text(
          value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black),
        ),
      ),
    ]);
  }

  Widget _buildHeaderCell(String text, int flex) => Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.red.shade900),
          ),
        ),
      );

  Widget _buildMatrixRow(CatalogOrderData catalogOrder, String size) {
    final matrix = catalogOrder.orderMatrix;
    final styleKey = catalogOrder.catalog.styleCode;
    final sizeIndex = matrix.sizes.indexOf(size);

    String mrp = '0';
    String wsp = '0';
    String qty = '0';
    String stock = '0';

    if (sizeIndex != -1) {
      final matrixData =
          matrix.matrix.firstWhere((row) => row.length > sizeIndex)[sizeIndex].split(',');
      mrp = matrixData.isNotEmpty ? matrixData[0] : '0';
      wsp = matrixData.length > 1 ? matrixData[1] : '0';
      qty = matrixData.length > 2 ? matrixData[2] : '0';
      stock = matrixData.length > 3 ? matrixData[3] : '0';
    }

    controllers[styleKey] ??= {};
    controllers[styleKey]![size] ??= TextEditingController(text: qty);

    return Row(
      children: [
        _buildCell(size, 2),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Center(
              child: SizedBox(
                width: 40,
                child: TextField(
                  controller: controllers[styleKey]![size],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) {
                    final newQty = int.tryParse(val) ?? 0;
                    final row = matrix.matrix.firstWhere((row) => row.length > sizeIndex);
                    final matrixData = row[sizeIndex].split(',');
                    if (matrixData.length >= 3) {
                      matrixData[2] = newQty.toString();
                      row[sizeIndex] = matrixData.join(',');
                    }
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
        _buildCell(mrp, 1),
        _buildCell(wsp, 1),
        _buildCell(stock, 1),
      ],
    );
  }

  Widget _buildCell(String text, int flex) => Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );

  int _calculateOrderQty(CatalogOrderData data) {
    return data.orderMatrix.matrix
        .expand((i) => i)
        .map((e) => int.tryParse(e.split(',')[2]) ?? 0)
        .fold(0, (a, b) => a + b);
  }

  int _calculateStockQty(CatalogOrderData data) {
    return data.orderMatrix.matrix
        .expand((i) => i)
        .map((e) => int.tryParse(e.split(',')[3]) ?? 0)
        .fold(0, (a, b) => a + b);
  }

  double _calculateOrderAmount(CatalogOrderData data) {
    return data.orderMatrix.matrix
        .expand((i) => i)
        .map((e) {
          final parts = e.split(',');
          final mrp = double.tryParse(parts[0]) ?? 0;
          final qty = double.tryParse(parts[2]) ?? 0;
          return mrp * qty;
        })
        .fold(0, (a, b) => a + b);
  }
}
