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
    required String ledKey,
    required String reportType, // 'summary' or 'detail'
    required bool showNarration,
  }) async {
    try {
      final dateRange = "$fromDate to $toDate";
      
      final Map<String, dynamic> requestBody = {
        "date_range": dateRange,
        "ledKey": ledKey,
        "report_type": reportType,
        "show_narration": showNarration,
        "report": "cashbook",
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

static Future<Uint8List?> generateLedgerReport({
  required String fromDate,
  required String toDate,
  required String ledgerType, // 'all', 'customer', 'vendor'
  required List<String> stateIds,
  required List<String> cityIds,
  required List<String> groupIds,
  required List<String> subGroupIds,
  required String reportType, // 'summary' or 'detail'
  required bool isBillWise,
  required bool isNarration,
}) async {
  try {
    final dateRange = "$fromDate to $toDate";

    // Build the request body
    final Map<String, dynamic> requestBody = {
      "date_range": dateRange,
      "report": "ledger",
      "report_type": reportType,
      "ledger_type": ledgerType,
      "bill_wise": isBillWise,
      "narration": isNarration,
    };

    // Add state IDs if provided
    if (stateIds.isNotEmpty) {
      requestBody["state_ids"] = stateIds;
    } else {
      requestBody["state_ids"] = null;
    }

    // Add city IDs if provided
    if (cityIds.isNotEmpty) {
      requestBody["city_ids"] = cityIds;
    } else {
      requestBody["city_ids"] = null;
    }

    // Add group IDs (AccGrp_Ids) - numeric IDs, no quotes
    if (groupIds.isNotEmpty) {
      final formattedGroupIds = groupIds.join(',');
      requestBody["AccGrp_Ids"] = "[$formattedGroupIds]";
    } else {
      requestBody["AccGrp_Ids"] = null;
    }

    // Add sub group IDs (AccLGrp_Keys) - string IDs with quotes
    if (subGroupIds.isNotEmpty) {
      final formattedSubGroupKeys = subGroupIds.map((key) => "'$key'").join(',');
      requestBody["AccLGrp_Keys"] = "[$formattedSubGroupKeys]";
    } else {
      requestBody["AccLGrp_Keys"] = null;
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

// Add these helper methods if not already present
static Future<List<KeyName>> fetchStates() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getStates'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) {
        return KeyName(
          key: item['state_id'].toString(),
          name: item['state_name'],
        );
      }).toList();
    } else {
      throw Exception('Failed to load states');
    }
  } catch (e) {
    throw Exception('Error fetching states: $e');
  }
}

static Future<List<KeyName>> fetchCities() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/accounts/getCities'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) {
        return KeyName(
          key: item['city_id'].toString(),
          name: item['city_name'],
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
}