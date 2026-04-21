import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vrs_erp/models/PartyWithSpclMarkDwn.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/models/registerModel.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/stockReportModel.dart';
import 'package:vrs_erp/models/style.dart';
import '../constants/app_constants.dart';
import '../models/consignee.dart';

class ApiService {
  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/itemSubGrp'),
    );
    // print("RRRRRRRRRRRRRRRRRresponse data:${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  static Future<List<Item>> fetchItemsByCategory(String categoryKey) async {
    if (categoryKey.isEmpty) {
      throw Exception('Invalid category selected');
    }
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/item/$categoryKey'),
    );
    print("Item API response for $categoryKey: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items for itemSubGrpKey: $categoryKey');
    }
  }

  static Future<List<Item>> fetchAllItems() async {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/item/raju'),
    );

    // print("@@@@@@@@@@@@@@@@@@Item API response for${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items  ');
    }
  }

  static Future<List<Style>> fetchStylesByItemKey(String itemKey) async {
    if (itemKey.isEmpty) {
      throw Exception('Invalid item selected');
    }
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/style/$itemKey'),
    );
    // print("Style API response for $itemKey: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Style.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load styles for itemKey: $itemKey');
    }
  }

  static Future<List<Style>> fetchStylesByItemGrpKey(String itemGrpKey) async {
    if (itemGrpKey.isEmpty) {
      throw Exception('Invalid category selected');
    }
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/style/getByItemGrpKey/$itemGrpKey'),
    );
    // print("Style API response for $itemKey: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Style.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load styles for itemGrpKey: $itemGrpKey');
    }
  }

  // Fetch Shades by Item Key (returning Shade objects)
  static Future<List<Shade>> fetchShadesByItemKey(String itemKey) async {
    if (itemKey.isEmpty) {
      throw Exception('Invalid item selected');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/shade/GetShadeByItem/$itemKey'),
    );
    // print("ShADEEEEEEEEEEEEEEEEEEE API response for${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Return a list of Shade objects
      return data.map((json) => Shade.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load shades for itemKey: $itemKey');
    }
  }

  static Future<List<Shade>> fetchShadesByItemGrpKey(String itemGrpKey) async {
    if (itemGrpKey.isEmpty) {
      throw Exception('Invalid item selected');
    }

    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/shade/GetShadeByItemGrp/$itemGrpKey'),
    );
    // print("ShADEEEEEEEEEEEEEEEEEEE API response for${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Return a list of Shade objects
      return data.map((json) => Shade.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load shades for itemKey: $itemGrpKey');
    }
  }

  // Fetch Style Sizes by Item Key (returning StyleSize objects)
  static Future<List<Sizes>> fetchStylesSizeByItemKey(String itemKey) async {
    if (itemKey.isEmpty) {
      throw Exception('Invalid item selected');
    }

    final response = await http.get(
      Uri.parse(
        '${AppConstants.BASE_URL}/stylesize/GetStylesSizeByItem/$itemKey',
      ),
    );
    // print("SizeeeeeeeeeeeeeeeeeAPI response for${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Return a list of StyleSize objects
      return data.map((json) => Sizes.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load style sizes for itemKey: $itemKey');
    }
  }

  static Future<List<Sizes>> fetchStylesSizeByItemGrpKey(
    String itemGrpKey,
  ) async {
    if (itemGrpKey.isEmpty) {
      throw Exception('Invalid item selected');
    }

    final response = await http.get(
      Uri.parse(
        '${AppConstants.BASE_URL}/stylesize/GetStylesSizeByItemGrp/$itemGrpKey',
      ),
    );
    // print("SizeeeeeeeeeeeeeeeeeAPI response for${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Return a list of StyleSize objects
      return data.map((json) => Sizes.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load style sizes for itemKey: $itemGrpKey');
    }
  }

  static Future<List<Shade>> fetchShadesByStyleKey(String styleKey) async {
    if (styleKey.isEmpty) {
      throw Exception('Invalid style selected');
    }
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/shade/$styleKey'),
    );
    //  print("Shade API response for $styleKey: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Shade.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load shades for styleKey: $styleKey');
    }
  }

  static Future<List<Sizes>> fetchSizesByStyleKey(String styleKey) async {
    if (styleKey.isEmpty) {
      throw Exception('Invalid style selected');
    }
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/stylesize/$styleKey'),
    );
    // print("Size API response for $styleKey: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Sizes.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load sizes for styleKey: $styleKey');
    }
  }

  static Future<List<Brand>> fetchBrands() async {
    final response = await http.get(
      Uri.parse('${AppConstants.BASE_URL}/brand'),
    );
    //  print("Brand API response: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Brand.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load brands');
    }
  }

  static Future<List<Catalog>> fetchCatalog({
    required String itemSubGrpKey,
    required String itemKey,
    String? brandKey,
    String? styleKey,
    String? shadeKey,
    String? sizeKey,
    double? fromMRP,
    double? toMRP,
    String? coBr,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/catalog'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'itemSubGrpKey': itemSubGrpKey,
        'itemKey': itemKey,
        'brandKey': brandKey,
        'styleKey': styleKey,
        'shadeKey': shadeKey,
        'sizeKey': sizeKey,
        'fromMRP': fromMRP,
        'toMRP': toMRP,
        'coBr': coBr,
      }),
    );
    //  print("response body:${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Catalog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load catalog');
    }
  }

  static Future<List<dynamic>> getBarcodeDetails(String barcode) async {
    final url = Uri.parse(
      '${AppConstants.BASE_URL}/orderBooking/GetBarcodeDetails',
    );

    final body = {
      "coBrId": UserSession.coBrId ?? '',
      "userId": UserSession.userName ?? '',
      "fcYrId": UserSession.userFcYr ?? '',
      "barcode": barcode,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print("response barcode:${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch barcode details');
    }
  }

  static Future<Map<String, dynamic>> fetchCatalogItem({
    required String itemSubGrpKey,
    String? itemKey,
    required String cobr,
    String? brandKey,
    String? sortBy,
    String? styleKey,
    String? shadeKey,
    String? sizeKey,
    String? fromMRP,
    String? toMRP,
    String? fromDate,
    String? toDate,
    String? stockFilter, // Add this
    String? imageFilter, // Add this
    int? pageNo,
  }) async {
    final url = Uri.parse('${AppConstants.BASE_URL}/catalog/catlogDetailsPgn');

    final Map<String, dynamic> body = {
      "itemSubGrpKey": itemSubGrpKey,
      "itemKey": itemKey,
      "brandKey": brandKey,
      "styleKey": styleKey,
      "shadeKey": shadeKey,
      "sizeKey": sizeKey,
      "fromMRP": fromMRP,
      "toMRP": toMRP,
      "cobr": cobr,
      "sortBy": sortBy,
      "fromDate": fromDate,
      "toDate": toDate,
      "stockFilter": stockFilter, // Add this
      "imageFilter": imageFilter, // Add this
      "pageNo": pageNo,
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final catalogs = data.map((json) => Catalog.fromJson(json)).toList();
      return {"statusCode": response.statusCode, "catalogs": catalogs};
    } else {
      return {
        "statusCode": response.statusCode,
        "catalogs": [],
        "error": response.body,
      };
    }
  }

  static Future<List<String>> fetchAddedItems({
    required String coBrId,
    required String userId,
    required String fcYrId,
    required String barcode,
  }) async {
    final url = Uri.parse(
      '${AppConstants.BASE_URL}/orderBooking/GetAddedItems',
    );

    final body = {
      "coBrId": coBrId,
      "userId": userId, // Ensure this is correct
      "fcYrId": fcYrId,
      "barcode": barcode,
    };
    print("Request body: $body");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    print("Response body: ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .cast<String>(); // Ensure the response is a list of style codes
    } else {
      throw Exception('Failed to fetch added items: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchConsinees({
    required String key,
    required String CoBrId,
  }) async {
    final url = Uri.parse('${AppConstants.BASE_URL}/users/getConsinee');

    final Map<String, dynamic> body = {"key": key, "coBrId": CoBrId};

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Convert the raw JSON data to a list of Consignee objects
      final List<Consignee> consignees =
          data.map((json) => Consignee.fromJson(json)).toList();

      return {
        "statusCode": response.statusCode,
        "result": consignees, // Return a list of Consignee objects
      };
    } else {
      return {
        "statusCode": response.statusCode,
        "consignees": [], // Return an empty list if the request fails
        "error": response.body,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchBookingTypes({
    required String coBrId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/getBookingType'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'coBrId': coBrId}),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('Error fetching booking types: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception in fetchBookingTypes: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSalesOrderData({
    required String coBrId,
    required String userId,
    required String fcYrId,
    required String barcode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderBooking/get-sales-order-no'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'coBrId': coBrId,
          'userId': userId,
          'fcYrId': fcYrId,
          'barcode': barcode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Sales Order Data: $data');
        return Map<String, dynamic>.from(data);
      } else {
        print('Error fetching sales order data: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Exception in getSalesOrderData: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> fetchLedgers({
    required String ledCat,
    required String coBrId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/getLedger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ledCat': ledCat, 'coBrId': coBrId}),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> result =
            data
                .map(
                  (item) => KeyName(
                    key: item['ledKey'].toString(),
                    name: item['ledName'].toString(),
                  ),
                )
                .toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching ledgers: $statusCode');
        return {'statusCode': statusCode, 'result': <KeyName>[]};
      }
    } catch (e) {
      print('Exception in fetchLedgers: $e');
      return {'statusCode': 500, 'result': <KeyName>[]};
    }
  }

  static Future<Map<String, dynamic>> fetchPartyWithSpclMarkDwn({
    required String ledCat,
    required String coBrId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/getPartyWithSpclMarkDwn'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ledCat': ledCat, 'coBrId': coBrId}),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<PartyWithSpclMarkDwn> result =
            data.map((item) => PartyWithSpclMarkDwn.fromJson(item)).toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching parties: $statusCode');
        return {'statusCode': statusCode, 'result': <PartyWithSpclMarkDwn>[]};
      }
    } catch (e) {
      print('Exception in fetchPartyWithSpclMarkDwn: $e');
      return {'statusCode': 500, 'result': <PartyWithSpclMarkDwn>[]};
    }
  }

  static Future<List<RegisterOrder>> fetchOrderRegister({
    required String fromDate,
    required String toDate,
    String? custKey,
    required String coBrId,
    String? salesPerson,
    String? status,
    String? dlvFromDate,
    String? dlvToDate,
    String? userName,
    String? lastSavedOrderId,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.BASE_URL}/orderBooking/getOrderRegister',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromDate': fromDate,
          'toDate': toDate,
          'custKey': custKey,
          'coBrId': coBrId,
          'salesPerson': salesPerson,
          'status': status,
          'dlvFromDate': dlvFromDate,
          'dlvToDate': dlvToDate,
          'userName': userName,
          'lastsavedorderid': '0',
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RegisterOrder.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load order register: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching order register: $e');
    }
  }

  static Future<List<RegisterOrder>> fetchPackingRegister({
    required String fromDate,
    required String toDate,
    String? custKey,
    required String coBrId,
    String? salesPerson,
    String? status,
    String? dlvFromDate,
    String? dlvToDate,
    String? userName,
    String? lastSavedOrderId,
    int? pageNo,
    int? pageSize,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.BASE_URL}/orderBooking/getPackingRegister',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromDate': fromDate,
          'toDate': toDate,
          'custKey': custKey,
          'coBrId': coBrId,
          'salesPerson': salesPerson,
          'status': status,
          'dlvFromDate': dlvFromDate,
          'dlvToDate': dlvToDate,
          'userName': userName,
          'lastsavedorderid': lastSavedOrderId,
          'pageNo': pageNo,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RegisterOrder.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load order register: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching order register: $e');
    }
  }

  static Future<List<RegisterOrder>> fetchSaleBillRegister({
    required String fromDate,
    required String toDate,
    String? custKey,
    required String coBrId,
    String? salesPerson,
    String? status,
    String? dlvFromDate,
    String? dlvToDate,
    String? userName,
    String? lastSavedOrderId,
    int? pageNo,
    int? pageSize,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.BASE_URL}/orderBooking/getSaleBillRegister',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fromDate': fromDate,
          'toDate': toDate,
          'custKey': custKey,
          'coBrId': coBrId,
          'salesPerson': salesPerson,
          'status': status,
          'dlvFromDate': dlvFromDate,
          'dlvToDate': dlvToDate,
          'userName': userName,
          'lastsavedorderid': lastSavedOrderId,
          'pageNo': pageNo,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RegisterOrder.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load order register: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching order register: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchPayTerms({
    required String coBrId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/getPytTermDisc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'coBrId': coBrId}),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> result =
            data
                .map(
                  (item) => KeyName(
                    key: item['pytTermDiscKey'].toString(),
                    name: item['pytTermDiscName'].toString(),
                  ),
                )
                .toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching pay terms: $statusCode');
        return {'statusCode': statusCode, 'result': <KeyName>[]};
      }
    } catch (e) {
      print('Exception in fetchPayTerms: $e');
      return {'statusCode': 500, 'result': <KeyName>[]};
    }
  }

  static Future<Map<String, dynamic>> fetchStations({
    required String coBrId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/getStation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'coBrId': coBrId}),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> result =
            data
                .map(
                  (item) => KeyName(
                    key: item['key'].toString(),
                    name: item['value'].toString(),
                  ),
                )
                .toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching stations: $statusCode');
        return {'statusCode': statusCode, 'result': <KeyName>[]};
      }
    } catch (e) {
      print('Exception in fetchStations: $e');
      return {'statusCode': 500, 'result': <KeyName>[]};
    }
  }

  // Add to ApiService class
  static Future<List<StockReportItem>> fetchStockReport({
    required String itemSubGrpKey,
    required String itemKey,
    required String userId,
    required String fcYrId,
    required String cobr,
    String? brandKey,
    String? styleKey,
    String? shadeKey,
    String? sizeKey,
    double? fromMRP,
    double? toMRP,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/stockReport/getStockReport'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "itemSubGrpKey": itemSubGrpKey,
        "itemKey": itemKey,
        "userId": userId,
        "fcYrId": fcYrId,
        "cobr": cobr,
        "brandKey": brandKey,
        "styleKey": styleKey,
        "shadeKey": shadeKey,
        "sizeKey": sizeKey,
        "fromMRP": fromMRP,
        "toMRP": toMRP,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StockReportItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stock report: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchStates() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/states'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'CoBr_Id': UserSession.coBrId}),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> result =
            data
                .map(
                  (item) => KeyName(
                    key: item['state_key'].toString(),
                    name: item['state_name'].toString(),
                  ),
                )
                .toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching states: $statusCode');
        return {'statusCode': statusCode, 'result': <KeyName>[]};
      }
    } catch (e) {
      print('Exception in fetchStates: $e');
      return {'statusCode': 500, 'result': <KeyName>[]};
    }
  }

  static Future<Map<String, dynamic>> fetchCities({
    required String stateKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/cities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'CoBr_Id': UserSession.coBrId, 'statekey': stateKey}),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> result =
            data
                .map(
                  (item) => KeyName(
                    key: item['city_key'].toString(),
                    name: item['city_name'].toString(),
                  ),
                )
                .toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching cities: $statusCode');
        return {'statusCode': statusCode, 'result': <KeyName>[]};
      }
    } catch (e) {
      print('Exception in fetchCities: $e');
      return {'statusCode': 500, 'result': <KeyName>[]};
    }
  }

  static Future<Map<String, dynamic>> fetchLedgerList({
    required String type,
    required String? salesPersonKey,
    String? selectedCity,
    String? selectedState,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/users/ledger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'CoBr_Id': UserSession.coBrId,
          'SalesPerson_key': salesPersonKey,
          'selectedCity': selectedCity,
          'selectedState': selectedState,
        }),
      );

      final int statusCode = response.statusCode;

      if (statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<KeyName> result =
            data
                .map(
                  (item) => KeyName(
                    key: item['Led_Key'].toString(),
                    name: item['Led_Name'].toString(),
                  ),
                )
                .toList();

        return {'statusCode': statusCode, 'result': result};
      } else {
        print('Error fetching ledger list: $statusCode');
        return {'statusCode': statusCode, 'result': <KeyName>[]};
      }
    } catch (e) {
      print('Exception in fetchLedgerList: $e');
      return {'statusCode': 500, 'result': <KeyName>[]};
    }
  }

  // Add this to your ApiService class
  static Future<Map<String, dynamic>> fetchOrderReportData(
    String orderNo,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.BASE_URL}/orderRegister/getSalesOrderData/$orderNo',
        ),
        headers: {
          'Content-Type': 'application/json',
          // Add any authentication headers if needed
          // 'Authorization': 'Bearer ${UserSession.token}',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load order report data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching order report data: $e');
      throw Exception('Error fetching order report data: $e');
    }
  }

  //customer apis
  static Future<Map<String, dynamic>> createLedger(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/accounts/createLedger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success response
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {'message': response.body, 'success': true};
        }
      } else {
        // Error response - try to extract meaningful message
        String errorMessage = 'Something went wrong';

        try {
          final errorData = jsonDecode(response.body);

          // Check for DUPLICATE_KEY error
          if (errorData['errorCode'] == 'DUPLICATE_KEY' ||
              errorData['message']?.contains('DUPLICATE_KEY') == true ||
              errorData['error']?.contains('Duplicate') == true) {
            // Extract ledger name from error if possible
            if (errorData['dynamicMessage'] != null) {
              errorMessage = errorData['dynamicMessage'];
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            } else {
              errorMessage = 'Customer with this name already exists';
            }
          }
          // Handle other application exceptions
          else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // If response is not JSON, check if it contains duplicate key message
          if (response.body.contains('Duplicate') ||
              response.body.contains('duplicate') ||
              response.body.contains('already exists')) {
            errorMessage = 'Customer with this name already exists';
          } else {
            errorMessage = response.body;
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Handle network errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
          'No response from server. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getBrandForCust() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getBrand'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('Unexpected response format for brands: $data');
          return [];
        }
      } else {
        print('Error fetching brands: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching brands: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomerGroups() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getCustomerGrp'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('Unexpected response format for customer groups: $data');
          return [];
        }
      } else {
        print('Error fetching customer groups: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching customer groups: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAccountSubGroups() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getAccLGrp'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('Unexpected response format for account subgroups: $data');
          return [];
        }
      } else {
        print('Error fetching account subgroups: ${response.statusCode}');
        return [];
      }
    } catch (error) {
      print('Error fetching account subgroups: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCardType() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getCardTypes'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching card types: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCurrency() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getCurrency'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching currencies: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPaymentDiscount() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getPaymentTermsDisc'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching payment discounts: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getQuality() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getQuality'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching quality: $error');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTerms() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getTerms'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching terms: $error');
      return [];
    }
  }

  // Add to ApiService class

  static Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.BASE_URL}/accounts/getLedger'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['data'] != null && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (error) {
      print('Error fetching customers: $error');
      return [];
    }
  }

  static Future<Map<String, dynamic>> deleteLedger(String ledKey) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.BASE_URL}/accounts/deleteLedger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"@Led_Key_1": ledKey}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {'message': 'Customer deleted successfully', 'success': true};
        }
      } else {
        String errorMessage = 'Failed to delete customer';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? response.body;
        } catch (e) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception(
          'No response from server. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLedgerByLedKey(String ledKey) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.BASE_URL}/accounts/getLedgerByLedKey/$ledKey',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]; // Return the first customer object
        }
        return {};
      } else {
        throw Exception('Failed to fetch customer data');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'No response from server. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateLedger(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.BASE_URL}/accounts/updateLedger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          return {'message': response.body, 'success': true};
        }
      } else {
        String errorMessage = 'Failed to update customer';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? response.body;
        } catch (e) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'No response from server. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }
    static Future<Map<String, dynamic>> fetchOrderReportDataPost(
    String docId,
    String orderStatus,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.BASE_URL}/orderRegister/getSalesOrderData'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"doc_id": docId, "order_status": orderStatus}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load order report data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching order report data: $e');
      throw Exception('Error fetching order report data: $e');
    }
  }

  // Add this method to your existing ApiService class
static Future<Map<String, dynamic>> insertPacking(Map<String, dynamic> payload) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/orderBooking/insertPacking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'status': 'error', 'message': 'Failed to save packing'};
    }
  } catch (e) {
    print('Error inserting packing: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}

static Future<Map<String, dynamic>> deletePacking({
  required String docId,
  required String coBrId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/orderBooking/deletePacking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'docId': docId,
        'coBrId': coBrId,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'status': 'error', 'message': 'Failed to delete packing order'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}
// Fetch packing by ID for update
static Future<Map<String, dynamic>> fetchPackingById({
  required String docId,
  required String coBrId,
}) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/orderBooking/getPackingById'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'docId': docId,
        'coBrId': coBrId,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'status': 'error', 'message': 'Failed to fetch packing data'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

// Update packing
static Future<Map<String, dynamic>> updatePacking(Map<String, dynamic> payload) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/orderBooking/updatePacking'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'status': 'error', 'message': 'Failed to update packing'};
  } catch (e) {
    return {'status': 'error', 'message': e.toString()};
  }
}

}
