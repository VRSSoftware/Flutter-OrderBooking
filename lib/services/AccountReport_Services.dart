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
      };
      
      // Add ledKey if provided
      if (ledKey != null && ledKey.isNotEmpty) {
        requestBody["ledKey"] = ledKey;
      }
      
      // Add any additional parameters
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
          debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
          return response.bodyBytes;
        } else {
          final responseData = jsonDecode(response.body);
          throw Exception(responseData['message'] ?? 'Failed to generate report');
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
  static Future<String> savePdfToTemp(Uint8List pdfBytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Save PDF to permanent storage
  static Future<String> savePdfPermanently(Uint8List pdfBytes, String fileName) async {
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
        final List<KeyName> ledgers = data.map((item) {
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
  required List<String> ledgerKeys,  // Empty list = all ledgers
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
        throw Exception(responseData['message'] ?? 'Failed to generate cash book report');
      }
    } else {
      throw Exception('Failed to load cash book report: ${response.statusCode}');
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
        final List<KeyName> ledgers = data.map((item) {
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
  required List<String> ledgerKeys,  // Empty list = all ledgers
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
        throw Exception(responseData['message'] ?? 'Failed to generate bank book report');
      }
    } else {
      throw Exception('Failed to load bank book report: ${response.statusCode}');
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
          key: item['AccLGrp_Key'],
          name: item['AccLGrp_Name'],
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
  List<String>? groupKeys,      // Changed from String? groupKey
  List<String>? subGroupKeys,   // Changed from String? subGroupKey
  required String reportType,
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": "groupSummary",
      "report_type": reportType,
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
      final formattedSubGroupKeys = subGroupKeys.map((key) => "'$key'").join(',');
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
        throw Exception(responseData['message'] ?? 'Failed to generate group summary report');
      }
    } else {
      throw Exception('Failed to load group summary report: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error generating group summary report: $e');
    throw Exception('Error generating group summary report: $e');
  }
}

static Future<Uint8List?> generateGroupVoucherReport({
  required String fromDate,
  required String toDate,
  List<String>? groupKeys,      // Changed to List
  List<String>? subGroupKeys,   // Changed to List
  required String reportType, // 'summary' or 'detail'
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    // Build the request body with proper structure
    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": "groupVoucher",  // Report type for group voucher
      "report_type": reportType,
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
      final formattedSubGroupKeys = subGroupKeys.map((key) => "'$key'").join(',');
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
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate group voucher report');
      }
    } else {
      throw Exception('Failed to load group voucher report: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error generating group voucher report: $e');
    throw Exception('Error generating group voucher report: $e');
  }
}

static Future<List<KeyName>> fetchLedgersByFilters({
  String? ledCat,  // 'W' for customer, 'V' for vendor, 'L' for ledger, null for all
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
      
      final List<KeyName> ledgers = data.map((item) {
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
      final formattedSubGroupKeys = subGroupIds.map((key) => "'$key'").join(',');
      requestBody["AccLGrp_Keys"] = "[$formattedSubGroupKeys]";
    }

    debugPrint('========== GENERATE LEDGER REPORT ==========');
    debugPrint('Request Body: ${jsonEncode(requestBody)}');
    debugPrint('Ledger Type: $ledgerType -> ledCat: ${requestBody["ledCat"]}');

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.contains('application/pdf')) {
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate ledger report');
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
          key: item['City_Key'].toString(),
          name: item['City_Name'],
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
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate trial balance report');
      }
    } else {
      throw Exception('Failed to load trial balance report: ${response.statusCode}');
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
    };

    debugPrint('Request URL: ${AppConstants.BASE_URL}/accounts/getLedgerPdf');
    debugPrint('Request Body: ${jsonEncode(requestBody)}');
    debugPrint('Ledger Wise: $isLedgerWise');
    debugPrint('Report Type: ${isLedgerWise ? "profitLossLedgerwise" : "profitLoss"}');

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getLedgerPdf'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    debugPrint('Response Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];

      if (contentType != null && contentType.contains('application/pdf')) {
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate profit & loss report');
      }
    } else {
      throw Exception('Failed to load profit & loss report: ${response.statusCode}');
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
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate balance sheet report');
      }
    } else {
      throw Exception('Failed to load balance sheet report: ${response.statusCode}');
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
        final List<KeyName> ledgers = data.map((item) {
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
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate payable report');
      }
    } else {
      throw Exception('Failed to load payable report: ${response.statusCode}');
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
        final List<KeyName> ledgers = data.map((item) {
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
  required List<String> ledgerKeys,  // Empty list = all ledgers
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
        debugPrint('PDF received successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to generate receivable report');
      }
    } else {
      throw Exception('Failed to load receivable report: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error generating receivable report: $e');
    throw Exception('Error generating receivable report: $e');
  }
}
}