import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/keyName.dart';

class AccountReportService {
  static Future<Uint8List?> generateDayBookReport({
    required String reportType,
    required String fromDate,
    required String toDate,
    String? ledKey,
    Map<String, dynamic>? additionalParams,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": reportType,
        "coBr": UserSession.coBrId,
      };

      if (ledKey != null && ledKey.isNotEmpty) {
        requestBody["ledKey"] = ledKey;
      }

      if (additionalParams != null) {
        requestBody.addAll(additionalParams);
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ?? 'Failed to generate report',
          );
        }
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating report: $e');
      throw Exception('Error generating report: $e');
    }
  }

  /// Save PDF to temporary directory and return file path
  static Future<String> savePdfToTemp(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Save PDF to permanent storage
  static Future<String> savePdfPermanently(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  static Future<List<KeyName>> fetchCashBookLedgers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerCashBook/011'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key'].toString(),
                name: item['Led_Name'].toString(),
              );
            }).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load cash book ledgers');
      }
    } catch (e) {
      debugPrint('Error fetching cash book ledgers: $e');
      throw Exception('Error fetching cash book ledgers: $e');
    }
  }

  static Future<Uint8List?> generateCashBookReport({
    required String fromDate,
    required String toDate,
    required List<String> ledgerKeys, // Empty list = all ledgers
    required String reportType,
    required bool showNarration,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "cashBook",
        "report_type": reportType,
        "showNarration": showNarration,
        "coBr": UserSession.coBrId,
      };

      // Only add led_keys if not empty
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/pdf')) {
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ?? 'Failed to generate cash book report',
          );
        }
      } else {
        throw Exception(
          'Failed to load cash book report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating cash book report: $e');
      throw Exception('Error generating cash book report: $e');
    }
  }

  static Future<List<KeyName>> fetchBankBookLedgers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerCashBook/012'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key'].toString(),
                name: item['Led_Name'].toString(),
              );
            }).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load cash book ledgers');
      }
    } catch (e) {
      debugPrint('Error fetching cash book ledgers: $e');
      throw Exception('Error fetching cash book ledgers: $e');
    }
  }

  static Future<Uint8List?> generateBankBookReport({
    required String fromDate,
    required String toDate,
    required List<String> ledgerKeys, // Empty list = all ledgers
    required String reportType,
    required bool showNarration,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "bankBook",
        "report_type": reportType,
        "show_narration": showNarration,
        "coBr": UserSession.coBrId,
      };

      // Only add led_keys if not empty
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/pdf')) {
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ?? 'Failed to generate bank book report',
          );
        }
      } else {
        throw Exception(
          'Failed to load bank book report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating bank book report: $e');
      throw Exception('Error generating bank book report: $e');
    }
  }

  static Future<List<KeyName>> fetchAccountGroups() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getAccGrp'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((item) {
          return KeyName(
            key: item['AccGrp_Id'].toString(),
            name: item['AccGrp_Name'],
          );
        }).toList();
      } else {
        throw Exception('Failed to load groups');
      }
    } catch (e) {
      throw Exception('Error fetching groups: $e');
    }
  }
