import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
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
  bool _isSaving = false;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    final file = File(widget.pdfPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF file not found'),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.subtitle == 'All Ledgers' ? widget.title : '${widget.title} - ${widget.subtitle}',
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.showDownloadButton) ...[
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              onPressed: _isSaving ? null : _savePdfPermanently,
              tooltip: 'Download PDF',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _sharePdf,
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new_outlined),
              onPressed: _openWith,
              tooltip: 'Open with',
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Period: ${widget.fromDate} to ${widget.toDate}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Type: ${widget.reportType.toUpperCase()}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading)
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
            fitPolicy: FitPolicy.BOTH,
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
              debugPrint('PDF Error: $error');
              if (!mounted) return;
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _savePdfPermanently() async {
    final isMounted = mounted;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        
        if (!status.isGranted) {
          if (!isMounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to save PDF'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      
      final String fileName = '${widget.title}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf'
          .replaceAll(' ', '_')
          .toLowerCase();
      
      final String newPath = '${directory.path}/$fileName';

      final File tempFile = File(widget.pdfPath);
      await tempFile.copy(newPath);

      if (!isMounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Documents/$fileName'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      if (!isMounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (isMounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _sharePdf() async {
    final isMounted = mounted;
    
    try {
      final file = File(widget.pdfPath);
      
      if (!await file.exists()) {
        if (!isMounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF file not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final String fileName = '${widget.title}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf'
          .replaceAll(' ', '_')
          .toLowerCase();

      await Share.shareXFiles(
        [XFile(widget.pdfPath, name: fileName)],
        text: '${widget.title} Report\nPeriod: ${widget.fromDate} to ${widget.toDate}',
      );

      if (!isMounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share dialog opened'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      if (!isMounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openWith() async {
    final isMounted = mounted;
    
    try {
      final file = File(widget.pdfPath);
      
      if (!await file.exists()) {
        if (!isMounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF file not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await OpenFile.open(widget.pdfPath);
      
      if (!isMounted) return;
      
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening PDF...'),
            duration: Duration(seconds: 1),
          ),
        );
      } else if (result.type == ResultType.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No app found to open PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      if (!isMounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}