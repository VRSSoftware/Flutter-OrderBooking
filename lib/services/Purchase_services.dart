import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';

class PurchaseService {
static  Future<Map<String, dynamic>> getPurInwardDocNo() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/purchase/getDocNo'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'LastCd': data['LastCd']?.toString() ?? '',
          'DocNo': data['DocNo']?.toString() ?? '',
        };
      } else {
        throw Exception('Failed to load document number');
      }
    } catch (e) {
      print('Error fetching document number: $e');
      return {'LastCd': '', 'DocNo': ''};
    }
  }

   static Future<Map<String, dynamic>> fetchPOForPurchaseInwardAgainstSO({
    required String coBrId,
    required String supplierKey,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/purchase/POList'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cobr_id': coBrId, 'supl_key': supplierKey}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> fetchSizeDetailsForPurchaseInward(
    Map<String, dynamic> requestBody,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/purchase/getSizeDetailsForInward'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> getPaymentDiscount() async {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/common/getPaymentDiscount'),
      headers: {'Content-Type': 'application/json'},
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> savePurchaseInward(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/purchase/savePurchaseInward'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updatePurchaseInward(
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/purchase/updatePurchaseInward'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return jsonDecode(response.body);
  }




  
}