static Future<List<KeyName>> fetchAccountSubGroups() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getAccLGrp'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) {
        return KeyName(
          key: item['AccLGrp_Key'].toString(),
          name: item['AccLGrp_Name'],
          extra: {
            'AccGrp_Id': item['AccGrp_Id']?.toString() ?? '',
          },
        );
      }).toList();
    } else {
      throw Exception('Failed to load sub groups');
    }
  } catch (e) {
    throw Exception('Error fetching sub groups: $e');
  }
}
  static Future<Uint8List?> generateGroupSummaryReport({
    required String fromDate,
    required String toDate,
    List<String>? groupKeys, // Changed from String? groupKey
    List<String>? subGroupKeys, // Changed from String? subGroupKey
    required String reportType,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "groupSummary",
        "report_type": reportType,
        "coBr": UserSession.coBrId,
      };

      // Add AccGrp_Ids for multiple groups (numeric IDs, no quotes)
      if (groupKeys != null && groupKeys.isNotEmpty) {
        final formattedGroupIds = groupKeys.join(',');
        requestBody["AccGrp_Ids"] = "[$formattedGroupIds]";
      } else {
        requestBody["AccGrp_Ids"] = null;
      }

      // Add AccLGrp_Keys for multiple sub groups (string IDs with quotes)
      if (subGroupKeys != null && subGroupKeys.isNotEmpty) {
        final formattedSubGroupKeys = subGroupKeys
            .map((key) => "'$key'")
            .join(',');
        requestBody["AccLGrp_Keys"] = "[$formattedSubGroupKeys]";
      } else {
        requestBody["AccLGrp_Keys"] = null;
      }

      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/pdf')) {
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ??
                'Failed to generate group summary report',
          );
        }
      } else {
        throw Exception(
          'Failed to load group summary report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating group summary report: $e');
      throw Exception('Error generating group summary report: $e');
    }
  }

  static Future<Uint8List?> generateGroupVoucherReport({
    required String fromDate,
    required String toDate,
    List<String>? groupKeys, // Changed to List
    List<String>? subGroupKeys, // Changed to List
    required String reportType, // 'summary' or 'detail'
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body with proper structure
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "groupVoucher", // Report type for group voucher
        "report_type": reportType,
        "coBr": UserSession.coBrId,
      };

      // Add AccGrp_Ids for multiple groups (numeric IDs, no quotes)
      if (groupKeys != null && groupKeys.isNotEmpty) {
        final formattedGroupIds = groupKeys.join(',');
        requestBody["AccGrp_Ids"] = "[$formattedGroupIds]";
      } else {
        requestBody["AccGrp_Ids"] = null;
      }

      // Add AccLGrp_Keys for multiple sub groups (string IDs with quotes)
      if (subGroupKeys != null && subGroupKeys.isNotEmpty) {
        final formattedSubGroupKeys = subGroupKeys
            .map((key) => "'$key'")
            .join(',');
        requestBody["AccLGrp_Keys"] = "[$formattedSubGroupKeys]";
      } else {
        requestBody["AccLGrp_Keys"] = null;
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Group Keys (AccGrp_Ids): $groupKeys');
      debugPrint('Sub Group Keys (AccLGrp_Keys): $subGroupKeys');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ??
                'Failed to generate group voucher report',
          );
        }
      } else {
        throw Exception(
          'Failed to load group voucher report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating group voucher report: $e');
      throw Exception('Error generating group voucher report: $e');
    }
  }

  static Future<List<KeyName>> fetchLedgersByFilters({
    String?
    ledCat, // 'W' for customer, 'V' for vendor, 'L' for ledger, null for all
  }) async {
    try {
      final Map<String, dynamic> requestBody = {};

      // Only add ledCat if provided and not null
      if (ledCat != null && ledCat.isNotEmpty) {
        requestBody["ledCat"] = ledCat;
      }

      print('========== FETCH LEDGERS API CALL ==========');
      print('URL: ${AppConstants.BASE_URL}/accounts/getLedgerByLedCat');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('ledCat value: $ledCat');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerByLedCat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print('Parsed data length: ${data.length}');

        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key']?.toString() ?? '',
                name: item['Led_Name']?.toString() ?? '',
              );
            }).toList();

        print('Ledgers count: ${ledgers.length}');
        ledgers.forEach((ledger) {
          print('Ledger: ${ledger.key} - ${ledger.name}');
        });

        return ledgers;
      } else {
        throw Exception('Failed to load ledgers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ledgers: $e');
      throw Exception('Error fetching ledgers: $e');
    }
  }

  static Future<Uint8List?> generateLedgerReport({
    required String fromDate,
    required String toDate,
    required String ledgerType, // 'customer', 'vendor', 'ledger', 'all'
    required List<String> ledgerKeys,
    required List<String> stateIds,
    required List<String> cityIds,
    required List<String> groupIds,
    required List<String> subGroupIds,
    required String reportType,
    required bool isBillWise,
    required bool isNarration,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "ledger",
        "report_type": reportType,
        "showBillWise": isBillWise,
      };

      // Map ledger type to ledCat parameter
      // Default is "L" for ledger
      if (ledgerType == 'customer') {
        requestBody["ledCat"] = "W";
      } else if (ledgerType == 'vendor') {
        requestBody["ledCat"] = "V";
      } else if (ledgerType == 'ledger') {
        requestBody["ledCat"] = "L";
      } else if (ledgerType == 'all') {
        requestBody["ledCat"] = "ALL";
      }

      // Add selected ledger keys (format as "['0157','01100','01110']")
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      // Add state keys (format as "['011','061']")
      if (stateIds.isNotEmpty) {
        final formattedStateKeys = stateIds.map((key) => "'$key'").join(',');
        requestBody["State_Keys"] = "[$formattedStateKeys]";
      }

      // Add city keys
      if (cityIds.isNotEmpty) {
        final formattedCityKeys = cityIds.map((key) => "'$key'").join(',');
        requestBody["City_Keys"] = "[$formattedCityKeys]";
      }

      // Add group IDs (format as "[13,12,56]")
      if (groupIds.isNotEmpty) {
        final formattedGroupIds = groupIds.join(',');
        requestBody["AccGrp_Ids"] = "[$formattedGroupIds]";
      }

      // Add sub group keys (format as "['0121','0151']")
      if (subGroupIds.isNotEmpty) {
        final formattedSubGroupKeys = subGroupIds
            .map((key) => "'$key'")
            .join(',');
        requestBody["AccLGrp_Keys"] = "[$formattedSubGroupKeys]";
      }

      debugPrint('========== GENERATE LEDGER REPORT ==========');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint(
        'Ledger Type: $ledgerType -> ledCat: ${requestBody["ledCat"]}',
      );

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ?? 'Failed to generate ledger report',
          );
        }
      } else {
        throw Exception('Failed to load ledger report: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating ledger report: $e');
      throw Exception('Error generating ledger report: $e');
    }
  }

  static Future<List<KeyName>> fetchStates() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getState'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) {
          return KeyName(
            key: item['State_Key'].toString(),
            name: item['State_Name'],
          );
        }).toList();
      } else {
        throw Exception('Failed to load states');
      }
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }

  // Fetch Cities
