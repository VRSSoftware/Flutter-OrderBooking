import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAllItems();
    _fetchBrands();
  }

  Future<void> _downloadStockReport() async {
    if (selectedCategoryKey == null || selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both category and item first')),
      );
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
                LoadingAnimationWidget.waveDots(color: Colors.blue, size: 50),
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
        brandKey: selectedBrands.isNotEmpty ? selectedBrands.map((b) => b.brandKey).join(',') : null,
        styleKey: selectedStyles.isNotEmpty ? selectedStyles.map((s) => s.styleKey).join(',') : null,
        shadeKey: selectedShades.isNotEmpty ? selectedShades.map((s) => s.shadeKey).join(',') : null,
        sizeKey: selectedSizes.isNotEmpty ? selectedSizes.map((s) => s.itemSizeKey).join(',') : null,
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
    if (stockData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to download'))
      );
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
                LoadingAnimationWidget.waveDots(color: Colors.blue, size: 50),
                const SizedBox(height: 20),
                Text(
                  'Generating PDF...',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      List<String> selectedItemNames = selectedItems
          .map((item) => item.itemName ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      final pdf = pw.Document();
      
      // Group items by item name first, then by style code
      Map<String, Map<String, List<StockReportItem>>> groupedByItemAndStyle = {};
      
      for (var item in stockData) {
        final itemName = item.itemName ?? 'Unknown Item';
        final styleCode = item.styleCode ?? 'Unknown';
        
        if (!groupedByItemAndStyle.containsKey(itemName)) {
          groupedByItemAndStyle[itemName] = {};
        }
        
        if (!groupedByItemAndStyle[itemName]!.containsKey(styleCode)) {
          groupedByItemAndStyle[itemName]![styleCode] = [];
        }
        
        groupedByItemAndStyle[itemName]![styleCode]!.add(item);
      }

      // Get all unique sizes across all items
      List<String> allSizes = [];
      for (var item in stockData) {
        if (item.details != null && item.details!.isNotEmpty) {
          List<String> pairs = item.details!.split(',');
          for (var pair in pairs) {
            List<String> parts = pair.split(':');
            if (parts.length == 2) {
              String size = parts[0].trim();
              if (!allSizes.contains(size)) {
                allSizes.add(size);
              }
            }
          }
        }
      }

      allSizes.sort((a, b) {
        int? aNum = int.tryParse(a);
        int? bNum = int.tryParse(b);
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        Map<String, int> sizeOrder = {
          'XS': 1, 'S': 2, 'M': 3, 'L': 4, 'XL': 5, '2XL': 6, '3XL': 7, 
          '4XL': 8, '5XL': 9, '6XL': 10, '7XL': 11, '8XL': 12
        };
        int aOrder = sizeOrder[a] ?? 999;
        int bOrder = sizeOrder[b] ?? 999;
        if (aOrder != 999 || bOrder != 999) {
          return aOrder.compareTo(bOrder);
        }
        return a.compareTo(b);
      });

      List<pw.Widget> allPages = [];
      Map<String, int> itemTotals = {};
      
      // Build pages for each item
      groupedByItemAndStyle.forEach((itemName, styleGroups) {
        int itemTotal = 0;
        List<pw.Widget> itemSections = [];
        
        // Add item header
        itemSections.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 16, bottom: 8),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.deepOrange,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  itemName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  '${selectedCategoryName?.toUpperCase() ?? 'LADIES WEAR'}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          )
        );
        
        // Add style sections for this item
        styleGroups.forEach((styleCode, items) {
          Map<String, Map<String, int>> shadeData = {};
          Map<String, int> sizeTotals = {};
          
          for (var item in items) {
            String shadeName = item.shadeName ?? 'Unknown';
            Map<String, int> sizeMap = {};
            
            if (item.details != null && item.details!.isNotEmpty) {
              List<String> pairs = item.details!.split(',');
              for (var pair in pairs) {
                List<String> parts = pair.split(':');
                if (parts.length == 2) {
                  String size = parts[0].trim();
                  int qty = int.tryParse(parts[1].trim()) ?? 0;
                  sizeMap[size] = qty;
                  sizeTotals[size] = (sizeTotals[size] ?? 0) + qty;
                }
              }
            }
            
            shadeData[shadeName] = sizeMap;
          }

          int styleTotal = items.fold(0, (sum, item) => sum + (item.total ?? 0));
          itemTotal += styleTotal;

          itemSections.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8),
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.blue50,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          styleCode,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        ),
                        child: pw.Text(
                          'Total: $styleTotal',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Container(
                          width: 80,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Shade', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          width: 50,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        ...allSizes.map((size) => pw.Container(
                          width: 40,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(size, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        )).toList(),
                      ],
                    ),
                    
                    ...shadeData.entries.map((entry) {
                      String shade = entry.key;
                      Map<String, int> sizeMap = entry.value;
                      int shadeTotal = items.firstWhere(
                        (item) => item.shadeName == shade,
                        orElse: () => StockReportItem(),
                      ).total ?? 0;
                      
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            width: 80,
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(shade, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
                          ),
                          pw.Container(
                            width: 50,
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(shadeTotal.toString(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                          ),
                          ...allSizes.map((size) {
                            int qty = sizeMap[size] ?? 0;
                            return pw.Container(
                              width: 40,
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                qty.toString(),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: qty > 0 ? PdfColors.green700 : PdfColors.grey400,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                    
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        pw.Container(
                          width: 80,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Style Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        pw.Container(
                          width: 50,
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(styleTotal.toString(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        ),
                        ...allSizes.map((size) {
                          return pw.Container(
                            width: 40,
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              sizeTotals[size]?.toString() ?? '0',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            )
          );
        });
        
        // Add item total row
        itemSections.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 8, bottom: 16),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.amber600, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$itemName TOTAL:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                  ),
                ),
                pw.Text(
                  itemTotal.toString(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber900,
                  ),
                ),
              ],
            ),
          )
        );
        
        itemTotals[itemName] = itemTotal;
        allPages.addAll(itemSections);
      });

      int grandTotal = stockData.fold(0, (sum, item) => sum + (item.total ?? 0));

      // Add grand total with item-wise breakdown
      allPages.add(
        pw.Column(
          children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 16),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'GRAND TOTAL',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        ),
                        child: pw.Text(
                          grandTotal.toString(),
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.white),
                  pw.SizedBox(height: 8),
                  ...itemTotals.entries.map((entry) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${entry.key}:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            entry.value.toString(),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total --> ${selectedCategoryName?.toUpperCase() ?? 'LADIES WEAR'}:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                  pw.Text(
                    grandTotal.toString(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            if (context.pageNumber == 1) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VRS Software Pvt Ltd',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Item Wise Stock Report',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Category: ${selectedCategoryName ?? 'All Categories'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Items: ${selectedItemNames.join(', ')}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                ],
              );
            }
            return pw.SizedBox(height: 10);
          },
          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated on: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            );
          },
          build: (pw.Context context) {
            return allPages;
          },
        ),
      );

      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      String cleanName = (selectedCategoryName ?? 'Stock').replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final fileName = 'ItemWiseStock_${cleanName}_$dateStr.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded successfully, opening...'),
            backgroundColor: Colors.green,
          ),
        );

        final result = await OpenFile.open(file.path);
        
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (selectedCategoryKey == null || selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both category and item')),
      );
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
        brandKey: selectedBrands.isNotEmpty ? selectedBrands.map((b) => b.brandKey).join(',') : null,
        styleKey: selectedStyles.isNotEmpty ? selectedStyles.map((s) => s.styleKey).join(',') : null,
        shadeKey: selectedShades.isNotEmpty ? selectedShades.map((s) => s.shadeKey).join(',') : null,
        sizeKey: selectedSizes.isNotEmpty ? selectedSizes.map((s) => s.itemSizeKey).join(',') : null,
        fromMRP: fromMRP.isNotEmpty ? double.tryParse(fromMRP) : null,
        toMRP: toMRP.isNotEmpty ? double.tryParse(toMRP) : null,
      );

      setState(() {
        stockReportItems = stockReport;
        isLoadingStockReport = false;
      });
    } catch (e) {
      setState(() {
        isLoadingStockReport = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading stock report: $e')));
    }
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
      final fetchedStyles = await ApiService.fetchStylesByItemGrpKey(itemGrpKey);
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
      final fetchedShades = await ApiService.fetchShadesByItemGrpKey(itemGrpKey);
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
      final fetchedSizes = await ApiService.fetchStylesSizeByItemGrpKey(itemGrpKey);
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
        pageBuilder: (context, animation, secondaryAnimation) => StockFilterPage(),
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

  Widget _buildItemSection(String itemName, Map<String, List<StockReportItem>> styleGroups) {
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
        Card(
          margin: const EdgeInsets.only(bottom: 20),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Style Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (withImage && items.isNotEmpty)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _getImageUrl(items.first),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        styleCode,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Style Total Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Total: $styleTotal',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Table Container
              if (allSizes.isNotEmpty && shadeSizeQuantities.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Header
                        Container(
                          color: Colors.grey.shade50,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Shade',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              ...allSizes.map(
                                (size) => Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Center(
                                    child: Text(
                                      size,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Center(
                                  child: Text(
                                    'Total',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table Rows
                        ...shadeSizeQuantities.entries.map((entry) {
                          String shade = entry.key;
                          Map<String, int> sizeMap = entry.value;
                          int shadeTotal = items.firstWhere(
                            (item) => item.shadeName == shade,
                            orElse: () => StockReportItem(),
                          ).total ?? 0;

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 140,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Text(
                                    shade,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                ...allSizes.map(
                                  (size) => Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    child: Center(
                                      child: Text(
                                        sizeMap[size]?.toString() ?? '0',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: (sizeMap[size] ?? 0) > 0 ? FontWeight.w500 : FontWeight.normal,
                                          color: (sizeMap[size] ?? 0) > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                  ),
                                  child: Center(
                                    child: Text(
                                      shadeTotal.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Style Total Row
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border(top: BorderSide(color: Colors.grey.shade300)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 140,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  'Style Total',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              ...allSizes.map(
                                (size) => Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Center(
                                    child: Text(
                                      sizeTotals[size]?.toString() ?? '0',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 80,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                ),
                                child: Center(
                                  child: Text(
                                    styleTotal.toString(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue.shade900,
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

              if (allSizes.isEmpty || shadeSizeQuantities.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No size-wise data available',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Header
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                itemName.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                selectedCategoryName?.toUpperCase() ?? 'LADIES WEAR',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        
        // Style Tables
        ...styleTables,
        
        // Item Total
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade600),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemName TOTAL:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
              Text(
                itemTotal.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Stock Report', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  tooltip: "Filter",
                ),
                if (_getActiveFilterCount() > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
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
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Category Dropdown
              DropdownSearch<String>(
                items: categories.map((category) => category.itemSubGrpName).toList(),
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
                          selectedCategoryKey = selectedCategory.itemSubGrpKey;
                          _fetchItemsByCategory(selectedCategoryKey!);
                        } else {
                          selectedCategoryKey = null;
                          _fetchAllItems();
                        }
                      } catch (e) {
                        selectedCategoryKey = null;
                        _fetchAllItems();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error selecting category: $e')),
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
                    labelText: "Select Category",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  fit: FlexFit.loose,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search Category",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  containerBuilder: (context, popupWidget) =>
                      Container(color: Colors.white, child: popupWidget),
                  loadingBuilder: isLoadingCategories
                      ? (context, searchEntry) => Center(
                          child: LoadingAnimationWidget.waveDots(color: Colors.blue, size: 40),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 16),
              
              // Item Dropdown
              DropdownSearch<Item>.multiSelection(
                items: items,
                itemAsString: (Item i) => i.itemName ?? '',
                selectedItems: selectedItems,
                onChanged: (List<Item> value) {
                  setState(() {
                    selectedItems = value;
                    if (value.isNotEmpty) {
                      String itemSubGrpKey = value.first.itemSubGrpKey ?? '';
                      Category? matchingCategory;
                      try {
                        matchingCategory = categories.firstWhere(
                          (cat) => cat.itemSubGrpKey == itemSubGrpKey,
                        );
                      } catch (e) {
                        matchingCategory = null;
                      }
                      if (matchingCategory != null) {
                        selectedCategoryKey = matchingCategory.itemSubGrpKey;
                        selectedCategoryName = matchingCategory.itemSubGrpName;
                      }
                    }
                  });
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Select Items",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                popupProps: PopupPropsMultiSelection.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Search Item",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  loadingBuilder: isLoadingItems
                      ? (context, searchEntry) => Center(
                          child: LoadingAnimationWidget.waveDots(color: Colors.blue, size: 40),
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: "View",
                    color: Colors.blue,
                    onTap: _fetchStockReport,
                  ),
                  _buildActionButton(
                    icon: Icons.download,
                    label: "Download",
                    color: Colors.deepPurple,
                    onTap: _downloadStockReport,
                  ),
                  _buildActionButton(
                    icon: FontAwesomeIcons.whatsapp,
                    label: "WhatsApp",
                    color: Colors.green,
                    isFaIcon: true,
                    onTap: () {},
                  ),
                  _buildActionButton(
                    icon: Icons.clear,
                    label: "Clear",
                    color: Colors.red,
                    onTap: clearFilters,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              
              // Stock Items Table
              Expanded(
                child: isLoadingStockReport
                    ? Center(
                        child: LoadingAnimationWidget.waveDots(color: Colors.blue, size: 40),
                      )
                    : !hasSearched
                        ? const SizedBox()
                        : stockReportItems.isEmpty
                            ? const Center(child: Text('No stock data found'))
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Build item sections
                                    ...groupedByItemAndStyle.entries.map((entry) {
                                      return _buildItemSection(entry.key, entry.value);
                                    }).toList(),

                                    // Grand Total with Item Breakdown
                                    if (groupedByItemAndStyle.isNotEmpty)
                                      Card(
                                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.blue.shade700, Colors.blue.shade900],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.summarize,
                                                      color: Colors.white,
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
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                            color: Colors.white.withOpacity(0.9),
                                                          ),
                                                        ),
                                                        Text(
                                                          'All Items Combined',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Colors.white.withOpacity(0.7),
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
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      grandTotal.toString(),
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Colors.blue.shade900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              const Divider(color: Colors.white30),
                                              const SizedBox(height: 8),
                                              ...itemTotals.entries.map((entry) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        '${entry.key}:',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                      Text(
                                                        entry.value.toString(),
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Total --> ${selectedCategoryName?.toUpperCase() ?? 'LADIES WEAR'}:',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.amber.shade900,
                                                      ),
                                                    ),
                                                    Text(
                                                      grandTotal.toString(),
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.amber.shade900,
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentScreen: '/stockReport',
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFaIcon = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.20),
                    shape: BoxShape.circle,
                  ),
                  child: isFaIcon
                      ? FaIcon(icon, size: 20, color: color)
                      : Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
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
}