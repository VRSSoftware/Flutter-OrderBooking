import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class OrderReportViewPage extends StatefulWidget {
  final String orderNo;
  final dynamic orderData;
  final bool showOnlyWithImage; // Controls whether to show image column

  const OrderReportViewPage({
    Key? key, 
    required this.orderNo, 
    this.orderData,
    this.showOnlyWithImage = false, // Default to false
  }) : super(key: key);

  @override
  _OrderReportViewPageState createState() => _OrderReportViewPageState();
}

class _OrderReportViewPageState extends State<OrderReportViewPage> {
  bool isLoading = true;
  bool pdfError = false;
  Map<String, dynamic>? reportData;
  Map<String, dynamic> headerData = {};
  List<dynamic> items = [];
  Map<String, pw.ImageProvider?> imageCache = {};

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    try {
      final data = await ApiService.fetchOrderReportData(widget.orderNo);
      setState(() {
        reportData = data;
        headerData = data['headerData'] ?? {};
        items = data['tableData']?['items'] ?? [];
        isLoading = false;
      });
      await _loadImages();
    } catch (e) {
      setState(() {
        isLoading = false;
        pdfError = true;
      });
    }
  }

  Future<void> _loadImages() async {
    for (var item in items) {
      List styles = item['styles'] ?? [];
      for (var style in styles) {
        String imageUrl = style['Style_Image'] ?? '';
        if (imageUrl.isNotEmpty) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              imageCache[imageUrl] = pw.MemoryImage(response.bodyBytes);
            }
          } catch (e) {
            print('Error loading image: $e');
          }
        }
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _sharePDF() async {
    try {
      final pdfBytes = await _generatePDF();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Order_${widget.orderNo}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Order Report');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing PDF: $e')));
    }
  }