static Future<List<KeyName>> fetchCities() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getCity'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) {
        return KeyName(
          key: item['Stn_Key'].toString(),
          name: item['Stn_Name'],
          extra: {
            'State_Key': item['State_Key'].toString(),
          },
        );
      }).toList();
    } else {
      throw Exception('Failed to load cities');
    }
  } catch (e) {
    throw Exception('Error fetching cities: $e');
  }
}

  static Future<Uint8List?> generateTrialBalanceReport({
    required String fromDate,
    required String toDate,
    required String reportType, // 'summary' or 'detail'
    required bool isLedgerWise,
    required bool isDueOnly,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "trialBalance",
        "report_type": reportType,
        "showLedgerWise": isLedgerWise ? "1" : "0",
        "showDueOnly": isDueOnly ? "1" : "0",
        "coBr": UserSession.coBrId,
      };

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ??
                'Failed to generate trial balance report',
          );
        }
      } else {
        throw Exception(
          'Failed to load trial balance report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating trial balance report: $e');
      throw Exception('Error generating trial balance report: $e');
    }
  }

  static Future<Uint8List?> generateProfitLossReport({
    required String fromDate,
    required String toDate,
    required bool isLedgerWise,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": isLedgerWise ? "profitLossLedgerwise" : "profitLoss",
        "coBr": UserSession.coBrId,
      };

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Ledger Wise: $isLedgerWise');
      debugPrint(
        'Report Type: ${isLedgerWise ? "profitLossLedgerwise" : "profitLoss"}',
      );

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ??
                'Failed to generate profit & loss report',
          );
        }
      } else {
        throw Exception(
          'Failed to load profit & loss report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating profit & loss report: $e');
      throw Exception('Error generating profit & loss report: $e');
    }
  }

  static Future<Uint8List?> generateBalanceSheetReport({
    required String fromDate,
    required String toDate,
    required bool isLedgerWise,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "balanceSheet",
        "coBr": UserSession.coBrId,
      };

      // Add ledger wise flag if checked
      if (isLedgerWise) {
        requestBody["showLedgerWise"] = "1";
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Ledger Wise: $isLedgerWise');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ??
                'Failed to generate balance sheet report',
          );
        }
      } else {
        throw Exception(
          'Failed to load balance sheet report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating balance sheet report: $e');
      throw Exception('Error generating balance sheet report: $e');
    }
  }

  static Future<List<KeyName>> fetchPayablesLedgers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPayable'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key'].toString(),
                name: item['Led_Name'].toString(),
              );
            }).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load cash book ledgers');
      }
    } catch (e) {
      debugPrint('Error fetching cash book ledgers: $e');
      throw Exception('Error fetching cash book ledgers: $e');
    }
  }

  static Future<Uint8List?> generatePayableReport({
    required String fromDate,
    required String toDate,
    required List<String> ledgerKeys,
    required String reportType, // 'summary' or 'detail'
    required bool isOverdueOnly,
    required bool isAgeWise,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Determine report name based on isAgeWise
      final reportName = isAgeWise ? "payables_ageWise" : "payables";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": reportName,
        "report_type": reportType,
        "overDueOnly": isOverdueOnly,
        "coBr": UserSession.coBrId,
      };

      // Add ledger keys if provided (format as "['01100','01110']")
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Ledger Keys: $ledgerKeys');
      debugPrint('Overdue Only: $isOverdueOnly');
      debugPrint('Age Wise: $isAgeWise');
      debugPrint('Report Name: $reportName');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ?? 'Failed to generate payable report',
          );
        }
      } else {
        throw Exception(
          'Failed to load payable report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating payable report: $e');
      throw Exception('Error generating payable report: $e');
    }
  }

  static Future<List<KeyName>> fetchReceivablesLedgers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerReceivable'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key'].toString(),
                name: item['Led_Name'].toString(),
              );
            }).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load cash book ledgers');
      }
    } catch (e) {
      debugPrint('Error fetching cash book ledgers: $e');
      throw Exception('Error fetching cash book ledgers: $e');
    }
  }

  static Future<Uint8List?> generateReceivableReport({
    required String fromDate,
    required String toDate,
    required List<String> ledgerKeys, // Empty list = all ledgers
    required String reportType, // 'summary' or 'detail'
    required bool isOverdueOnly,
    required bool isAgeWise,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Determine report type based on isAgeWise
      final reportName = isAgeWise ? "receivables_ageWise" : "receivables";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": reportName,
        "report_type": reportType,
        "coBr": UserSession.coBrId,
      };

      // Add ledger keys if provided (format as "['01100','01110']")
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      // Add overdue only flag (boolean)
      requestBody["overDueOnly"] = isOverdueOnly;

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Ledger Keys: $ledgerKeys');
      debugPrint('Overdue Only: $isOverdueOnly');
      debugPrint('Age Wise: $isAgeWise');
      debugPrint('Report Name: $reportName');

      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(
            responseData['message'] ?? 'Failed to generate receivable report',
          );
        }
      } else {
        throw Exception(
          'Failed to load receivable report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating receivable report: $e');
      throw Exception('Error generating receivable report: $e');
    }
  }

  //broker commissin apis

  static Future<List<KeyName>> fetchLedgersByCategory(String category) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerByCategory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'led_cat':
              category, // 'B' for Broker, 'C' for Customer, 'ALL' for all
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key'].toString(),
                name: item['Led_Name'].toString(),
              );
            }).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load ledgers for category: $category');
      }
    } catch (e) {
      debugPrint('Error fetching ledgers for category $category: $e');
      throw Exception('Error fetching ledgers for category $category: $e');
    }
  }

  // Fetch ledgers for broker commission
  static Future<List<KeyName>> fetchBrokerLedgers() async {
    return fetchLedgersByCategory('W');
  }

  static Future<List<KeyName>> fetchBrokers() async {
    return fetchLedgersByCategory('B');
  }

  // Generate Broker Commission Receipt Report (Bill Wise)
  static Future<Uint8List?> generateBrokerCommissionReceiptReport({
    required String fromDate,
    required String toDate,
    required List<String> brokerKeys, // Empty list = all brokers
    required List<String> stateKeys, // Empty list = all states
    required List<String> cityKeys, // Empty list = all cities
    required List<String> ledgerKeys, // Empty list = all ledgers
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "broker_comm_rcpt_billwise",
        "coBr": UserSession.coBrId,
      };

      // Add broker keys if provided (format as "['01100','01110']")
      if (brokerKeys.isNotEmpty) {
        final formattedBrokerKeys = brokerKeys.map((key) => "'$key'").join(',');
        requestBody["broker_keys"] = "[$formattedBrokerKeys]";
      }

      // Add state keys if provided
      if (stateKeys.isNotEmpty) {
        final formattedStateKeys = stateKeys.map((key) => "'$key'").join(',');
        requestBody["State_Keys"] = "[$formattedStateKeys]";
      }

      // Add city keys if provided
      if (cityKeys.isNotEmpty) {
        final formattedCityKeys = cityKeys.map((key) => "'$key'").join(',');
        requestBody["station_keys"] = "[$formattedCityKeys]";
      }

      // Add ledger keys if provided
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Report Name: broker_commission_receipt_billwise');
      debugPrint('Broker Keys: $brokerKeys');
      debugPrint('State Keys: $stateKeys');
      debugPrint('City Keys: $cityKeys');
      debugPrint('Ledger Keys: $ledgerKeys');

      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getLedgerPdf',
        ), // Same API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          // Try to parse error message from response
          try {
            final responseData = jsonDecode(response.body);
            throw Exception(
              responseData['message'] ??
                  'Failed to generate broker commission receipt report',
            );
          } catch (e) {
            throw Exception(
              'Failed to generate broker commission receipt report',
            );
          }
        }
      } else {
        throw Exception(
          'Failed to load broker commission receipt report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating broker commission receipt report: $e');
      throw Exception('Error generating broker commission receipt report: $e');
    }
  }

  //Outstanding Remainder Api
  // Fetch ledgers for outstanding remainder
  static Future<List<KeyName>> fetchOutstandingRemainderLedgers() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/outstandingRemainderLedgers',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> ledgers =
            data.map((item) {
              return KeyName(
                key: item['Led_Key'].toString(),
                name: item['Led_Name'].toString(),
              );
            }).toList();
        return ledgers;
      } else {
        throw Exception('Failed to load outstanding remainder ledgers');
      }
    } catch (e) {
      debugPrint('Error fetching outstanding remainder ledgers: $e');
      throw Exception('Error fetching outstanding remainder ledgers: $e');
    }
  }

  // Generate Outstanding Remainder Report
  static Future<Uint8List?> generateOutstandingRemainderReport({
    required String fromDate,
    required String toDate,
    required List<String> stateKeys, // Empty list = all states
    required List<String> cityKeys, // Empty list = all cities
    required List<String> ledgerKeys, // Empty list = all ledgers
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "Outstanding_Reminder", // Report name for outstanding remainder
        "coBr": UserSession.coBrId,
      };

      // Add state keys if provided (format as "['01100','01110']")
      if (stateKeys.isNotEmpty) {
        final formattedStateKeys = stateKeys.map((key) => "'$key'").join(',');
        requestBody["State_Keys"] = "[$formattedStateKeys]";
      }

      // Add city keys if provided
      if (cityKeys.isNotEmpty) {
        final formattedCityKeys = cityKeys.map((key) => "'$key'").join(',');
        requestBody["station_keys"] = "[$formattedCityKeys]";
      }

      // Add ledger keys if provided
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Report Name: outstanding_remainder');
      debugPrint('State Keys: $stateKeys');
      debugPrint('City Keys: $cityKeys');
      debugPrint('Ledger Keys: $ledgerKeys');

      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getLedgerPdf',
        ), // Same API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          // Try to parse error message from response
          try {
            final responseData = jsonDecode(response.body);
            throw Exception(
              responseData['message'] ??
                  'Failed to generate outstanding remainder report',
            );
          } catch (e) {
            throw Exception('Failed to generate outstanding remainder report');
          }
        }
      } else {
        throw Exception(
          'Failed to load outstanding remainder report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating outstanding remainder report: $e');
      throw Exception('Error generating outstanding remainder report: $e');
    }
  }

  //customer Ledger Api
  // Fetch customer ledgers
  static Future<List<KeyName>> fetchCustomerLedgers() async {
    return fetchLedgersByCategory('W');
  }

  // Generate Customer Ledger Report
  static Future<Uint8List?> generateCustomerLedgerReport({
    required String fromDate,
    required String toDate,
    required List<String> stateKeys,
    required List<String> cityKeys,
    required List<String> ledgerKeys,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "Customer_ledger",
        "coBr": UserSession.coBrId,
      };

      // Add state keys if provided (format as "['01100','01110']")
      if (stateKeys.isNotEmpty) {
        final formattedStateKeys = stateKeys.map((key) => "'$key'").join(',');
        requestBody["State_Keys"] = "[$formattedStateKeys]";
      }

      // Add city keys if provided
      if (cityKeys.isNotEmpty) {
        final formattedCityKeys = cityKeys.map((key) => "'$key'").join(',');
        requestBody["station_keys"] = "[$formattedCityKeys]";
      }

      // Add ledger keys if provided
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Report Name: customer_ledger');
      debugPrint('State Keys: $stateKeys');
      debugPrint('City Keys: $cityKeys');
      debugPrint('Ledger Keys: $ledgerKeys');

      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getLedgerPdf',
        ), // Same API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          // Try to parse error message from response
          try {
            final responseData = jsonDecode(response.body);
            throw Exception(
              responseData['message'] ??
                  'Failed to generate customer ledger report',
            );
          } catch (e) {
            throw Exception('Failed to generate customer ledger report');
          }
        }
      } else {
        throw Exception(
          'Failed to load customer ledger report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating customer ledger report: $e');
      throw Exception('Error generating customer ledger report: $e');
    }
  }

  // Generate Customer Billwise Report
  static Future<Uint8List?> generateCustomerBillwiseReport({
    required String fromDate,
    required String toDate,
    required List<String> stateKeys, // Empty list = all states
    required List<String> cityKeys, // Empty list = all cities
    required List<String> ledgerKeys, // Empty list = all ledgers
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";

      // Build the request body
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "report": "Customer_AC_Billwise", // Report name for customer billwise
        "coBr": UserSession.coBrId,
      };

      // Add state keys if provided (format as "['01100','01110']")
      if (stateKeys.isNotEmpty) {
        final formattedStateKeys = stateKeys.map((key) => "'$key'").join(',');
        requestBody["State_Keys"] = "[$formattedStateKeys]";
      }

      // Add city keys if provided
      if (cityKeys.isNotEmpty) {
        final formattedCityKeys = cityKeys.map((key) => "'$key'").join(',');
        requestBody["station_keys"] = "[$formattedCityKeys]";
      }

      // Add ledger keys if provided
      if (ledgerKeys.isNotEmpty) {
        final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
        requestBody["led_keys"] = "[$formattedLedgerKeys]";
      }

      debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      debugPrint('Report Name: customer_ledger_billwise');
      debugPrint('State Keys: $stateKeys');
      debugPrint('City Keys: $cityKeys');
      debugPrint('Ledger Keys: $ledgerKeys');

      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getLedgerPdf',
        ), // Same API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          debugPrint(
            'PDF received successfully, size: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        } else {
          // Try to parse error message from response
          try {
            final responseData = jsonDecode(response.body);
            throw Exception(
              responseData['message'] ??
                  'Failed to generate customer billwise report',
            );
          } catch (e) {
            throw Exception('Failed to generate customer billwise report');
          }
        }
      } else {
        throw Exception(
          'Failed to load customer billwise report: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error generating customer billwise report: $e');
      throw Exception('Error generating customer billwise report: $e');
    }
  }


  // Add this method to your AccountReportService class

