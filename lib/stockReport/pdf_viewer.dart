import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/stockReportModel.dart';

class PdfService {
  static Future<void> generateStockReport({
    required List<StockReportItem> stockReportItems,
    required String categoryName,
    required List<String> selectedItemNames,
    required Map<String, dynamic> filters,
  }) async {
    final pdf = pw.Document();

    // Group items by style code first
    Map<String, List<StockReportItem>> groupedByStyle = {};
    for (var item in stockReportItems) {
      final styleCode = item.styleCode ?? 'Unknown';
      if (!groupedByStyle.containsKey(styleCode)) {
        groupedByStyle[styleCode] = [];
      }
      groupedByStyle[styleCode]!.add(item);
    }

    // Get all unique sizes across all items
    List<String> allSizes = _extractAllSizes(stockReportItems);
    
    // Sort sizes intelligently
    allSizes.sort(_compareSizes);

    // Build all content first
    List<pw.Widget> allPages = [];
    
    // Add each style group as a section
    groupedByStyle.forEach((styleCode, items) {
      allPages.add(_buildStyleSection(styleCode, items, allSizes));
    });
    
    // Add grand total section
    allPages.add(_buildGrandTotal(stockReportItems, allSizes));

    // Add page with header only on first page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          // Show header only on first page
          if (context.pageNumber == 1) {
            return _buildHeader(context, categoryName, selectedItemNames, filters);
          }
          // Return nothing for other pages (just a small top margin)
          return pw.SizedBox(height: 10);
        },
        footer: (context) => _buildFooter(context),
        build: (context) {
          // Split content across pages if needed
          return allPages;
        },
      ),
    );

    // Save PDF file
    await _savePdfFile(pdf, categoryName);
  }

  static List<String> _extractAllSizes(List<StockReportItem> items) {
    Set<String> sizes = {};
    for (var item in items) {
      if (item.details != null && item.details!.isNotEmpty) {
        List<String> pairs = item.details!.split(',');
        for (var pair in pairs) {
          List<String> parts = pair.split(':');
          if (parts.length == 2) {
            sizes.add(parts[0].trim());
          }
        }
      }
    }
    return sizes.toList();
  }

  static int _compareSizes(String a, String b) {
    // Try numeric comparison first
    int? aNum = int.tryParse(a);
    int? bNum = int.tryParse(b);
    
    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }
    
    // Handle special size formats (S, M, L, XL, etc.)
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
  }

  static pw.Widget _buildHeader(pw.Context context, String categoryName, 
      List<String> selectedItemNames, Map<String, dynamic> filters) {
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
              'Date: ${_getFormattedDate()}',
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
                'Category: $categoryName',
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
        if (_hasActiveFilters(filters)) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Filters: ${_getFilterSummary(filters)}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static bool _hasActiveFilters(Map<String, dynamic> filters) {
    return filters['styles']?.isNotEmpty == true ||
        filters['shades']?.isNotEmpty == true ||
        filters['sizes']?.isNotEmpty == true ||
        filters['brands']?.isNotEmpty == true ||
        filters['fromMRP']?.isNotEmpty == true ||
        filters['toMRP']?.isNotEmpty == true;
  }

  static String _getFilterSummary(Map<String, dynamic> filters) {
    List<String> parts = [];
    
    if (filters['styles']?.isNotEmpty == true) {
      parts.add('Styles: ${(filters['styles'] as List).map((s) => s.styleCode).join(', ')}');
    }
    if (filters['shades']?.isNotEmpty == true) {
      parts.add('Shades: ${(filters['shades'] as List).map((s) => s.shadeName).join(', ')}');
    }
    if (filters['sizes']?.isNotEmpty == true) {
      parts.add('Sizes: ${(filters['sizes'] as List).map((s) => s.sizeName).join(', ')}');
    }
    if (filters['brands']?.isNotEmpty == true) {
      parts.add('Brands: ${(filters['brands'] as List).map((b) => b.brandName).join(', ')}');
    }
    if (filters['fromMRP']?.isNotEmpty == true) {
      parts.add('MRP: ${filters['fromMRP']} - ${filters['toMRP']}');
    }
    
    return parts.join(' | ');
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on: ${_getFormattedDateTime()}',
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
  }

  static pw.Widget _buildStyleSection(String styleCode, 
      List<StockReportItem> items, List<String> allSizes) {
    
    // Calculate size-wise quantities for each shade
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

    // Calculate style total
    int styleTotal = items.fold(0, (sum, item) => sum + (item.total ?? 0));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.blue50,
          child: pw.Row(
            children: [
              pw.Text(
                styleCode,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
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
        
        // Table for this style
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Shade', isHeader: true, width: 80),
                _buildTableCell('Total', isHeader: true, width: 50),
                ...allSizes.map((size) => _buildTableCell(size, isHeader: true, width: 40)).toList(),
              ],
            ),
            
            // Data rows for each shade
            ...shadeData.entries.map((entry) {
              String shade = entry.key;
              Map<String, int> sizeMap = entry.value;
              int shadeTotal = items.firstWhere(
                (item) => item.shadeName == shade,
                orElse: () => StockReportItem(),
              ).total ?? 0;
              
              return pw.TableRow(
                children: [
                  _buildTableCell(shade, width: 80),
                  _buildTableCell(shadeTotal.toString(), 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold), width: 50),
                  ...allSizes.map((size) {
                    int qty = sizeMap[size] ?? 0;
                    return _buildTableCell(
                      qty.toString(),
                      style: pw.TextStyle(
                        color: qty > 0 ? PdfColors.green700 : PdfColors.grey400,
                      ),
                      width: 40,
                    );
                  }).toList(),
                ],
              );
            }).toList(),
            
            // Style total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('Style Total', 
                    style:  pw.TextStyle(fontWeight: pw.FontWeight.bold), width: 80),
                _buildTableCell(styleTotal.toString(), 
                    style:  pw.TextStyle(fontWeight: pw.FontWeight.bold), width: 50),
                ...allSizes.map((size) {
                  return _buildTableCell(
                    sizeTotals[size]?.toString() ?? '0',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    width: 40,
                  );
                }).toList(),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, 
      {bool isHeader = false, double? width, pw.TextStyle? style}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: style ?? pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildGrandTotal(List<StockReportItem> items, List<String> allSizes) {
    int grandTotal = items.fold(0, (sum, item) => sum + (item.total ?? 0));
    
    // Calculate size totals across all items
    Map<String, int> sizeTotals = {};
    for (var item in items) {
      if (item.details != null && item.details!.isNotEmpty) {
        List<String> pairs = item.details!.split(',');
        for (var pair in pairs) {
          List<String> parts = pair.split(':');
          if (parts.length == 2) {
            String size = parts[0].trim();
            int qty = int.tryParse(parts[1].trim()) ?? 0;
            sizeTotals[size] = (sizeTotals[size] ?? 0) + qty;
          }
        }
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GRAND TOTAL',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'All Items Combined',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Row(
            children: [
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
        ],
      ),
    );
  }

  static String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.month}/${now.day}/${now.year}';
  }

  static String _getFormattedDateTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  static String _getFileName(String categoryName) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    
    // Clean category name for filename
    String cleanName = categoryName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    return 'ItemWiseStock_${cleanName}_$dateStr.pdf';
  }

  static Future<void> _savePdfFile(pw.Document pdf, String categoryName) async {
    try {
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _getFileName(categoryName);
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      // Open the file
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
}