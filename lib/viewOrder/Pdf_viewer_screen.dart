// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:dio/dio.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:http/http.dart' as http;
// import 'package:vrs_erp/constants/app_constants.dart';

// class PdfViewerScreen extends StatefulWidget {
//   final String orderNo;
//   final String? whatsappNo;
//     final String partyName;
//      final String orderDate;
//      final String rptName;

//   const PdfViewerScreen({
//     Key? key,
//     required this.orderNo,
//     required this.whatsappNo,
//     required this.partyName,
//      required this.orderDate,
//      required this.rptName,
//   }) : super(key: key);

//   @override
//   State<PdfViewerScreen> createState() => _PdfViewerScreenState();
// }

// class _PdfViewerScreenState extends State<PdfViewerScreen> {
//   String? filePath = '';
//   String rptName = '';
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPdf();
//   }

//   Future<void> _loadPdf() async {
//     try {
//       final docId = widget.orderNo.replaceAll(RegExp(r'[^0-9]'), '');
//       rptName = widget.rptName;
//       final dio = Dio();
//       final response = await dio.post(
//         // '${AppConstants.Pdf_url}/api/values/order5',
//         '${AppConstants.Pdf_url}/api/order/pdf',
//         data: {"doc_id": docId,
//         "rptName": rptName,
//         "dbName": UserSession.dbName,
//         "dbUser": UserSession.dbUser,
//         "dbPassword": UserSession.dbPassword,
//         "dbServer": UserSession.dbSourceForRpt,
//         "rptPath": UserSession.rptPath,
//         },
//         options: Options(responseType: ResponseType.bytes),
//       );

//       if (response.statusCode == 200) {
//         final dir = await getTemporaryDirectory();
//         final path = '${dir.path}/order_$docId.pdf';
//         final file = File(path);
//         await file.writeAsBytes(response.data);

//         setState(() {
//           filePath = path;
//           isLoading = false;
//           rptName = widget.rptName;
//         });
//       } else {
//         _showError('Failed to load PDF: ${response.statusCode}');
//       }
//     } catch (e) {
//       _showError('Error loading PDF: $e');
//     }
//   }

//   void _showError(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(message)));
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _showShareOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder:
//           (_) => SafeArea(
//             child: Wrap(
//               children: [
//                 ListTile(
//                   leading: const FaIcon(
//                     FontAwesomeIcons.whatsapp,
//                     size: 25,
//                     //color: Colors.green,
//                   ),