static Future<Uint8List?> generateGroupTrialBalanceReport({
  required String fromDate,
  required String toDate,
  required List<String> groupKeys,
  required List<String> subGroupKeys,
  required List<String> ledgerKeys,
  required String reportType, // 'summary' or 'detail'
  required bool isLedgerWise,
  required bool isDueOnly,
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    // Build the request body
    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": "trialBalance", // Report name for group trial balance
      "report_type": reportType,
      "showLedgerWise": isLedgerWise ? "1" : "0",
      "showDueOnly": isDueOnly ? "1" : "0",
      "coBr": UserSession.coBrId,
    };

    // Add group keys (AccGrp_Ids - numeric IDs, no quotes)
    if (groupKeys.isNotEmpty) {
      final formattedGroupIds = groupKeys.join(',');
      requestBody["AccGrp_Ids"] = "[$formattedGroupIds]";
    }

    // Add sub group keys (AccLGrp_Keys - string IDs with quotes)
    if (subGroupKeys.isNotEmpty) {
      final formattedSubGroupKeys = subGroupKeys.map((key) => "'$key'").join(',');
      requestBody["AccLGrp_Keys"] = "[$formattedSubGroupKeys]";
    }

    // Add ledger keys (format as "['01100','01110']")
    if (ledgerKeys.isNotEmpty) {
      final formattedLedgerKeys = ledgerKeys.map((key) => "'$key'").join(',');
      requestBody["led_keys"] = "[$formattedLedgerKeys]";
    }

    debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
    debugPrint('Request Body: ${jsonEncode(requestBody)}');
    debugPrint('Report Name: group_trial_balance');
    debugPrint('Group Keys: $groupKeys');
    debugPrint('Sub Group Keys: $subGroupKeys');
    debugPrint('Ledger Keys: $ledgerKeys');
    debugPrint('Report Type: $reportType');
    debugPrint('Ledger Wise: $isLedgerWise');
    debugPrint('Due Only: $isDueOnly');

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];

      if (contentType != null && contentType.contains('application/pdf')) {
        debugPrint(
          'PDF received successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(
          responseData['message'] ?? 'Failed to generate group trial balance report',
        );
      }
    } else {
      throw Exception(
        'Failed to load group trial balance report: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('Error generating group trial balance report: $e');
    throw Exception('Error generating group trial balance report: $e');
  }
}

