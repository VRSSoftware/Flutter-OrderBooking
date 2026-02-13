import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Added for Date formatting

class SalesOrderInvoicePage extends StatefulWidget {
  const SalesOrderInvoicePage({super.key});

  @override
  State<SalesOrderInvoicePage> createState() => _SalesOrderInvoicePageState();
}

class _SalesOrderInvoicePageState extends State<SalesOrderInvoicePage> {
  late Future<List<dynamic>> futureData;
  final String todayDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<dynamic>> fetchData() async {
    final res = await http.get(Uri.parse(
        "http://192.168.0.11:8080/api/v1/orderRegister/getSalesOrderData/131"));

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      return body["tableData"]["items"];
    }
    throw Exception("API failed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SALES ORDER", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: futureData,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!;
          int overallTotalQty = 0;
          for (var item in items) {
            for (var style in item["styles"]) {
              for (var shade in style["shades"]) {
                for (var size in shade["size_data"]) {
                  overallTotalQty += (size["Qty"] as num).toInt();
                }
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(),
                const SizedBox(height: 20),
                ...items.map((e) => buildItem(e)).toList(),
                const SizedBox(height: 10),
                buildGrandSummary(overallTotalQty),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= IMPROVED HEADER =================

  Widget buildHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blueGrey.shade800,
            child: const Text("ORDER DETAILS",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Party: 3D FASHION COMPANY",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Order No: SO-131", style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                const Text("Address: RH4, Shree Shidhiganesh CHS, Sector-2, Airoli, Navi Mumbai"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text("GST No: 27AF23875065428")),
                    Expanded(child: Text("Today's Date: $todayDate", textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Mobile: 9869723951"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= IMPROVED ITEM TABLE =================

  Widget buildItem(dynamic item) {
    final List sizes = item["sizes"];
    final List styles = item["styles"];
    int itemTotalQty = 0;
    List<TableRow> rows = [];

    // Table Header with Item Name
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.blueGrey.shade100),
        children: [
          cell(item["item_name"].toString().toUpperCase(), bold: true, align: Alignment.centerLeft, flex: 2),
          ...List.generate(sizes.length + 3, (_) => const SizedBox()),
        ],
      ),
    );

    // Column Headers
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.blueGrey.shade50),
        children: [
          cell("Style", bold: true),
          cell("Shade", bold: true),
          ...sizes.map((s) => cell(s, bold: true)).toList(),
          cell("WSP", bold: true),
          cell("Total", bold: true),
        ],
      ),
    );

    for (var style in styles) {
      final styleCode = style["style_code"];
      List<Map<String, dynamic>> shadeRows = [];

      for (var shade in style["shades"]) {
        Map<double, Map<String, int>> rateMap = {};
        for (var s in shade["size_data"]) {
          double rate = (s["Rate"] as num).toDouble();
          rateMap.putIfAbsent(rate, () => {});
          rateMap[rate]![s["Size_Name"]] = (s["Qty"] as num).toInt();
        }
        for (var entry in rateMap.entries) {
          shadeRows.add({"shade": shade["shade_name"], "rate": entry.key, "sizes": entry.value});
        }
      }

      for (int i = 0; i < shadeRows.length; i++) {
        final row = shadeRows[i];
        int rowQty = 0;
        List<Widget> sizeCells = [];
        for (var size in sizes) {
          int q = row["sizes"][size] ?? 0;
          rowQty += q;
          sizeCells.add(cell(q == 0 ? "-" : q.toString(), color: q > 0 ? Colors.black : Colors.grey));
        }
        itemTotalQty += rowQty;

        rows.add(
          TableRow(
            children: [
              cell(i == 0 ? styleCode : "", bold: i == 0),
              cell(i == 0 || shadeRows[i - 1]["shade"] != row["shade"] ? row["shade"] : ""),
              ...sizeCells,
              cell("₹${row["rate"]}"),
              cell(rowQty.toString(), bold: true),
            ],
          ),
        );
      }
    }

    // Item Footer
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade50),
        children: [
          cell("Sub Total", bold: true),
          cell(""),
          ...sizes.map((e) => cell("")).toList(),
          cell(""),
          cell(itemTotalQty.toString(), bold: true, color: Colors.blue.shade900),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(border: Border.all(color: Colors.blueGrey.shade300, width: 0.5)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: Colors.blueGrey.shade200, width: 0.5),
          children: rows,
        ),
      ),
    );
  }

  // ================= SUMMARY TABLE =================

  Widget buildGrandSummary(int total) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: Colors.black, width: 1),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blueGrey.shade900),
          children: [
            cell("GRAND TOTAL QUANTITY", bold: true, color: Colors.white, padding: 10),
            cell(total.toString(), bold: true, color: Colors.white, padding: 10),
          ],
        ),
      ],
    );
  }

  Widget cell(String text, {bool bold = false, Color color = Colors.black, double padding = 6, Alignment align = Alignment.center, int flex = 1}) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}