//                   title: Text('Send via WhatsApp'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _showWhatsAppDialog();
//                   },
//                 ),
//                 ListTile(
//                   leading: Icon(Icons.share),
//                   title: Text('Share'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _sharePdf();
//                   },
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Future<void> _showWhatsAppDialog() async {
//     final controller = TextEditingController(text: widget.whatsappNo);
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text('Send PDF via WhatsApp'),
//             content: TextField(
//               controller: controller,
//               keyboardType: TextInputType.phone,
//               decoration: InputDecoration(labelText: 'WhatsApp Number'),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   final file = File(filePath!);
//                   final fileBytes = await file.readAsBytes();
//                   final success = await sendWhatsAppFile(
//                     fileBytes: fileBytes,
//                     mobileNo: controller.text,
//                     fileType: 'pdf',
//                     caption: 'Dear ${widget.partyName},Thanks for booking your order with ${UserSession.coBrName}.Your order number:${widget.orderNo} on ${widget.orderDate}.',
//                   );
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         success ? 'Sent via WhatsApp' : 'Failed to send',
//                       ),
//                     ),
//                   );
//                 },
//                 child: Text('Send'),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> _sharePdf() async {
//     if (filePath == null) return;
//     try {
//       await Share.shareXFiles([
//         XFile(filePath!),
//       ], text: 'Dear ${widget.partyName},Thanks for booking your order with ${UserSession.coBrName}.Your order number:${widget.orderNo} on ${widget.orderDate}');
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Share error: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Order PDF'),
//         actions: [
//           IconButton(icon: Icon(Icons.share), onPressed: _showShareOptions),
//         ],
//       ),
//       body:
//           isLoading
//               ? Center(child: CircularProgressIndicator())
//               : kIsWeb ? Container() : PDFView(
//                 filePath: filePath!,
//                 enableSwipe: true,
//                 swipeHorizontal: true,
//                 autoSpacing: false,
//                 pageFling: false,
//                 onError: (error) => _showError('PDF Error: $error'),
//                 onPageError:
//                     (page, error) => _showError('Error on page $page: $error'),
//               ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showShareOptions,
//         tooltip: 'Share PDF',
//         child: Icon(Icons.share),
//       ),
//     );
//   }
// }

// Future<bool> sendWhatsAppFile({
//   required List<int> fileBytes,
//   required String mobileNo,
//   required String fileType,
//   String? caption,
// }) async {
//   try {
//     String fileBase64 = base64Encode(fileBytes);

//     final response = await http.post(
//       Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
//       body: {
//         'data': fileBase64,
//         'filename': fileType == 'image' ? 'catalog.jpg' : 'Order.pdf',
//         'key': AppConstants.whatsappKey,
//         'number': '91$mobileNo',
//         'caption': caption ?? 'Please find the file attached.',
//       },
//     );

//     return response.statusCode == 200;
//   } catch (e) {
//     print('Error sending file: $e');
//     return false;
//   }
// }

// ignore_for_file: avoid_web_libraries_in_flutter


import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';

// Web-specific import
// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;
// import 'dart:io' as io;
import 'package:vrs_erp/utils/platform/platform_downloader.dart';

class PdfViewerScreen extends StatefulWidget {
  final String orderNo;
  final String? whatsappNo;
  final String partyName;
  final String orderDate;
  final String rptName;

  const PdfViewerScreen({
    Key? key,
    required this.orderNo,
    required this.whatsappNo,
    required this.partyName,
    required this.orderDate,
    required this.rptName,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? filePath = '';
  bool isLoading = true;
  Uint8List? pdfBytes; // For web preview

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final docId = widget.orderNo.replaceAll(RegExp(r'[^0-9]'), '');
      final dio = Dio();
      final response = await dio.post(
        // '${AppConstants.Pdf_url}/api/order/pdf',
        '${AppConstants.Pdf_url}',
        data: {
          "doc_id": docId,
          "rptName": widget.rptName,
          "dbName": UserSession.dbName,
          "dbUser": UserSession.dbUser,
          "dbPassword": UserSession.dbPassword,
          "dbServer": UserSession.dbSourceForRpt,
          "rptPath": UserSession.rptPath,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        if (kIsWeb) {
          setState(() {
            pdfBytes = Uint8List.fromList(response.data);
            isLoading = false;
          });
        } else {
          // final path = await PlatformDownloader.saveTempPdf(
          //   Uint8List.fromList(response.data),
          //   'order_$docId.pdf',
          // );

          setState(() {
            // filePath = path;
            isLoading = false;
          });
        }
      } else {
        _showError('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error loading PDF: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.whatsapp, size: 25),
                  title: const Text('Send via WhatsApp'),
                  onTap: () {
                    Navigator.pop(context);
                    _showWhatsAppDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(context);
                    _sharePdf();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showWhatsAppDialog() async {
    final controller = TextEditingController(text: widget.whatsappNo);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Send PDF via WhatsApp'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'WhatsApp Number'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (kIsWeb) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp send not supported on Web'),
                      ),
                    );
                    return;
                  }

                  final file = io.File(filePath!);
                  final fileBytes = await file.readAsBytes();
                  final success = await sendWhatsAppFile(
                    fileBytes: fileBytes,
                    mobileNo: controller.text,
                    fileType: 'pdf',
                    caption:
                        'Dear ${widget.partyName},Thanks for booking your order with ${UserSession.coBrName}.Your order number:${widget.orderNo} on ${widget.orderDate}.',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Sent via WhatsApp' : 'Failed to send',
                      ),
                    ),
                  );
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  Future<void> _sharePdf() async {
    if (filePath == null && pdfBytes == null) return;
    try {
      if (kIsWeb) {
        // final blob = html.Blob([pdfBytes!], 'application/pdf');
        // final url = html.Url.createObjectUrlFromBlob(blob);
        // html.window.open(url, "_blank"); // Open PDF in new tab
        // html.Url.revokeObjectUrl(url);
        // await PlatformDownloader.saveTempPdf(pdfBytes!,"pdf");

      } else {
        await Share.shareXFiles(
          [XFile(filePath!)],
          text:
              'Dear ${widget.partyName},Thanks for booking your order with ${UserSession.coBrName}.Your order number:${widget.orderNo} on ${widget.orderDate}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareOptions,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : kIsWeb
              ? Center(
                child: ElevatedButton.icon(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Open PDF in New Tab"),
                ),
              )
              : PDFView(
                filePath: filePath!,
                enableSwipe: true,
                swipeHorizontal: true,
                autoSpacing: false,
                pageFling: false,
                onError: (error) => _showError('PDF Error: $error'),
                onPageError:
                    (page, error) => _showError('Error on page $page: $error'),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showShareOptions,
        tooltip: 'Share PDF',
        child: const Icon(Icons.share),
      ),
    );
  }
}

Future<bool> sendWhatsAppFile({
  required List<int> fileBytes,
  required String mobileNo,
  required String fileType,
  String? caption,
}) async {
  try {
    String fileBase64 = base64Encode(fileBytes);

    final response = await http.post(
      Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
      body: {
        'data': fileBase64,
        'filename': fileType == 'image' ? 'catalog.jpg' : 'Order.pdf',
        'key': AppConstants.whatsappKey,
        'number': '91$mobileNo',
        'caption': caption ?? 'Please find the file attached.',
      },
    );

    return response.statusCode == 200;
  } catch (e) {
    print('Error sending file: $e');
    return false;
  }
}
