import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/services/app_services.dart';

class SaleBillReportViewPage extends StatefulWidget {
  final String orderId;
  final String orderNo;
  final String? defaultWhatsAppMobileNo;
  final bool fromRegisterPage;

  const SaleBillReportViewPage({
    Key? key,
    required this.orderId,
    required this.orderNo,
    this.defaultWhatsAppMobileNo,
    this.fromRegisterPage = false,
  }) : super(key: key);

  @override
  _SaleBillReportViewPageState createState() => _SaleBillReportViewPageState();
}

class _SaleBillReportViewPageState extends State<SaleBillReportViewPage> {
  bool isLoading = true;
  bool isDownloading = false;
  Map<String, dynamic> reportData = {};
  String? errorMessage;

  // Report sections
  List<dynamic> items = [];
  Map<String, dynamic> headerInfo = {};
  Map<String, dynamic> partyDetails = {};
  Map<String, dynamic> dispatchDetails = {};
  Map<String, dynamic> otherDetails = {};
  Map<String, dynamic> amountSummary = {};

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.fetchSaleBillReport(
        docId: widget.orderId,
        coBrId: UserSession.coBrId ?? '',
      );

      if (response['status'] == 'success' && response['data'] != null) {
        setState(() {
          reportData = response['data'];
          _parseReportData(reportData);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load report data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading report: $e';
        isLoading = false;
      });
    }
  }

  void _parseReportData(Map<String, dynamic> data) {
    // Parse header info
    headerInfo = {
      'docNo': data['docNo'] ?? widget.orderNo,
      'docDate': data['docDt'] ?? data['docDate'] ?? '',
      'series': data['series'] ?? '',
      'partyName': data['partyName'] ?? data['party'] ?? '',
      'partyStation': data['partyStation'] ?? data['station'] ?? '',
    };

    // Parse party details
    partyDetails = {
      'party': data['party'] ?? data['partyName'] ?? '',
      'partyStation': data['partyStation'] ?? data['station'] ?? '',
      'partyAddress': data['partyAddress'] ?? '',
      'destination': data['destination'] ?? '',
      'deliveryMode': data['deliveryMode'] ?? '',
      'consignee': data['consignee'] ?? '',
      'consigneeAddress': data['consigneeAddress'] ?? '',
      'consigneePerson': data['consigneePerson'] ?? '',
      'refNo': data['refNo'] ?? '',
    };

    // Parse dispatch details
    dispatchDetails = {
      'packingNo': data['packingNo'] ?? '',
      'packingDate': data['packingDate'] ?? '',
      'orderNo': data['orderNo'] ?? '',
      'orderDate': data['orderDate'] ?? '',
      'transporter': data['transporter'] ?? '',
      'lrNo': data['lrNo'] ?? '',
      'lrDate': data['lrDate'] ?? '',
      'discTerm': data['discTerm'] ?? '',
      'dueDt': data['dueDt'] ?? '',
      'vehicleNo': data['vehicleNo'] ?? '',
      'concPerson': data['concPerson'] ?? '',
      'pytDays': data['pytDays'] ?? '',
      'ourOrderNo': data['ourOrderNo'] ?? '',
    };

    // Parse other details
    otherDetails = {
      'salesPerson': data['salesPerson'] ?? '',
      'commPercent': data['commPercent'] ?? '0',
      'broker': data['broker'] ?? '',
      'brokerComm': data['brokerComm'] ?? '0',
      'cartonNo': data['cartonNo'] ?? '',
      'grossWgt': data['grossWgt'] ?? '0',
      'currency': data['currency'] ?? 'INR',
      'nettWgt': data['nettWgt'] ?? '0',
      'votWgt': data['votWgt'] ?? '0',
      'eWayBillNo': data['eWayBillNo'] ?? '',
      'formType': data['formType'] ?? '',
      'freight': data['freight'] ?? '0',
      'trspMode': data['trspMode'] ?? '',
      'rtgsDetails': data['rtgsDetails'] ?? '',
      'portOfDisc': data['portOfDisc'] ?? '',
    };

    // Parse amount summary
    amountSummary = {
      'grossAmt': data['grossAmt'] ?? 0.0,
      'disc': data['disc'] ?? 0.0,
      'taxAmt': data['taxAmt'] ?? 0.0,
      'otherChrgs': data['otherChrgs'] ?? 0.0,
      'netAmt': data['netAmt'] ?? 0.0,
      'rdOff': data['rdOff'] ?? false,
      'roundOffAmount': data['roundOffAmount'] ?? 0.0,
    };

    // Parse items
    items = data['items'] ?? [];
  }

  Future<void> _downloadPDF() async {
    setState(() {
      isDownloading = true;
    });

    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            setState(() => isDownloading = false);
            return;
          }
        }
      }

      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.Pdf_url}',
        data: {
          "doc_id": widget.orderId,
          "rptName": "SaleBillGST",
          "dbName": UserSession.dbName,
          "dbUser": UserSession.dbUser,
          "dbPassword": UserSession.dbPassword,
          "dbServer": UserSession.dbSourceForRpt,
          "rptPath": UserSession.rptPath,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        Directory? directory;
        String filePath;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          filePath = '${directory.path}/SaleBill_${widget.orderNo}.pdf';
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
          filePath = '${directory.path}/SaleBill_${widget.orderNo}.pdf';
        } else {
          throw Exception('Unsupported platform');
        }

        final file = File(filePath);
        await file.writeAsBytes(response.data, flush: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF downloaded to $filePath'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () async {
                  final result = await OpenFile.open(filePath);
                  if (result.type != ResultType.done && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to open PDF: ${result.message}')),
                    );
                  }
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download PDF: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  Future<void> _shareWhatsApp() async {
    final TextEditingController controller = TextEditingController(
      text: widget.defaultWhatsAppMobileNo ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Text(
              'WhatsApp',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter WhatsApp Number',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: 'Enter 10-digit number',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              String number = controller.text.trim();
              if (number.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(number)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 10-digit number')),
                );
                return;
              }
              Navigator.pop(context);
              await _sendWhatsAppPDF(number);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppPDF(String number) async {
    setState(() => isDownloading = true);

    try {
      final dio = Dio();
      final response = await dio.post(
        '${AppConstants.Pdf_url}',
        data: {
          "doc_id": widget.orderId,
          "rptName": "SaleBillGST",
          "dbName": UserSession.dbName,
          "dbUser": UserSession.dbUser,
          "dbPassword": UserSession.dbPassword,
          "dbServer": UserSession.dbSourceForRpt,
          "rptPath": UserSession.rptPath,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        bool sent = await _sendWhatsAppFile(
          fileBytes: response.data,
          mobileNo: number,
          caption: 'Sale Bill - ${widget.orderNo}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sent ? 'Sent on WhatsApp' : 'Failed to send'),
              backgroundColor: sent ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDownloading = false);
      }
    }
  }

  Future<bool> _sendWhatsAppFile({
    required List<int> fileBytes,
    required String mobileNo,
    String? caption,
  }) async {
    try {
      String fileBase64 = base64Encode(fileBytes);

      final response = await http.post(
        Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
        body: {
          'data': fileBase64,
          'filename': 'SaleBill_${widget.orderNo}.pdf',
          'key': AppConstants.whatsappKey,
          'number': '91$mobileNo',
          'caption': caption ?? 'Please find the Sale Bill attached.',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending file: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Sale Bill Report',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isLoading && reportData.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: isDownloading ? null : _downloadPDF,
              tooltip: 'Download PDF',
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
              onPressed: isDownloading ? null : _shareWhatsApp,
              tooltip: 'Share on WhatsApp',
            ),
          ],
        ],
      ),
      body: isLoading
          ? _buildLoadingIndicator()
          : errorMessage != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      
                      // Party Details Card
                      _buildSectionCard('Party Details', partyDetails, [
                        'party', 'partyStation', 'partyAddress', 'destination',
                        'deliveryMode', 'consignee', 'consigneeAddress', 'consigneePerson', 'refNo'
                      ]),
                      const SizedBox(height: 16),
                      
                      // Dispatch Details Card
                      if (dispatchDetails['packingNo'] != null && dispatchDetails['packingNo'] != '')
                        _buildSectionCard('Dispatch Details', dispatchDetails, [
                          'packingNo', 'packingDate', 'orderNo', 'orderDate',
                          'transporter', 'lrNo', 'lrDate', 'discTerm', 'dueDt',
                          'vehicleNo', 'concPerson', 'pytDays', 'ourOrderNo'
                        ]),
                      
                      // Items Card
                      _buildItemsCard(),
                      const SizedBox(height: 16),
                      
                      // Other Details Card
                      _buildSectionCard('Other Details', otherDetails, [
                        'salesPerson', 'commPercent', 'broker', 'brokerComm',
                        'cartonNo', 'grossWgt', 'currency', 'nettWgt', 'votWgt',
                        'eWayBillNo', 'formType', 'freight', 'trspMode', 'rtgsDetails', 'portOfDisc'
                      ]),
                      const SizedBox(height: 16),
                      
                      // Amount Summary Card
                      _buildAmountSummaryCard(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading report data...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Report',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchReportData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.6),
                      AppColors.primaryColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long,
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
                              'Sale Bill ${headerInfo['docNo'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Date: ${headerInfo['docDate'] ?? ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Party', headerInfo['partyName'] ?? ''),
                      ),
                      Expanded(
                        child: _buildInfoRow('Station', headerInfo['partyStation'] ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Map<String, dynamic> data, List<String> keys) {
    // Filter out empty values
    final visibleKeys = keys.where((key) {
      final value = data[key];
      return value != null && value.toString().isNotEmpty && value != '0';
    }).toList();

    if (visibleKeys.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 16,
              ),
              itemCount: visibleKeys.length,
              itemBuilder: (context, index) {
                final key = visibleKeys[index];
                final label = _getLabelForKey(key);
                final value = data[key].toString();
                return _buildInfoRow(label, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemCard(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['Product'] ?? item['itemName'] ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Qty: ${item['Qty'] ?? 0}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildItemDetail('Rate', '₹${item['Rate'] ?? 0}'),
              _buildItemDetail('MRP', '₹${item['MRP'] ?? 0}'),
              _buildItemDetail('Amount', '₹${item['Amount'] ?? 0}'),
            ],
          ),
          if (item['sizes'] != null && (item['sizes'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Size-wise Details',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: (item['sizes'] as List).map((size) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${size['Size_Name'] ?? size['size']}: ${size['Qty']}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.blue[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemDetail(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount Summary',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildSummaryRow('Gross Amount', amountSummary['grossAmt'] ?? 0.0),
            _buildSummaryRow('Discount', amountSummary['disc'] ?? 0.0),
            _buildSummaryRow('Tax Amount', amountSummary['taxAmt'] ?? 0.0),
            _buildSummaryRow('Other Charges', amountSummary['otherChrgs'] ?? 0.0),
            if (amountSummary['rdOff'] == true)
              _buildSummaryRow('Round Off', amountSummary['roundOffAmount'] ?? 0.0),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Net Amount',
              amountSummary['netAmt'] ?? 0.0,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.primaryColor : Colors.grey.shade700,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.primaryColor : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  String _getLabelForKey(String key) {
    final labels = {
      'party': 'Party',
      'partyStation': 'Station',
      'partyAddress': 'Address',
      'destination': 'Destination',
      'deliveryMode': 'Delivery Mode',
      'consignee': 'Consignee',
      'consigneeAddress': 'Consignee Address',
      'consigneePerson': 'Contact Person',
      'refNo': 'Reference No',
      'packingNo': 'Packing No',
      'packingDate': 'Packing Date',
      'orderNo': 'Order No',
      'orderDate': 'Order Date',
      'transporter': 'Transporter',
      'lrNo': 'LR No',
      'lrDate': 'LR Date',
      'discTerm': 'Discount Term',
      'dueDt': 'Due Date',
      'vehicleNo': 'Vehicle No',
      'concPerson': 'Concern Person',
      'pytDays': 'Payment Days',
      'ourOrderNo': 'Our Order No',
      'salesPerson': 'Salesperson',
      'commPercent': 'Commission %',
      'broker': 'Broker',
      'brokerComm': 'Broker Commission',
      'cartonNo': 'Carton No',
      'grossWgt': 'Gross Weight',
      'currency': 'Currency',
      'nettWgt': 'Net Weight',
      'votWgt': 'VOT Weight',
      'eWayBillNo': 'E-Way Bill No',
      'formType': 'Form Type',
      'freight': 'Freight',
      'trspMode': 'Transport Mode',
      'rtgsDetails': 'RTGS Details',
      'portOfDisc': 'Port of Discharge',
    };
    return labels[key] ?? key;
  }
}