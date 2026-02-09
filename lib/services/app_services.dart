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
          'lastsavedorderid': lastSavedOrderId,
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
}
