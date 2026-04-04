import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductionService {
  // Get Job Works List
  static Future<List<Map<String, dynamic>>> getJobWorks() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/searchQuery'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'docId': item['Doc_Id'],
                'docNo': item['Doc_No']?.toString() ?? '',
                'docDt': item['Doc_Dt']?.toString() ?? '',
                'jobber': item['Led_Name']?.toString() ?? '',
                'station': item['Stn_Name']?.toString() ?? '',
                'totPcs': item['TotPcs'] ?? 0,
                'jobChgPc': item['Job_Rate'] ?? 0.0,
                'status': item['Status']?.toString() ?? 'Active',
                'createdBy': item['Created_By']?.toString() ?? '',
                'createdOn': item['Created_Dt']?.toString() ?? '',
                'updatedBy': item['Updated_By']?.toString() ?? '',
                'updatedOn': item['Updated_Dt']?.toString() ?? '',
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load job works');
      }
    } catch (e) {
      print('Error fetching job works: $e');
      return [];
    }
  }

  // Get Document Number (Last Cd and Doc No)
  static Future<Map<String, dynamic>> getDocNo() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getDocNo'),
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

  // Get Products
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getProduct'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Item_Key'].toString(),
                'name': item['Item_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Get Designs by Item Key
  static Future<List<Map<String, dynamic>>> getDesignsByItemKey(
    String itemKey,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/production/getDesigns'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Item_Key': itemKey}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Style_Key'].toString(),
                'name': item['Style_Code'].toString(),
                'typeKey': item['Type_Key'].toString(),
                'typeName': item['Type_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load designs');
      }
    } catch (e) {
      print('Error fetching designs: $e');
      return [];
    }
  }

  // Get Shades by Style Key
  static Future<List<Map<String, dynamic>>> getStyleShades(
    String styleKey,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/production/getStyleShade'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Style_Key': styleKey}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Shade_Key'].toString(),
                'name': item['Shade_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load shades');
      }
    } catch (e) {
      print('Error fetching shades: $e');
      return [];
    }
  }

  // Get Style Sizes by Style Key
  static Future<List<Map<String, dynamic>>> getStyleSizes(
    String styleKey,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/production/getStyleSize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Style_Key': styleKey}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'id': item['StyleSize_Id'],
                'name': item['Size_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load style sizes');
      }
    } catch (e) {
      print('Error fetching style sizes: $e');
      return [];
    }
  }

  // Get Order Numbers
  static Future<List<Map<String, dynamic>>> getOrderNos() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getOrders'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Order_Key'].toString(),
                'name': item['Order_No'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }

  // Get Merchandisers
  static Future<List<Map<String, dynamic>>> getMerchandisers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getMerchadiser'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Led_Key'].toString(),
                'name': item['Led_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load merchandisers');
      }
    } catch (e) {
      print('Error fetching merchandisers: $e');
      return [];
    }
  }

  // Get Jobbers
  static Future<List<Map<String, dynamic>>> getJobbers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getJobber'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Led_Key'].toString(),
                'name': item['Led_Name'].toString(),
                'station': item['Stn_Name']?.toString() ?? '',
                'stationKey': item['OStn_Key'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load jobbers');
      }
    } catch (e) {
      print('Error fetching jobbers: $e');
      return [];
    }
  }

  // Get Series
  static Future<Map<String, dynamic>> getSeries(String seriesCode) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/series/$seriesCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load series');
      }
    } catch (e) {
      print('Error fetching series: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getFabricTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getFabricType'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['ItemGrp_Key'].toString(),
                'name': item['ItemGrp_Name'].toString(),
                'type': item['ItemGrp_Type'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load fabric types');
      }
    } catch (e) {
      print('Error fetching fabric types: $e');
      return [];
    }
  }

  // Get Fabric Products by Item Group Key
  static Future<List<Map<String, dynamic>>> getFabricProducts(
    String itemGrpKey,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/production/getFabricProduct'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ItemGrp_Key': itemGrpKey}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Item_Key'].toString(),
                'name': item['Item_Name'].toString(),
                'itemSubGrpKey': item['ItemSubGrp_Key'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load fabric products');
      }
    } catch (e) {
      print('Error fetching fabric products: $e');
      return [];
    }
  }

  // Get Shades
  static Future<List<Map<String, dynamic>>> getShades() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getShade'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Shade_Key'].toString(),
                'name': item['Shade_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load shades');
      }
    } catch (e) {
      print('Error fetching shades: $e');
      return [];
    }
  }

  // Get Brands (if you have an API endpoint)
  static Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      // Replace with your actual brand API endpoint
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/production/getBrands'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (item) => {
                'key': item['Brand_Key'].toString(),
                'name': item['Brand_Name'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception('Failed to load brands');
      }
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> insertJobOrder(
    Map<String, dynamic> jobOrderData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/production/insertJobOrder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(jobOrderData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'message': 'Job Order created successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create Job Order: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error creating Job Order: $e'};
    }
  }
}
