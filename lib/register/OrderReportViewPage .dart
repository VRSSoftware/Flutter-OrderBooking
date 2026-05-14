import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/OrderBooking/order_booking.dart';
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
  final String orderStatus;
  final dynamic orderData;
  final bool showOnlyWithImage;
  final bool fromRegisterPage;
  final String? defaultWhatsAppMobileNo;

  const OrderReportViewPage({
    Key? key,
    required this.orderNo,
    this.orderStatus = 'Draft',
    this.orderData,
    this.showOnlyWithImage = false,
    this.fromRegisterPage = false,
    this.defaultWhatsAppMobileNo,
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
      final data = await ApiService.fetchOrderReportDataPost(widget.orderNo, widget.orderStatus);
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
        // Load style image
        String styleImageUrl = style['Style_Image'] ?? '';
        if (styleImageUrl.isNotEmpty && !imageCache.containsKey(styleImageUrl)) {
          try {
            final response = await http.get(Uri.parse(styleImageUrl));
            if (response.statusCode == 200) {
              imageCache[styleImageUrl] = pw.MemoryImage(response.bodyBytes);
            }
          } catch (e) {
            print('Error loading style image: $e');
          }
        }
        
        // Load shade images
        List shades = style['shades'] ?? [];
        for (var shade in shades) {
          String shadeImageUrl = shade['shade_Img']?.toString() ?? '';
          if (shadeImageUrl.isNotEmpty && !imageCache.containsKey(shadeImageUrl)) {
            try {
              final response = await http.get(Uri.parse(shadeImageUrl));
              if (response.statusCode == 200) {
                imageCache[shadeImageUrl] = pw.MemoryImage(response.bodyBytes);
              }
            } catch (e) {
              print('Error loading shade image: $e');
            }
          }
        }
      }
    }
  }

  pw.ImageProvider? _getLogoImage() {
    try {
      String logoBase64 = headerData['logo']?.toString() ?? '';
      if (logoBase64.isNotEmpty) {
        if (logoBase64.contains(',')) {
          logoBase64 = logoBase64.split(',').last;
        }
        Uint8List bytes = base64.decode(logoBase64);
        return pw.MemoryImage(bytes);
      }
    } catch (e) {
      print('Error decoding logo: $e');
    }
    return null;
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

  List<String> _getSizesForCategory(dynamic category) {
    const int totalSizePositions = 12;
    List<dynamic> apiSizes = category['sizes'] ?? [];
    
    List<String> availableSizes = apiSizes.map((size) => size.toString()).toList();
    availableSizes.sort((a, b) {
      int aNum = int.tryParse(a) ?? 0;
      int bNum = int.tryParse(b) ?? 0;
      return aNum.compareTo(bNum);
    });

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

    pw.ImageProvider? logoImage = _getLogoImage();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(top: 8, bottom: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue300,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(left: 8, right: 8),
                    child: pw.Image(
                      logoImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        headerData['Co_Name']?.toString() ?? "VRS Software Pvt Ltd",
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
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
                    ],
                  ),
                ),
                if (logoImage != null)
                  pw.SizedBox(width: 68),
              ],
            ),
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
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        headerData['Led_Name']?.toString() ?? '',
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
                            color: PdfColors.grey900,
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
                            color: PdfColors.grey900,
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
                        color: PdfColors.grey900,
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
                            color: PdfColors.grey900,
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
                        color: PdfColors.grey900,
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
                            color: PdfColors.grey900,
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
                        color: PdfColors.grey900,
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
                            color: PdfColors.grey900,
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
                        color: PdfColors.grey900,
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
                            color: PdfColors.grey900,
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
      List<String> categorySizes = _getSizesForCategory(category);
      List styles = category['styles'] ?? [];
      int categoryTotalQty = 0;
      int categoryStyleCount = 0;

      // Check if any shade exists in this category
      bool hasAnyShade = false;
      for (var style in styles) {
        List shades = style['shades'] ?? [];
        for (var shade in shades) {
          String shadeName = shade['shade_name']?.toString() ?? '';
          if (shadeName.isNotEmpty && shadeName != 'null') {
            hasAnyShade = true;
            break;
          }
        }
        if (hasAnyShade) break;
      }

      List<pw.TableRow> categoryRows = [];

      for (var style in styles) {
        String styleCode = style['style_code']?.toString() ?? '';
        String styleImageUrl = style['Style_Image']?.toString() ?? '';
        String styleRemark = style['Remark']?.toString() ?? '';
        List shades = style['shades'] ?? [];

        // Get style image from cache
        pw.ImageProvider? styleImage;
        if (styleImageUrl.isNotEmpty && imageCache.containsKey(styleImageUrl)) {
          styleImage = imageCache[styleImageUrl];
        }

        bool hasValidShades = false;
        for (var shade in shades) {
          String shadeName = shade['shade_name']?.toString() ?? '';
          if (shadeName.isNotEmpty && shadeName != 'null') {
            hasValidShades = true;
            break;
          }
        }

        if (!hasValidShades) {
          // Handle styles without shades
          var shade = shades.isNotEmpty ? shades[0] : {'shade_name': '', 'shade_Img': null, 'size_data': []};
          
          List sizeData = shade['size_data'] ?? [];

          Map<String, int> sizeQtyMap = {};
          double? wsp;

          for (var size in sizeData) {
            String sizeName = size['Size_Name']?.toString() ?? '';
            int qty = (size['Qty'] ?? 0).toInt();

            if (sizeName.isNotEmpty) {
              sizeQtyMap[sizeName] = (sizeQtyMap[sizeName] ?? 0) + qty;
            }

            if (wsp == null) {
              num rate = size['Rate'] ?? 0;
              wsp = rate.toDouble();
            }
          }

          int totalQty = 0;
          for (var size in categorySizes) {
            totalQty += sizeQtyMap[size] ?? 0;
          }

          categoryTotalQty += totalQty;
          grandTotalQty += totalQty;
          categoryStyleCount++;
          totalStylesCount++;

          List<pw.Widget> dataCells = [];

          // Style column
          dataCells.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    styleCode,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  if (styleRemark.isNotEmpty)
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
          );

          // Style Image column
          dataCells.add(
            pw.Container(
              width: 40,
              height: 40,
              padding: const pw.EdgeInsets.all(2),
              child: styleImage != null
                  ? pw.Image(styleImage, fit: pw.BoxFit.contain)
                  : pw.Center(
                      child: pw.Text(
                        'No Image',
                        style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                      ),
                    ),
            ),
          );

          // Size columns
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

          // WSP and Total Qty columns
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
          
        } else {
          // Handle styles with shades
          bool isFirstRowForStyle = true;
          int shadeCount = 0;

          for (var shade in shades) {
            String shadeName = shade['shade_name']?.toString() ?? '';
            if (shadeName.isEmpty || shadeName == 'null') continue;
            
            String shadeImageUrl = shade['shade_Img']?.toString() ?? '';
            List sizeData = shade['size_data'] ?? [];

            // Get shade image from cache
            pw.ImageProvider? shadeImage;
            if (shadeImageUrl.isNotEmpty && imageCache.containsKey(shadeImageUrl)) {
              shadeImage = imageCache[shadeImageUrl];
            }

            Map<String, int> sizeQtyMap = {};
            double? wsp;

            for (var size in sizeData) {
              String sizeName = size['Size_Name']?.toString() ?? '';
              int qty = (size['Qty'] ?? 0).toInt();

              if (sizeName.isNotEmpty) {
                sizeQtyMap[sizeName] = (sizeQtyMap[sizeName] ?? 0) + qty;
              }

              if (wsp == null) {
                num rate = size['Rate'] ?? 0;
                wsp = rate.toDouble();
              }
            }

            int totalQty = 0;
            for (var size in categorySizes) {
              totalQty += sizeQtyMap[size] ?? 0;
            }

            categoryTotalQty += totalQty;
            grandTotalQty += totalQty;
            shadeCount++;

            List<pw.Widget> dataCells = [];

            // Style column (only for first row of this style)
            if (isFirstRowForStyle) {
              dataCells.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        styleCode,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      if (styleRemark.isNotEmpty)
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
              );
            } else {
              dataCells.add(pw.Container());
            }

            // Shade column
            dataCells.add(
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  shadeName,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );

            // Style Image column (only for first row of this style)
            dataCells.add(
              pw.Container(
                width: 35,
                height: 35,
                padding: const pw.EdgeInsets.all(2),
                child: (isFirstRowForStyle && styleImage != null)
                    ? pw.Image(styleImage, fit: pw.BoxFit.contain)
                    : (isFirstRowForStyle)
                        ? pw.Center(
                            child: pw.Text(
                              'No Image',
                              style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                            ),
                          )
                        : pw.Container(),
              ),
            );

            // Shade Image column
            dataCells.add(
              pw.Container(
                width: 35,
                height: 35,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  color: PdfColors.grey50,
                ),
                child: shadeImage != null
                    ? pw.Center(
                        child: pw.Container(
                          width: 33,
                          height: 33,
                          child: pw.Image(shadeImage, fit: pw.BoxFit.contain),
                        ),
                      )
                    : pw.Center(
                        child: pw.Text(
                          'No Image',
                          style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                        ),
                      ),
              ),
            );

            // Size columns
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

            // WSP and Total Qty columns
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
      }

      if (categoryStyleCount > 0) {
        // Header cells
        List<pw.Widget> headerCells = [];

        if (!hasAnyShade) {
          headerCells.addAll([
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                "Style",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                "Image",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ]);
        } else {
          headerCells.addAll([
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
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                "Style Image",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(2),
              child: pw.Text(
                "Shade Image",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ]);
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

        categoryRows.insert(
          0,
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: headerCells,
          ),
        );

        int totalColumns = (hasAnyShade ? 4 : 2) + categorySizes.length + 2;
        
        List<pw.Widget> categoryTotalRowCells = [];

        if (!hasAnyShade) {
          categoryTotalRowCells.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                "Total Item: $categoryStyleCount",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
            ),
          );
          categoryTotalRowCells.add(
            pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
          );
        } else {
          categoryTotalRowCells.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                "Total Item: $categoryStyleCount",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              ),
            ),
          );
          categoryTotalRowCells.add(
            pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
          );
          categoryTotalRowCells.add(
            pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
          );
          categoryTotalRowCells.add(
            pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
          );
        }

        for (int i = (hasAnyShade ? 4 : 2); i < totalColumns - 1; i++) {
          categoryTotalRowCells.add(
            pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
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

        // Set column widths
        Map<int, pw.TableColumnWidth> columnWidths = {};

        if (!hasAnyShade) {
          columnWidths[0] = const pw.FixedColumnWidth(80);
          columnWidths[1] = const pw.FixedColumnWidth(45);
          for (int i = 0; i < categorySizes.length; i++) {
            columnWidths[2 + i] = const pw.FixedColumnWidth(28);
          }
          columnWidths[2 + categorySizes.length] = const pw.FixedColumnWidth(40);
          columnWidths[3 + categorySizes.length] = const pw.FixedColumnWidth(65);
        } else {
          columnWidths[0] = const pw.FixedColumnWidth(55);
          columnWidths[1] = const pw.FixedColumnWidth(55);
          columnWidths[2] = const pw.FixedColumnWidth(45);
          columnWidths[3] = const pw.FixedColumnWidth(45);
          for (int i = 0; i < categorySizes.length; i++) {
            columnWidths[4 + i] = const pw.FixedColumnWidth(28);
          }
          columnWidths[4 + categorySizes.length] = const pw.FixedColumnWidth(40);
          columnWidths[5 + categorySizes.length] = const pw.FixedColumnWidth(65);
        }

        tables.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                categoryName,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: columnWidths,
                  children: categoryRows,
                ),
              ),
              pw.SizedBox(height: 15),
            ],
          ),
        );
      }
    }

    // Determine if any shade exists globally for grand total row
    bool hasAnyShadeGlobal = false;
    for (var category in items) {
      List styles = category['styles'] ?? [];
      for (var style in styles) {
        List shades = style['shades'] ?? [];
        for (var shade in shades) {
          String shadeName = shade['shade_name']?.toString() ?? '';
          if (shadeName.isNotEmpty && shadeName != 'null') {
            hasAnyShadeGlobal = true;
            break;
          }
        }
        if (hasAnyShadeGlobal) break;
      }
      if (hasAnyShadeGlobal) break;
    }

    int totalColumns = 0;
    if (items.isNotEmpty) {
      var lastCategory = items.last;
      List<String> lastCategorySizes = _getSizesForCategory(lastCategory);
      totalColumns = (hasAnyShadeGlobal ? 4 : 2) + lastCategorySizes.length + 2;
    }

    List<pw.Widget> grandTotalRowCells = [];

    if (!hasAnyShadeGlobal) {
      grandTotalRowCells.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            "Total Item: $totalStylesCount",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
      );
      grandTotalRowCells.add(
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
      );
    } else {
      grandTotalRowCells.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            "Total Item: $totalStylesCount",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
      );
      grandTotalRowCells.add(
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
      );
      grandTotalRowCells.add(
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
      );
      grandTotalRowCells.add(
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
      );
    }

    for (int i = (hasAnyShadeGlobal ? 4 : 2); i < totalColumns - 1; i++) {
      grandTotalRowCells.add(
        pw.Container(padding: const pw.EdgeInsets.all(4), child: pw.Container()),
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
    String ledgerName = headerData['Ledger_Name']?.toString() ?? '';
    String createdByText = ledgerName.isNotEmpty 
        ? "Created By: $ledgerName" 
        : "Created By: ";
    
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(createdByText, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            "${headerData['Co_Name']?.toString() ?? ''}",
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

  Future<void> _shareViaWhatsApp() async {
    try {
      String? defaultMobileNo = widget.defaultWhatsAppMobileNo ?? 
                                widget.orderData?.whatsAppMobileNo ?? 
                                headerData['WhatsAppMobileNo']?.toString();
      
      final result = await _showMobileNumberDialog(defaultMobileNo: defaultMobileNo);
      if (result == null) return;
      
      String mobileNo = result['mobileNo'] ?? '';
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Preparing order report for WhatsApp...',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      String whatsappType = AppConstants.whatsappType ?? '1';
      
      if (whatsappType == "1") {
        await _shareViaWhatsAppNode(mobileNo);
      } else if (whatsappType == "2") {
        await _shareViaWhatsAppBackend(mobileNo);
      } else {
        await _shareViaWhatsAppNode(mobileNo);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      print('Error sending via WhatsApp: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareViaWhatsAppNode(String mobileNo) async {
    try {
      final pdfBytes = await _generatePDF();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Order_${widget.orderNo}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      final pdfBytesData = await file.readAsBytes();
      String fileBase64 = base64Encode(pdfBytesData);
      
      String caption = _prepareOrderReportCaption();
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Sending via WhatsApp...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      String whatsappKey = AppConstants.whatsappKey ?? '';
      if (whatsappKey.isEmpty) {
        throw Exception('WhatsApp API key not configured');
      }
      
      final response = await http.post(
        Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
        body: {
          'data': fileBase64,
          'filename': 'Order_${widget.orderNo}.pdf',
          'key': whatsappKey,
          'number': '91$mobileNo',
          'caption': caption,
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200 && mounted) {
        try {
          final responseData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['status'] == 'success' 
                  ? '✓ Order report sent successfully to $mobileNo'
                  : 'Failed: ${responseData['message'] ?? 'Unknown error'}',
              ),
              backgroundColor: responseData['status'] == 'success' 
                ? Colors.green 
                : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Order report sent successfully to $mobileNo'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send via WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      await file.delete();
      
    } catch (e) {
      print('Error sending via Node API: $e');
      rethrow;
    }
  }

  Future<void> _shareViaWhatsAppBackend(String mobileNo) async {
    try {
      final pdfBytes = await _generatePDF();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Order_${widget.orderNo}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      final uri = Uri.parse('${AppConstants.BASE_URL}/pdf/send-pdf');
      var request = http.MultipartRequest('POST', uri);
      
      request.fields['mobile_no'] = mobileNo;
      request.fields['order_no'] = widget.orderNo;
      request.fields['party_name'] = headerData['Led_Name']?.toString() ?? '';
      request.fields['order_date'] = _formatDate(headerData['Doc_Dt']?.toString());
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: 'Order_${widget.orderNo}.pdf',
        ),
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Sending order report...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 && mounted) {
        try {
          final responseBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseBody['message'] ?? '✓ Order report sent successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Order report sent successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      await file.delete();
      
    } catch (e) {
      print('Error sending PDF via Backend API: $e');
      rethrow;
    }
  }

  Future<Map<String, String>?> _showMobileNumberDialog({String? defaultMobileNo}) {
    TextEditingController mobileController = TextEditingController(text: defaultMobileNo ?? '');
    
    return showDialog<Map<String, String>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Enter Mobile Number",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Order report will be sent as PDF via WhatsApp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final mobileNo = mobileController.text.trim();
                if (mobileNo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter mobile number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (mobileNo.length != 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid 10-digit mobile number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(mobileNo)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter numbers only'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, {'mobileNo': mobileNo});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Send via WhatsApp"),
            ),
          ],
        );
      },
    );
  }

  String _prepareOrderReportCaption() {
    String orderNo = widget.orderNo;
    String orderDate = _formatDate(headerData['Doc_Dt']?.toString());
    String partyName = headerData['Led_Name']?.toString() ?? '';
    int totalItems = items.length;
    
    int totalQty = 0;
    for (var category in items) {
      List styles = category['styles'] ?? [];
      for (var style in styles) {
        List shades = style['shades'] ?? [];
        for (var shade in shades) {
          List sizeData = shade['size_data'] ?? [];
          for (var size in sizeData) {
            dynamic qtyValue = size['Qty'] ?? 0;
            if (qtyValue is num) {
              totalQty += qtyValue.toInt();
            } else if (qtyValue is int) {
              totalQty += qtyValue;
            } else {
              totalQty += int.tryParse(qtyValue.toString()) ?? 0;
            }
          }
        }
      }
    }
    
    return '''
*📋 VRS ORDER REPORT*
━━━━━━━━━━━━━━━━━━━━

🏢 *Company:* ${headerData['Co_Name']?.toString() ?? 'VRS Software'}
📦 *Order No:* $orderNo
📅 *Order Date:* $orderDate
👤 *Party:* $partyName
📊 *Total Items:* $totalItems
🔢 *Total Quantity:* $totalQty

━━━━━━━━━━━━━━━━━━━━
*Generated from VRS ERP App*
  ''';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: Text(
            "Order Report",
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
            onPressed: _handleBackNavigation,
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 20),
                onPressed: isLoading ? null : _sharePDF,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                onPressed: isLoading ? null : _shareViaWhatsApp,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
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
      ),
    );
  }

  void _handleBackNavigation() {
    if (widget.fromRegisterPage) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OrderBookingScreen()),
      );
    }
  }
}