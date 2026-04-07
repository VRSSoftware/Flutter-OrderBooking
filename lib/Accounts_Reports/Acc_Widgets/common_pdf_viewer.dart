import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CommonPdfViewer extends StatefulWidget {
  final String pdfPath;
  final String title;
  final String subtitle;
  final String fromDate;
  final String toDate;
  final String reportType;
  final bool showDownloadButton;

  const CommonPdfViewer({
    super.key,
    required this.pdfPath,
    required this.title,
    required this.subtitle,
    required this.fromDate,
    required this.toDate,
    required this.reportType,
    this.showDownloadButton = true,
  });

  @override
  State<CommonPdfViewer> createState() => _CommonPdfViewerState();
}

class _CommonPdfViewerState extends State<CommonPdfViewer> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  PDFViewController? _pdfViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - ${widget.subtitle}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.showDownloadButton)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _savePdfPermanently,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Period: ${widget.fromDate} to ${widget.toDate}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type: ${widget.reportType.toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (!_isLoading)
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
                _isLoading = false;
              });
            },
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = (page ?? 0) + 1;
                if (total != null) {
                  _totalPages = total;
                }
              });
            },
            onError: (error) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading PDF: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _savePdfPermanently() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage permission required to save PDF'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${widget.title}_${widget.subtitle}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final permanentFile = File('${directory.path}/$fileName');
      
      final tempFile = File(widget.pdfPath);
      await tempFile.copy(permanentFile.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully to Documents'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}