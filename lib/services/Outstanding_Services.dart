// In your outstanding_service.dart file
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/constants/app_constants.dart';

class OutstandingService {
  static Future<List<Map<String, dynamic>>>
  getOutstandingReceivableBills() async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getOustandingReceivableBills',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"CoBr_Id": UserSession.coBrId, "AccLGrp_Type": "4"}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOutstandingPayableBills() async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getOustandingReceivableBills',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"CoBr_Id": UserSession.coBrId, "AccLGrp_Type": "3"}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/dashboard-summary'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard summary');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