// UPDATED METHOD: Now returns 12-size array with sizes starting from 0th index
List<String> _getSizesForCategory(dynamic category) {
  const int totalSizePositions = 12;
  
  // Get the available sizes from the API
  List<dynamic> apiSizes = category['sizes'] ?? [];
  
  // Convert to strings and sort
  List<String> availableSizes = apiSizes.map((size) => size.toString()).toList();
  availableSizes.sort((a, b) {
    int aNum = int.tryParse(a) ?? 0;
    int bNum = int.tryParse(b) ?? 0;
    return aNum.compareTo(bNum);
  });
  
  // Create a new list with 12 elements
  // Fill first N positions with available sizes, rest with "-"
  return List.generate(totalSizePositions, (index) {
    if (index < availableSizes.length) {
      return availableSizes[index];
    } else {
      return "-";
    }
  });
}
  // ALTERNATIVE METHOD: If you want to just take first 12 sizes and fill rest with hyphens
  List<String> _getSizesWithFill(dynamic category) {
    const int totalSizePositions = 12;
    
    List<dynamic> apiSizes = category['sizes'] ?? [];
    List<String> availableSizes = apiSizes.map((size) => size.toString()).toList();
    
    // Create a new list with 12 elements
    return List.generate(totalSizePositions, (index) {
      if (index < availableSizes.length) {
        return availableSizes[index];
      } else {
        return "-";
      }
    });
  }

  Future<Uint8List> _generatePDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return [
              _buildPDFHeader(),
              pw.SizedBox(height: 15),
              _buildPDFItemsTable(),
              pw.SizedBox(height: 15),
              _buildPDFFooter(),
            ];
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      return Uint8List(0);
    }
  }

  pw.Widget _buildPDFHeader() {
    String address = headerData['RegdAdd']?.toString() ?? "";
    String addressLine1 = "";
    String addressLine2 = "";

    if (address.length > 40) {
      int splitIndex = address.indexOf(',', 30);
      if (splitIndex == -1) {
        splitIndex = address.lastIndexOf(' ', 40);
      }
      if (splitIndex > 0 && splitIndex < address.length - 1) {
        addressLine1 = address.substring(0, splitIndex + 1);
        addressLine2 = address.substring(splitIndex + 1).trim();
      } else {
        addressLine1 = address.substring(0, 40);
        addressLine2 = address.substring(40);
      }
    } else {
      addressLine1 = address;
    }

    String partyAddress = headerData['OAddr']?.toString() ?? "";
    String partyAddressLine1 = "";
    String partyAddressLine2 = "";

    if (partyAddress.length > 30) {
      int splitIndex = partyAddress.indexOf(',', 25);
      if (splitIndex == -1) {
        splitIndex = partyAddress.lastIndexOf(' ', 30);
      }
      if (splitIndex > 0 && splitIndex < partyAddress.length - 1) {
        partyAddressLine1 = partyAddress.substring(0, splitIndex + 1);
        partyAddressLine2 = partyAddress.substring(splitIndex + 1).trim();
      } else {
        partyAddressLine1 = partyAddress.substring(0, 30);
        partyAddressLine2 = partyAddress.substring(30);
      }
    } else {
      partyAddressLine1 = partyAddress;
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            headerData['Co_Name']?.toString() ?? "VRS Software Pvt Ltd",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            headerData['RegdAdd']?.toString() ?? "",
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            "Mobile: ${headerData['TelNo']?.toString() ?? ''}   Email: ${headerData['Email']?.toString() ?? ''}",
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.Divider(height: 15, thickness: 0.2),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Party : ",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        headerData['Party_Name']?.toString() ?? '',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(flex: 1, child: pw.Container()),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Address : ",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (partyAddressLine1.isNotEmpty)
                                pw.Text(
                                  partyAddressLine1,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                              if (partyAddressLine2.isNotEmpty)
                                pw.Text(
                                  partyAddressLine2,
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  softWrap: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "Order No : ",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          headerData['Doc_No']?.toString() ?? '',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  children: [
                    pw.Text(
                      "GST No : ",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      headerData['GSTNo']?.toString() ?? '',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "Date : ",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          _formatDate(headerData['Doc_Dt']?.toString()),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  children: [
                    pw.Text(
                      "Mobile : ",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      headerData['Mobile']?.toString() ?? '',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "Salesman : ",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          headerData['SalesPerson_Name']?.toString() ?? '',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  children: [
                    pw.Text(
                      "Del.Date : ",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      _formatDate(headerData['DlvDate']?.toString()),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "Transport : ",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          headerData['Transporter_Name']?.toString() ?? '',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Remark : ",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        headerData['Remark']?.toString() ?? '',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          "Broker : ",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          headerData['Broker_Name']?.toString() ?? '',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFItemsTable() {
    if (items.isEmpty) {
      return pw.Center(child: pw.Text("No Items Found"));
    }

    int grandTotalQty = 0;
    int totalStylesCount = 0;
    List<pw.Widget> tables = [];

    for (var category in items) {
      String categoryName = category['item_name']?.toString() ?? '';
      List<String> categorySizes = _getSizesForCategory(category); // Now returns 12-size array
      List styles = category['styles'] ?? [];
      int categoryTotalQty = 0;
      int categoryStyleCount = 0;
      
      List<pw.TableRow> categoryRows = [];

      for (var style in styles) {
        String styleCode = style['style_code']?.toString() ?? '';
        String imageUrl = style['Style_Image']?.toString() ?? '';
        String styleRemark = style['Remark']?.toString() ?? '';
        List shades = style['shades'] ?? [];
        
        bool isFirstRowForStyle = true;
        int shadeCount = 0;

        for (var shade in shades) {
          String shadeName = shade['shade_name']?.toString() ?? '';
          List sizeData = shade['size_data'] ?? [];

          Map<String, int> sizeQtyMap = {};
          int totalQty = 0;
          double? wsp;

          for (var size in sizeData) {
            String sizeName = size['Size_Name']?.toString() ?? '';
            num qty = size['Qty'] ?? 0;
            int intQty = qty.toInt();
            totalQty += intQty;
            if (sizeName.isNotEmpty) {
              sizeQtyMap[sizeName] = intQty;
            }
            if (wsp == null) {
              num rate = size['Rate'] ?? 0;
              wsp = rate.toDouble();
            }
          }

          categoryTotalQty += totalQty;
          grandTotalQty += totalQty;
          shadeCount++;

          List<pw.Widget> dataCells = [
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (isFirstRowForStyle)
                    pw.Text(
                      styleCode,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  if (isFirstRowForStyle && styleRemark.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'Remark: $styleRemark',
                        style: pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                shadeName,
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];

          // Add Image column only if showOnlyWithImage is true
          if (widget.showOnlyWithImage) {
            dataCells.add(
              pw.Container(
                width: 35,
                height: 35,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  color: PdfColors.grey50,
                ),
                child: isFirstRowForStyle
                    ? (imageUrl.isNotEmpty && imageCache.containsKey(imageUrl)
                        ? pw.Center(
                            child: pw.Container(
                              width: 33,
                              height: 33,
                              child: pw.Image(
                                imageCache[imageUrl]!,
                                fit: pw.BoxFit.contain,
                              ),
                            ),
                          )
                        : pw.Center(
                            child: pw.Container(
                              width: 33,
                              height: 33,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.circular(2),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  'No Image',
                                  style: pw.TextStyle(
                                    fontSize: 6,
                                    color: PdfColors.grey700,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ),
                          ))
                    : pw.Container(),
              ),
            );
          }

          // Now categorySizes always has 12 elements
          for (var size in categorySizes) {
            dataCells.add(
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  sizeQtyMap[size]?.toString() ?? '-',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
          }

          dataCells.addAll([
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                wsp?.toStringAsFixed(0) ?? "0",
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                totalQty.toString(),
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ]);

          categoryRows.add(pw.TableRow(children: dataCells));
          isFirstRowForStyle = false;
        }

        if (shadeCount > 0) {
          categoryStyleCount++;
          totalStylesCount++;
        }
      }

      if (categoryStyleCount > 0) {
        List<pw.Widget> headerCells = [
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "Style",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "Shade",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ];

        // Add Image column header only if showOnlyWithImage is true
        if (widget.showOnlyWithImage) {
          headerCells.add(
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                "Image",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
          );
        }

        for (var size in categorySizes) {
          headerCells.add(
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                size,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
          );
        }

        headerCells.addAll([
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "WSP",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "TotQty",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ]);

        categoryRows.insert(0, pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headerCells,
        ));

        int totalColumns = 2 + (widget.showOnlyWithImage ? 1 : 0) + categorySizes.length + 2;
        List<pw.Widget> categoryTotalRowCells = [
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "Total Item: $categoryStyleCount",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Container(),
          ),
        ];

        if (widget.showOnlyWithImage) {
          categoryTotalRowCells.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Container(),
            ),
          );
        }

        for (int i = 2 + (widget.showOnlyWithImage ? 1 : 0); i < totalColumns - 1; i++) {
          categoryTotalRowCells.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Container(),
            ),
          );
        }

        categoryTotalRowCells.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              "$categoryName Total: $categoryTotalQty",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );

        categoryRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: categoryTotalRowCells,
          ),
        );

        tables.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                categoryName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Table(border: pw.TableBorder.all(width: 0.5), children: categoryRows),
              ),
              pw.SizedBox(height: 15),
            ],
          ),
        );
      }
    }

    int totalColumns = 0;
    if (items.isNotEmpty) {
      var lastCategory = items.last;
      List<String> lastCategorySizes = _getSizesForCategory(lastCategory);
      totalColumns = 2 + (widget.showOnlyWithImage ? 1 : 0) + lastCategorySizes.length + 2;
    }

    List<pw.Widget> grandTotalRowCells = [
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          "Total Item: $totalStylesCount",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Container(),
      ),
    ];

    if (widget.showOnlyWithImage) {
      grandTotalRowCells.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Container(),
        ),
      );
    }

    for (int i = 2 + (widget.showOnlyWithImage ? 1 : 0); i < totalColumns - 1; i++) {
      grandTotalRowCells.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Container(),
        ),
      );
    }

    grandTotalRowCells.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          "Grand Total: $grandTotalQty",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );

    tables.add(
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey400),
              children: grandTotalRowCells,
            ),
          ],
        ),
      ),
    );

    return pw.Column(children: tables);
  }

  pw.Widget _buildPDFFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("Created By: Admin", style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            "For ${headerData['Co_Name']?.toString() ?? ''}",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Print Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}",
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text("Order Form", style: const TextStyle(color: Colors.white)),
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: isLoading ? null : _sharePDF,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfError
          ? const Center(child: Text("Error loading PDF"))
          : PdfPreview(
              build: (format) => _generatePDF(),
              allowSharing: false,
              allowPrinting: false,
              pdfFileName: 'Order_${widget.orderNo}.pdf',
              initialPageFormat: PdfPageFormat.a4,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              onError: (context, error) {
                return Center(child: Text("PDF Error: $error"));
              },
            ),
    );
  }
}