// Add this method to AccountReportService class


static Future<Uint8List?> generateJournalRegisterReport({
  required String fromDate,
  required String toDate,
  required String reportType,
  required bool isBillWise,
  required bool isNarration,
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    // Dynamic report name
    final String reportName =
        isBillWise
            ? "JournalRegisterBillWise"
            : "JournalRegister";

    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": reportName,
      "report_type": reportType,
      "showBillWise": isBillWise,
      "showNarration": isNarration,
      "coBr": UserSession.coBrId,
    };

    debugPrint(
      'Request URL: ${AppConstants.BASE_URL}/accounts/getAccReports',
    );
    debugPrint('Request Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getAccReports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];

      if (contentType != null &&
          contentType.contains('application/pdf')) {
        debugPrint(
          'PDF received successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(
          responseData['message'] ??
              'Failed to generate journal register report',
        );
      }
    } else {
      throw Exception(
        'Failed to load journal register report: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('Error generating journal register report: $e');
    throw Exception('Error generating journal note register report: $e');
  }
}

// Add this method to AccountReportService class

static Future<Uint8List?> generateDebitNoteRegisterReport({
  required String fromDate,
  required String toDate,
  required String reportType,
  required bool isBillWise,
  required bool isNarration,
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    // Dynamic report name
    final String reportName =
        isBillWise
            ? "debitNoteRegisterBillWise"
            : "debitNoteRegister";

    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": reportName,
      "report_type": reportType,
      "showBillWise": isBillWise,
      "showNarration": isNarration,
      "coBr": UserSession.coBrId,
    };

    debugPrint(
      'Request URL: ${AppConstants.BASE_URL}/accounts/getAccReports',
    );
    debugPrint('Request Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getAccReports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];

      if (contentType != null &&
          contentType.contains('application/pdf')) {
        debugPrint(
          'PDF received successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(
          responseData['message'] ??
              'Failed to generate debit note register report',
        );
      }
    } else {
      throw Exception(
        'Failed to load debit note register report: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('Error generating debit note register report: $e');
    throw Exception('Error generating debit note register report: $e');
  }
}


// Add this method to AccountReportService class

static Future<Uint8List?> generateCreditNoteRegisterReport({
  required String fromDate,
  required String toDate,
  required String reportType,
  required bool isBillWise,
  required bool isNarration,
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    // Dynamic report name
    final String reportName =
        isBillWise
          ? "CreditNoteRegisterBillWise"
        : "CreditNoteRegister";

    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": reportName,
      "report_type": reportType,
      "showBillWise": isBillWise,
      "showNarration": isNarration,
      "coBr": UserSession.coBrId,
    };

    debugPrint(
      'Request URL: ${AppConstants.BASE_URL}/accounts/getAccReports',
    );
    debugPrint('Request Body: ${jsonEncode(requestBody)}');

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getAccReports'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];

      if (contentType != null &&
          contentType.contains('application/pdf')) {
        debugPrint(
          'PDF received successfully, size: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(
          responseData['message'] ??
              'Failed to generate credit note register report',
        );
      }
    } else {
      throw Exception(
        'Failed to load credit note register report: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('Error generating credit note register report: $e');
    throw Exception('Error generating credit note register report: $e');
  }
}
}
