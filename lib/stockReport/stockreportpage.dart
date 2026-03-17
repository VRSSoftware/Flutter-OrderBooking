import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/stockReportModel.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/stockReport/stockfilter.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';

class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});

  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  String? selectedCategoryKey;
  String? selectedCategoryName;
  String? selectedItem;
  List<Item> selectedItems = [];

  List<Category> categories = [];
  List<Item> items = [];
  List<StockReportItem> stockReportItems = [];
  bool isLoadingCategories = true;
  bool isLoadingItems = true;
  bool isLoadingStockReport = false;
  bool hasSearched = false;

  // Filter-related state variables
  List<Style> styles = [];
  List<Shade> shades = [];
  List<Sizes> sizes = [];
  List<Brand> brands = [];
  List<Style> selectedStyles = [];
  List<Shade> selectedShades = [];
  List<Sizes> selectedSizes = [];
  List<Brand> selectedBrands = [];
  String fromMRP = '';
  String toMRP = '';
  String coBr = '';
  bool withImage = false;

  final Item selectAllItem = Item(itemName: "All Items", itemKey: "ALL");

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAllItems();
    _fetchBrands();
  }

  Future<void> _downloadStockReport() async {
    if (selectedCategoryKey == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select category ')));
      return;
    }

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
                LoadingAnimationWidget.waveDots(
                  color: AppColors.primaryColor,
                  size: 50,
                ),
                const SizedBox(height: 20),
                Text(
                  'Fetching stock data...',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      String itemKeys = selectedItems
          .map((e) => e.itemKey)
          .where((e) => e != null && e.isNotEmpty)
          .join(',');

      final fetchedStockReport = await ApiService.fetchStockReport(
        itemSubGrpKey: selectedCategoryKey!,
        itemKey: itemKeys,
        userId: 'admin',
        fcYrId: '24',
        cobr: '01',
        brandKey:
            selectedBrands.isNotEmpty
                ? selectedBrands.map((b) => b.brandKey).join(',')
                : null,
        styleKey:
            selectedStyles.isNotEmpty
                ? selectedStyles.map((s) => s.styleKey).join(',')
                : null,
        shadeKey:
            selectedShades.isNotEmpty
                ? selectedShades.map((s) => s.shadeKey).join(',')
                : null,
        sizeKey:
            selectedSizes.isNotEmpty
                ? selectedSizes.map((s) => s.itemSizeKey).join(',')
                : null,
        fromMRP: fromMRP.isNotEmpty ? double.tryParse(fromMRP) : null,
        toMRP: toMRP.isNotEmpty ? double.tryParse(toMRP) : null,
      );

      if (context.mounted) {
        Navigator.pop(context);
      }

      await _generateAndOpenPDF(fetchedStockReport);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching stock data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.MemoryImage?> _loadPdfImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {}
    return null;
  }

  Map<String, Map<String, List<StockReportItem>>>
  _groupItemsByItemAndStyleFromList(List<StockReportItem> data) {
    Map<String, Map<String, List<StockReportItem>>> groupedItems = {};

    for (var item in data) {
      final itemName = item.itemName ?? 'Unknown Item';
      final styleCode = item.styleCode ?? 'Unknown';

      if (!groupedItems.containsKey(itemName)) {
        groupedItems[itemName] = {};
      }

      if (!groupedItems[itemName]!.containsKey(styleCode)) {
        groupedItems[itemName]![styleCode] = [];
      }

      groupedItems[itemName]![styleCode]!.add(item);
    }

    return groupedItems;
  }

  String _getImageUrl(StockReportItem item) {
    if (UserSession.onlineImage == '0') {
      final imageName =
          item.fullImagePath?.split('/').last.split('?').first ?? '';
      if (imageName.isEmpty) {
        return '${AppConstants.BASE_URL}/images/NoImage.jpg';
      }
      return '${AppConstants.BASE_URL}/images/$imageName';
    } else if (UserSession.onlineImage == '1') {
      return item.fullImagePath ??
          '${AppConstants.BASE_URL}/images/NoImage.jpg';
    }
    return '${AppConstants.BASE_URL}/images/NoImage.jpg';
  }

  Future<void> _generateAndOpenPDF(List<StockReportItem> stockData) async {
    final pdf = pw.Document();

    // First, group items the same way as bottom sheet
    final groupedByItemAndStyle = _groupItemsByItemAndStyleFromList(stockData);

    List<pw.Widget> content = [];
    int grandTotal = 0;

    for (var itemEntry in groupedByItemAndStyle.entries) {
      String uniqueItemKey = itemEntry.key;
      Map<String, List<StockReportItem>> styleGroups = itemEntry.value;

      // Extract actual item name
      String itemName = uniqueItemKey.split('|')[0];
      int itemTotal = 0;

      for (var styleEntry in styleGroups.entries) {
        String styleCode = styleEntry.key;
        List<StockReportItem> items = styleEntry.value;

        // Collect all sizes for this style
        List<String> allSizes = [];
        for (var item in items) {
          if (item.details != null) {
            for (var pair in item.details!.split(',')) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                String size = parts[0].trim();
                if (!allSizes.contains(size)) {
                  allSizes.add(size);
                }
              }
            }
          }
        }

        // Sort sizes numerically
        allSizes.sort((a, b) {
          int? aNum = int.tryParse(a);
          int? bNum = int.tryParse(b);
          if (aNum != null && bNum != null) {
            return aNum.compareTo(bNum);
          }
          return a.compareTo(b);
        });

        // Build shade data for this style
        Map<String, Map<String, int>> shadeData = {};
        Map<String, int> sizeTotals = {};

        for (var size in allSizes) {
          sizeTotals[size] = 0;
        }

        for (var item in items) {
          String shade = item.shadeName ?? "Unknown";
          shadeData.putIfAbsent(shade, () => {});

          if (item.details != null) {
            for (var pair in item.details!.split(',')) {
              var parts = pair.split(':');
              if (parts.length == 2) {
                String size = parts[0].trim();
                int qty = int.tryParse(parts[1]) ?? 0;
                shadeData[shade]![size] = qty;
                sizeTotals[size] = (sizeTotals[size] ?? 0) + qty;
              }
            }
          }
        }

        // Calculate style total
        int styleTotal = items.fold(0, (sum, item) => sum + (item.total ?? 0));
        itemTotal += styleTotal;

        // Build PDF table for this style
        List<pw.TableRow> rows = [];

        // Header
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              _cell("Shade", 70),
              if (withImage) _cell("Img", 35),
              ...allSizes.map((s) => _cell(s, 40)),
              _cell("Total", 50),
            ],
          ),
        );

        // Data rows
        for (var shadeEntry in shadeData.entries) {
          String shade = shadeEntry.key;
          Map<String, int> sizeMap = shadeEntry.value;
          int shadeTotal = sizeMap.values.fold(0, (a, b) => a + b);

          pw.MemoryImage? image;
          if (withImage) {
            final url = _getImageUrl(items.first);
            image = await _loadPdfImage(url);
          }

          rows.add(
            pw.TableRow(
              children: [
                _cell(shade, 70),
                if (withImage)
                  pw.Container(
                    width: 25,
                    height: 25,
                    alignment: pw.Alignment.center,
                    child:
                        image != null
                            ? pw.Image(
                              image,
                              width: 16,
                              height: 16,
                              fit: pw.BoxFit.contain,
                            )
                            : pw.SizedBox(),
                  ),
                ...allSizes.map((size) {
                  int qty = sizeMap[size] ?? 0;
                  return _cell(qty.toString(), 40);
                }),
                _cell(shadeTotal.toString(), 50),
              ],
            ),
          );
        }

        // Total row
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cell("Total", 70),
              if (withImage) _cell("", 35),
              ...allSizes.map((s) => _cell(sizeTotals[s].toString(), 40)),
              _cell(styleTotal.toString(), 50),
            ],
          ),
        );

        // Add style section to PDF
        content.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Style header
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.grey100,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          "Style: $styleCode",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Text(
                        "Brand: ${items.first.brandName ?? ''}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: rows,
                ),
                pw.SizedBox(height: 4),
              ],
            ),
          ),
        );
      }

      grandTotal += itemTotal;

      // Add item total after all styles for this item
      content.add(
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(right: 8, bottom: 12),
          child: pw.Text(
            "$itemName Total: $itemTotal",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ),
      );
    }

    // Add grand total
    content.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 16),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(),
          color: PdfColors.grey100,
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "GRAND TOTAL",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.Text(
              grandTotal.toString(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "VRS SOFTWARE",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Date: ${DateTime.now().toString().substring(0, 10)}",
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Text(
                  "Item Wise Stock Report",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Category: ${selectedCategoryName ?? ''}",
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(),
              ],
            );
          }
          return pw.SizedBox(height: 10);
        },
        build: (context) => content,
      ),
    );

    final bytes = await pdf.save();
    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/stock_report.pdf");
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  pw.Widget _cell(String text, double width) {
    return pw.Container(
      width: width,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (selectedStyles.isNotEmpty) count++;
    if (selectedShades.isNotEmpty) count++;
    if (selectedSizes.isNotEmpty) count++;
    if (selectedBrands.isNotEmpty) count++;
    if (fromMRP.isNotEmpty) count++;
    if (toMRP.isNotEmpty) count++;
    if (withImage) count++;
    return count;
  }

  Future<void> _fetchStockReport() async {
    setState(() {
      hasSearched = true;
    });

    if (selectedCategoryKey == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select category')));
      return;
    }

    setState(() {
      isLoadingStockReport = true;
      stockReportItems = [];
    });

    try {
      String itemKeys = selectedItems
          .map((e) => e.itemKey)
          .where((e) => e != null && e.isNotEmpty)
          .join(',');

      final stockReport = await ApiService.fetchStockReport(
        itemSubGrpKey: selectedCategoryKey!,
        itemKey: itemKeys,
        userId: 'admin',
        fcYrId: '24',
        cobr: '01',
        brandKey:
            selectedBrands.isNotEmpty
                ? selectedBrands.map((b) => b.brandKey).join(',')
                : null,
        styleKey:
            selectedStyles.isNotEmpty
                ? selectedStyles.map((s) => s.styleKey).join(',')
                : null,
        shadeKey:
            selectedShades.isNotEmpty
                ? selectedShades.map((s) => s.shadeKey).join(',')
                : null,
        sizeKey:
            selectedSizes.isNotEmpty
                ? selectedSizes.map((s) => s.itemSizeKey).join(',')
                : null,
        fromMRP: fromMRP.isNotEmpty ? double.tryParse(fromMRP) : null,
        toMRP: toMRP.isNotEmpty ? double.tryParse(toMRP) : null,
      );

      setState(() {
        stockReportItems = stockReport;
        isLoadingStockReport = false;
      });

      // Show bottom sheet with results
      if (stockReport.isNotEmpty && mounted) {
        _showStockReportBottomSheet();
      }
    } catch (e) {
      setState(() {
        isLoadingStockReport = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading stock report: $e')));
    }
  }

  void _showStockReportBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: AppColors.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stock Report',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedCategoryName ?? 'Category'} • ${selectedItems.length} item(s)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(child: _buildStockReportContent(scrollController)),
                    // Bottom buttons
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBottomSheetButton(
                                icon: Icons.download,
                                label: 'Download PDF',
                                color: AppColors.primaryColor,
                                onTap: () {
                                  Navigator.pop(context);
                                  _downloadStockReport();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBottomSheetButton(
                                icon: FontAwesomeIcons.whatsapp,
                                label: 'WhatsApp',
                                color: Colors.green,
                                isFaIcon: true,
                                onTap: () {
                                  Navigator.pop(context); // Close bottom sheet
                                  _shareViaWhatsApp(); // Call the WhatsApp method
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildBottomSheetButton({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFaIcon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isFaIcon
                ? FaIcon(icon, size: 18, color: color)
                : Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockReportContent(ScrollController scrollController) {
    int grandTotal = 0;
    Map<String, int> itemTotals = {};

    final groupedByItemAndStyle = _groupItemsByItemAndStyle();

    groupedByItemAndStyle.forEach((itemName, styleGroups) {
      int itemTotal = 0;
      styleGroups.forEach((styleCode, items) {
        itemTotal += items.fold(0, (sum, item) => sum + (item.total ?? 0));
      });
      itemTotals[itemName] = itemTotal;
      grandTotal += itemTotal;
    });

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        ...groupedByItemAndStyle.entries.map((entry) {
          return _buildStyledItemSection(entry.key, entry.value);
        }).toList(),
        if (groupedByItemAndStyle.isNotEmpty)
          _buildGrandTotalCard(itemTotals, grandTotal),
      ],
    );
  }

  Widget _buildStyledItemSection(
    String itemName,
    Map<String, List<StockReportItem>> styleGroups,
  ) {
    int itemTotal = 0;
    List<Widget> styleTables = [];

    styleGroups.forEach((styleCode, items) {
      int styleTotal = 0;

      // Parse details to extract size-wise quantities
      Map<String, Map<String, int>> shadeSizeQuantities = {};
      List<String> allSizes = [];

      for (var item in items) {
        styleTotal += item.total ?? 0;

        if (item.details != null && item.details!.isNotEmpty) {
          Map<String, int> sizeMap = {};
          List<String> sizePairs = item.details!.split(',');

          for (String pair in sizePairs) {
            List<String> parts = pair.split(':');
            if (parts.length == 2) {
              String size = parts[0].trim();
              int quantity = int.tryParse(parts[1].trim()) ?? 0;
              sizeMap[size] = quantity;

              if (!allSizes.contains(size)) {
                allSizes.add(size);
              }
            }
          }

          shadeSizeQuantities[item.shadeName ?? 'Unknown'] = sizeMap;
        }
      }

      itemTotal += styleTotal;

      // Sort sizes numerically
      allSizes.sort((a, b) {
        int? aNum = int.tryParse(a);
        int? bNum = int.tryParse(b);
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        return a.compareTo(b);
      });

      // Calculate totals
      Map<String, int> sizeTotals = {};

      for (var size in allSizes) {
        sizeTotals[size] = 0;
      }

      for (var item in items) {
        if (shadeSizeQuantities.containsKey(item.shadeName)) {
          var sizeMap = shadeSizeQuantities[item.shadeName]!;
          for (var size in sizeMap.keys) {
            sizeTotals[size] = (sizeTotals[size] ?? 0) + (sizeMap[size] ?? 0);
          }
        }
      }

      styleTables.add(
        _buildStyleTable(
          styleCode: styleCode,
          items: items,
          allSizes: allSizes,
          shadeSizeQuantities: shadeSizeQuantities,
          sizeTotals: sizeTotals,
          styleTotal: styleTotal,
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Header with border only
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryColor.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryColor.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemName.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor.shade900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryColor.shade200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: $itemTotal',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Style Tables
        ...styleTables,
      ],
    );
  }

  Widget _buildStyleTable({
    required String styleCode,
    required List<StockReportItem> items,
    required List<String> allSizes,
    required Map<String, Map<String, int>> shadeSizeQuantities,
    required Map<String, int> sizeTotals,
    required int styleTotal,
  }) {
    // Define consistent column widths
    const double shadeColumnWidth = 120;
    const double sizeColumnWidth = 50;
    const double totalColumnWidth = 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Style Header with compact design
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.primaryColor.shade100),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (withImage && items.isNotEmpty)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryColor.shade200,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _getImageUrl(items.first),
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.image_not_supported,
                              size: 16,
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        styleCode,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor.shade900,
                        ),
                      ),
                      if (items.isNotEmpty && items.first.brandName != null)
                        Text(
                          items.first.brandName!,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryColor.shade200),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$styleTotal',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table with Fixed Shade Column and Scrollable Content
          if (allSizes.isNotEmpty && shadeSizeQuantities.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed Shade Column Section (doesn't scroll) - Matching design
                  Container(
                    width: shadeColumnWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Shade Header - Matching scrollable header design
                        Container(
                          height: 38,
                          color: AppColors.primaryColor[50],
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SHADE',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: AppColors.primaryColor.shade900,
                            ),
                          ),
                        ),

                        // Shade names with alternating colors - Matching row design
                        ...shadeSizeQuantities.entries.map((entry) {
                          String shade = entry.key;
                          int index = shadeSizeQuantities.entries
                              .toList()
                              .indexOf(entry);

                          return Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey[50],
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              shade,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),

                        // Total row shade - Matching total row design
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(
                              top: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'TOTAL',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content Section
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Scrollable Header
                          Container(
                            height: 38,
                            color: AppColors.primaryColor[50],
                            child: Row(
                              children: [
                                ...allSizes.map(
                                  (size) => Container(
                                    width: sizeColumnWidth,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        size,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                          color:
                                              AppColors.primaryColor.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Total column header
                                Container(
                                  width: totalColumnWidth,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor[100],
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'TOTAL',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                        color: AppColors.primaryColor.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Data Rows
                          ...shadeSizeQuantities.entries.map((entry) {
                            Map<String, int> sizeMap = entry.value;
                            int shadeTotal = sizeMap.values.fold(
                              0,
                              (a, b) => a + b,
                            );
                            int index = shadeSizeQuantities.entries
                                .toList()
                                .indexOf(entry);

                            return Container(
                              height: 32,
                              color:
                                  index % 2 == 0
                                      ? Colors.white
                                      : Colors.grey[50],
                              child: Row(
                                children: [
                                  // Size columns
                                  ...allSizes.map(
                                    (size) => Container(
                                      width: sizeColumnWidth,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          sizeMap[size]?.toString() ?? '0',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight:
                                                (sizeMap[size] ?? 0) > 0
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                            color:
                                                (sizeMap[size] ?? 0) > 0
                                                    ? AppColors
                                                        .primaryColor
                                                        .shade700
                                                    : Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Total column
                                  Container(
                                    width: totalColumnWidth,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor[50],
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        shadeTotal.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppColors.primaryColor.shade900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),

                          // Scrollable Total Row
                          Container(
                            height: 32,
                            color: Colors.grey[100],
                            child: Row(
                              children: [
                                // Size total columns
                                ...allSizes.map(
                                  (size) => Container(
                                    width: sizeColumnWidth,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        sizeTotals[size]?.toString() ?? '0',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Grand total column
                                Container(
                                  width: totalColumnWidth,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor[100],
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      styleTotal.toString(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: AppColors.primaryColor.shade900,
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
                ],
              ),
            ),

          if (allSizes.isEmpty || shadeSizeQuantities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'No size-wise data available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard(Map<String, int> itemTotals, int grandTotal) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryColor.shade100),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryColor.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.summarize,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRAND TOTAL',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryColor.shade900,
                        ),
                      ),
                      Text(
                        '${selectedCategoryName?.toUpperCase() ?? 'LADIES WEAR'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryColor.shade200),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    grandTotal.toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primaryColor.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Item breakdowns
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...itemTotals.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor.shade100,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: AppColors.primaryColor.shade100),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items: ${itemTotals.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Generated: ${DateTime.now().toString().substring(0, 10)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      final fetchedCategories = await ApiService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
    }
  }

  Future<void> _fetchAllItems() async {
    setState(() {
      isLoadingItems = true;
    });
    try {
      final fetchedItems = await ApiService.fetchAllItems();
      setState(() {
        items = fetchedItems;
        isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        isLoadingItems = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    }
  }

  Future<void> _fetchItemsByCategory(String categoryKey) async {
    setState(() {
      isLoadingItems = true;
    });
    try {
      final fetchedItems = await ApiService.fetchItemsByCategory(categoryKey);
      setState(() {
        items = fetchedItems;
        isLoadingItems = false;
      });
      await _fetchStyles(categoryKey);
      await _fetchShades(categoryKey);
      await _fetchSizes(categoryKey);
    } catch (e) {
      setState(() {
        isLoadingItems = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    }
  }

  Future<void> _fetchStyles(String itemGrpKey) async {
    try {
      final fetchedStyles = await ApiService.fetchStylesByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        styles = fetchedStyles;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading styles: $e')));
    }
  }

  Future<void> _fetchShades(String itemGrpKey) async {
    try {
      final fetchedShades = await ApiService.fetchShadesByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        shades = fetchedShades;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading shades: $e')));
    }
  }

  Future<void> _fetchSizes(String itemGrpKey) async {
    try {
      final fetchedSizes = await ApiService.fetchStylesSizeByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        sizes = fetchedSizes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sizes: $e')));
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final fetchedBrands = await ApiService.fetchBrands();
      setState(() {
        brands = fetchedBrands;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading brands: $e')));
    }
  }

  void _showFilterDialog() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => StockFilterPage(),
        settings: RouteSettings(
          arguments: {
            'styles': styles,
            'shades': shades,
            'sizes': sizes,
            'brands': brands,
            'selectedStyles': selectedStyles,
            'selectedShades': selectedShades,
            'selectedSizes': selectedSizes,
            'selectedBrands': selectedBrands,
            'fromMRP': fromMRP,
            'toMRP': toMRP,
            'withImage': withImage,
          },
        ),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );

    if (result != null) {
      Map<String, dynamic> selectedFilters = result;
      setState(() {
        selectedStyles = selectedFilters['styles'] ?? [];
        selectedShades = selectedFilters['shades'] ?? [];
        selectedSizes = selectedFilters['sizes'] ?? [];
        selectedBrands = selectedFilters['brands'] ?? [];
        fromMRP = selectedFilters['fromMRP'] ?? '';
        toMRP = selectedFilters['toMRP'] ?? '';
        withImage = selectedFilters['withImage'] ?? false;
      });

      if (selectedCategoryKey != null && selectedItem != null) {
        await _fetchStockReport();
      } else {
        setState(() {
          stockReportItems = [];
        });
        await _fetchAllItems();
      }
    }
  }

  void clearFilters() {
    setState(() {
      selectedCategoryKey = null;
      selectedCategoryName = null;
      selectedItem = null;
      selectedItems = [];
      selectedStyles = [];
      selectedShades = [];
      selectedSizes = [];
      selectedBrands = [];
      fromMRP = '';
      toMRP = '';
      stockReportItems = [];
      hasSearched = false;
    });
    _fetchAllItems();
  }

  // Helper method to group stock report items by item name first, then by style code
  Map<String, Map<String, List<StockReportItem>>> _groupItemsByItemAndStyle() {
    Map<String, Map<String, List<StockReportItem>>> groupedItems = {};

    for (var item in stockReportItems) {
      final itemName = item.itemName ?? 'Unknown Item';
      final styleCode = item.styleCode ?? 'Unknown';

      if (!groupedItems.containsKey(itemName)) {
        groupedItems[itemName] = {};
      }

      if (!groupedItems[itemName]!.containsKey(styleCode)) {
        groupedItems[itemName]![styleCode] = [];
      }

      groupedItems[itemName]![styleCode]!.add(item);
    }

    return groupedItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text(
          'Stock Report',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Clear button - circular
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
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
              onPressed: clearFilters,
              icon: const Icon(Icons.clear, color: Colors.white, size: 18),
              tooltip: "Clear All",
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
          const SizedBox(width: 8),

          // Filter button with badge - circular
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 18,
                  ),
                  tooltip: "Filter",
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                if (_getActiveFilterCount() > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '${_getActiveFilterCount()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category Card with border only
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor.shade200,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.category,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Select Category',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownSearch<String>(
                      items:
                          categories
                              .map((category) => category.itemSubGrpName)
                              .toList(),
                      selectedItem: selectedCategoryName,
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryName = value;
                          selectedItem = null;
                          if (value != null) {
                            Category? selectedCategory;
                            try {
                              for (var cat in categories) {
                                if (cat.itemSubGrpName == value) {
                                  selectedCategory = cat;
                                  break;
                                }
                              }
                              if (selectedCategory != null) {
                                selectedCategoryKey =
                                    selectedCategory.itemSubGrpKey;
                                _fetchItemsByCategory(selectedCategoryKey!);
                              } else {
                                selectedCategoryKey = null;
                                _fetchAllItems();
                              }
                            } catch (e) {
                              selectedCategoryKey = null;
                              _fetchAllItems();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error selecting category: $e'),
                                ),
                              );
                            }
                          } else {
                            selectedCategoryKey = null;
                            _fetchAllItems();
                          }
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: "Choose category",
                          hintStyle: GoogleFonts.poppins(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search Category",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        containerBuilder:
                            (context, popupWidget) => Container(
                              color: Colors.white,
                              child: popupWidget,
                            ),
                        loadingBuilder:
                            isLoadingCategories
                                ? (context, searchEntry) => Center(
                                  child: LoadingAnimationWidget.waveDots(
                                    color: AppColors.primaryColor,
                                    size: 40,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items Card with border only
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor.shade200,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Select Items',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownSearch<Item>.multiSelection(
                      items: items,
                      compareFn: (Item a, Item b) => a.itemKey == b.itemKey,
                      itemAsString:
                          (Item i) =>
                              i.itemName == "All Items"
                                  ? "All"
                                  : (i.itemName ?? ''),
                      selectedItems: selectedItems,
                      onChanged: (List<Item> value) {
                        setState(() {
                          selectedItems = value;
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: "Choose items",
                          hintStyle: GoogleFonts.poppins(fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      popupProps: PopupPropsMultiSelection.menu(
                        showSearchBox: true,
                        showSelectedItems: true,

                        // ⭐ THIS HIDES THE DEFAULT CHECKBOX
                        selectionWidget: (context, item, isSelected) {
                          return const SizedBox();
                        },

                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: "Search Item",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        itemBuilder: (context, item, isSelected) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            color:
                                isSelected
                                    ? AppColors.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.itemName ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? AppColors.primaryColor
                                          : Colors.black87,
                                ),
                              ),
                              trailing:
                                  isSelected
                                      ? Icon(
                                        Icons.check,
                                        color: AppColors.primaryColor,
                                        size: 18,
                                      )
                                      : null,
                            ),
                          );
                        },

                        loadingBuilder:
                            isLoadingItems
                                ? (context, searchEntry) => Center(
                                  child: LoadingAnimationWidget.waveDots(
                                    color: AppColors.primaryColor,
                                    size: 40,
                                  ),
                                )
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons with border only
            // Action Buttons with icon and label in same line
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHorizontalButton(
                      icon: Icons.visibility,
                      label: "View",
                      color: AppColors.primaryColor,
                      onTap: _fetchStockReport,
                    ),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    _buildHorizontalButton(
                      icon: Icons.download,
                      label: "PDF",
                      color: AppColors.primaryColor,
                      onTap: _downloadStockReport,
                    ),
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    _buildHorizontalButton(
                      icon: FontAwesomeIcons.whatsapp,
                      label: "WhatsApp",
                      color: Colors.green,
                      isFaIcon: true,
                      onTap: () async {
                        await _shareViaWhatsApp();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Banner
            if (selectedItems.isNotEmpty && !hasSearched)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryColor.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${selectedItems.length} item(s) selected. Tap View to see stock report.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primaryColor.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading indicator
            if (isLoadingStockReport)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingAnimationWidget.waveDots(
                        color: AppColors.primaryColor,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fetching stock data...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty state
            if (!isLoadingStockReport &&
                hasSearched &&
                stockReportItems.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stock data found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try selecting different items or filters',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Hint for empty state
            if (!hasSearched && selectedItems.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No items selected',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select category and items to view stock report',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentScreen: '/stockReport',
      ),
    );
  }

  Widget _buildHorizontalButton({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFaIcon = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isFaIcon
                  ? FaIcon(icon, size: 16, color: color)
                  : Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBorderButton({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFaIcon = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isFaIcon
                  ? FaIcon(icon, size: 18, color: color)
                  : Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }

  // Add this method to handle WhatsApp sharing
  Future<void> _shareViaWhatsApp() async {
    if (selectedCategoryKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show mobile number dialog
    final result = await _showMobileNumberDialog();

    if (result == null) return; // User cancelled

    String mobileNo = result['mobileNo'] ?? '';

    // Show loading dialog
    if (!context.mounted) return;

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
                LoadingAnimationWidget.waveDots(color: Colors.green, size: 50),
                const SizedBox(height: 20),
                Text(
                  'Preparing stock report for WhatsApp...',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Fetch stock data
      String itemKeys = selectedItems
          .map((e) => e.itemKey)
          .where((e) => e != null && e.isNotEmpty)
          .join(',');

      final fetchedStockReport = await ApiService.fetchStockReport(
        itemSubGrpKey: selectedCategoryKey!,
        itemKey: itemKeys,
        userId: 'admin',
        fcYrId: '24',
        cobr: '01',
        brandKey:
            selectedBrands.isNotEmpty
                ? selectedBrands.map((b) => b.brandKey).join(',')
                : null,
        styleKey:
            selectedStyles.isNotEmpty
                ? selectedStyles.map((s) => s.styleKey).join(',')
                : null,
        shadeKey:
            selectedShades.isNotEmpty
                ? selectedShades.map((s) => s.shadeKey).join(',')
                : null,
        sizeKey:
            selectedSizes.isNotEmpty
                ? selectedSizes.map((s) => s.itemSizeKey).join(',')
                : null,
        fromMRP: fromMRP.isNotEmpty ? double.tryParse(fromMRP) : null,
        toMRP: toMRP.isNotEmpty ? double.tryParse(toMRP) : null,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      // Send PDF via Node API (whatsappType == "1")
      await _sendPDFViaNodeAPI(fetchedStockReport, mobileNo);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to send PDF via Node API (whatsappType == "1")
  Future<void> _sendPDFViaNodeAPI(
    List<StockReportItem> stockData,
    String mobileNo,
  ) async {
    try {
      // Generate PDF first
      final pdf = await _generateStockReportPDF(stockData);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/stock_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Read file bytes and convert to base64
      final pdfBytes = await file.readAsBytes();
      String fileBase64 = base64Encode(pdfBytes);

      // Prepare caption
      String caption = _prepareStockReportCaption();

      // Show sending dialog
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending via WhatsApp...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Send via Node API (same as CatalogPage)
      final response = await http.post(
        Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
        body: {
          'data': fileBase64,
          'filename': 'stock_report.pdf',
          'key': AppConstants.whatsappKey,
          'number': '91$mobileNo',
          'caption': caption,
        },
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock report sent successfully to $mobileNo'),
            backgroundColor: Colors.green,
          ),
        );

        // Optionally clear selection after successful send
        setState(() {
          // You can clear selections if needed
          // selectedItems = [];
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send via WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sending PDF via Node API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  // Mobile number dialog (simplified version without format selection)
  Future<Map<String, String>?> _showMobileNumberDialog() {
    TextEditingController mobileController = TextEditingController();

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
              // Mobile number input
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
              const SizedBox(height: 8),

              // Info message
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
                        'Stock report will be sent as PDF via WhatsApp',
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
                      content: Text(
                        'Please enter valid 10-digit mobile number',
                      ),
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

  // Prepare caption for WhatsApp message
  String _prepareStockReportCaption() {
    String category = selectedCategoryName ?? 'Category';
    int itemCount = selectedItems.length;

    // Calculate totals
    int totalQuantity = 0;
    for (var item in stockReportItems) {
      totalQuantity += item.total ?? 0;
    }

    return '''
📊 *Stock Report* 
📅 Date: ${DateTime.now().toString().substring(0, 10)}
🏢 Company: VRS Software

Generated from VRS ERP App
  ''';
  }

  // Extract PDF generation to a reusable method
  Future<pw.Document> _generateStockReportPDF(
    List<StockReportItem> stockData,
  ) async {
    final pdf = pw.Document();

    // Use the same grouping logic as bottom sheet
    final groupedByItemAndStyle = _groupItemsByItemAndStyle();

    List<pw.Widget> content = [];
    int grandTotal = 0;

    for (var itemEntry in groupedByItemAndStyle.entries) {
      String uniqueItemKey = itemEntry.key;
      Map<String, List<StockReportItem>> styleGroups = itemEntry.value;

      // Extract actual item name
      String itemName = uniqueItemKey.split('|')[0];
      int itemTotal = 0;

      for (var styleEntry in styleGroups.entries) {
        String styleCode = styleEntry.key;
        List<StockReportItem> items = styleEntry.value;

        // Collect all sizes for this style
        List<String> allSizes = [];
        for (var item in items) {
          if (item.details != null) {
            for (var pair in item.details!.split(',')) {
              final parts = pair.split(':');
              if (parts.length == 2) {
                String size = parts[0].trim();
                if (!allSizes.contains(size)) {
                  allSizes.add(size);
                }
              }
            }
          }
        }

        // Sort sizes numerically
        allSizes.sort((a, b) {
          int? aNum = int.tryParse(a);
          int? bNum = int.tryParse(b);
          if (aNum != null && bNum != null) {
            return aNum.compareTo(bNum);
          }
          return a.compareTo(b);
        });

        // Build shade data for this style
        Map<String, Map<String, int>> shadeData = {};
        Map<String, int> sizeTotals = {};

        for (var size in allSizes) {
          sizeTotals[size] = 0;
        }

        for (var item in items) {
          String shade = item.shadeName ?? "Unknown";
          shadeData.putIfAbsent(shade, () => {});

          if (item.details != null) {
            for (var pair in item.details!.split(',')) {
              var parts = pair.split(':');
              if (parts.length == 2) {
                String size = parts[0].trim();
                int qty = int.tryParse(parts[1]) ?? 0;
                shadeData[shade]![size] = qty;
                sizeTotals[size] = (sizeTotals[size] ?? 0) + qty;
              }
            }
          }
        }

        // Calculate style total
        int styleTotal = items.fold(0, (sum, item) => sum + (item.total ?? 0));
        itemTotal += styleTotal;

        // Build PDF table for this style
        List<pw.TableRow> rows = [];

        // Header
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              _cell("Shade", 70),
              if (withImage) _cell("Img", 35),
              ...allSizes.map((s) => _cell(s, 40)),
              _cell("Total", 50),
            ],
          ),
        );

        // Data rows
        for (var shadeEntry in shadeData.entries) {
          String shade = shadeEntry.key;
          Map<String, int> sizeMap = shadeEntry.value;
          int shadeTotal = sizeMap.values.fold(0, (a, b) => a + b);

          pw.MemoryImage? image;
          if (withImage) {
            final url = _getImageUrl(items.first);
            image = await _loadPdfImage(url);
          }

          rows.add(
            pw.TableRow(
              children: [
                _cell(shade, 70),
                if (withImage)
                  pw.Container(
                    width: 25,
                    height: 25,
                    alignment: pw.Alignment.center,
                    child:
                        image != null
                            ? pw.Image(
                              image,
                              width: 16,
                              height: 16,
                              fit: pw.BoxFit.contain,
                            )
                            : pw.SizedBox(),
                  ),
                ...allSizes.map((size) {
                  int qty = sizeMap[size] ?? 0;
                  return _cell(qty.toString(), 40);
                }),
                _cell(shadeTotal.toString(), 50),
              ],
            ),
          );
        }

        // Total row
        rows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cell("Total", 70),
              if (withImage) _cell("", 35),
              ...allSizes.map((s) => _cell(sizeTotals[s].toString(), 40)),
              _cell(styleTotal.toString(), 50),
            ],
          ),
        );

        // Add style section to PDF
        content.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Style header
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.grey100,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          "Style: $styleCode",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.Text(
                        "Brand: ${items.first.brandName ?? ''}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: rows,
                ),
                pw.SizedBox(height: 4),
              ],
            ),
          ),
        );
      }

      grandTotal += itemTotal;

      // Add item total after all styles for this item
      content.add(
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(right: 8, bottom: 12),
          child: pw.Text(
            "$itemName Total: $itemTotal",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ),
      );
    }

    // Add grand total
    content.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(top: 16),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(),
          color: PdfColors.grey100,
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "GRAND TOTAL",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
            pw.Text(
              grandTotal.toString(),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "VRS SOFTWARE",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Date: ${DateTime.now().toString().substring(0, 10)}",
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Text(
                  "Item Wise Stock Report",
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  "Category: ${selectedCategoryName ?? ''}",
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 5),
                pw.Divider(),
              ],
            );
          }
          return pw.SizedBox(height: 10);
        },
        build: (context) => content,
      ),
    );
    return pdf;
  }
}
