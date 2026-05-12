import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/OrderBooking/orderbooking_booknow.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/catalog.dart';

import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

extension NullOrEmpty on Object? {
  bool get isNullOrEmpty {
    if (this == null) return true;
    if (this is String) return (this as String).isEmpty;
    if (this is List) return (this as List).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    return false;
  }
  
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

class CatalogItem {
  final String styleCode;
  final String shadeName;
  final String sizeName;
  final int clQty;
  final double mrp;
  final double wsp;

  CatalogItem({
    required this.styleCode,
    required this.shadeName,
    required this.sizeName,
    required this.clQty,
    required this.mrp,
    required this.wsp,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      styleCode: json['styleCode']?.toString() ?? '',
      shadeName: json['shadeName']?.toString() ?? '',
      sizeName: json['sizeName']?.toString() ?? '',
      clQty: int.tryParse(json['clqty']?.toString() ?? '0') ?? 0,
      mrp: double.tryParse(json['mrp']?.toString() ?? '0') ?? 0,
      wsp: double.tryParse(json['wsp']?.toString() ?? '0') ?? 0,
    );
  }
}

class MultiCatalogBookingPage extends StatefulWidget {
  final List<Catalog> catalogs;
  final VoidCallback onSuccess; // Add this line
  final Map<String, dynamic>? routeArguments;
  const MultiCatalogBookingPage({
    super.key,
    required this.catalogs,
    required this.onSuccess,
    this.routeArguments,
  });

  

  @override
  State<MultiCatalogBookingPage> createState() =>
      _MultiCatalogBookingPageState();
}

class _MultiCatalogBookingPageState extends State<MultiCatalogBookingPage> {
  Map<String, List<CatalogItem>> catalogItemsMap = {};
  Map<String, List<String>> sizesMap = {};
  Map<String, List<String>> colorsMap = {};
  Map<String, Map<String, Map<String, TextEditingController>>> controllersMap =
      {};
  Map<String, String> styleCodeMap = {};
  Map<String, Map<String, double>> sizeMrpMap = {};
  Map<String, Map<String, double>> sizeWspMap = {};
  Map<String, TextEditingController> noteControllersMap = {};
  Map<String, bool> isLoadingMap = {};
  Map<String, List<String>> copiedRowsMap = {};

  String userId = UserSession.userName ?? '';
  String coBrId = UserSession.coBrId ?? '';
  String fcYrId = UserSession.userFcYr ?? '';
  bool stockWise = true;
  int maxSizes = 0;
  bool isLoading = true;
  int _loadingCounter = 0;


  // Add after copiedRowsMap
Map<String, Map<String, Uint8List?>> aiGeneratedImages = {}; // Store AI generated images
Map<String, Map<String, bool>> isGeneratingAIImage = {}; // Loading states for AI generation

final String stabilityApiKey = 'sk-pWlAiqMTis8Dfj4lJWstDURxCWMStEX7Ob9OM80lb39AgR89';
final String stabilityApiUrl = 'https://api.stability.ai/v2beta/stable-image/edit/search-and-replace';


  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  List<Catalog> filteredCatalogs = [];

  @override
  void initState() {
    super.initState();
      filteredCatalogs = List.from(widget.catalogs);
    _loadingCounter = widget.catalogs.length;
    for (var catalog in widget.catalogs) {
      noteControllersMap[catalog.styleCode] = TextEditingController();
      copiedRowsMap[catalog.styleCode] = [];
      aiGeneratedImages[catalog.styleCode] = {}; // Add this line
      isGeneratingAIImage[catalog.styleCode] = {}; // Add this line
      fetchCatalogData(catalog);
    }
  }


  @override
void dispose() {
  searchController.dispose();
  super.dispose();
}

  void filterCatalogs(String query) {
  setState(() {
    if (query.isEmpty) {
      filteredCatalogs = List.from(widget.catalogs);
    } else {
      filteredCatalogs = widget.catalogs.where((catalog) {
        return catalog.styleCode.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  });
}

bool _hasShades(Catalog catalog) {
  final items = catalogItemsMap[catalog.styleCode] ?? [];
  return items.any((item) => item.shadeName.isNotNullOrEmpty);
}

Future<void> fetchCatalogData(Catalog catalog) async {
  final String apiUrl = '${AppConstants.BASE_URL}/catalog/GetOrderDetails';

  final Map<String, dynamic> requestBody = {
    "itemSubGrpKey": catalog.itemSubGrpKey.toString(),
    "itemKey": catalog.itemKey.toString(),
    "styleKey": catalog.styleKey.toString(),
    "userId": userId,
    "coBrId": coBrId,
    "fcYrId": fcYrId,
    "stockWise": stockWise,
    "brandKey": null,
    "shadeKey": null,
    "styleSizeId": null,
    "fromMRP": null,
    "toMRP": null,
  };

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final items = data.map((e) => CatalogItem.fromJson(e)).toList();
        
        // Check if all shades are null/empty
        final hasValidShades = items.any((e) => e.shadeName.isNotNullOrEmpty);
        
        List<String> uniqueSizes;
        List<String> uniqueColors;
        
        if (!hasValidShades) {
          // No shades case - use empty string as shade
          uniqueSizes = items.map((e) => e.sizeName).toSet().toList();
          uniqueColors = ['']; // Empty string for no-shade
        } else {
          // Has shades - normal case
          uniqueSizes = items.map((e) => e.sizeName).toSet().toList();
          uniqueColors = items.map((e) => e.shadeName).toSet().toList();
        }

        Map<String, double> tempSizeMrpMap = {};
        Map<String, double> tempSizeWspMap = {};
        for (var item in items) {
          tempSizeMrpMap[item.sizeName] = item.mrp;
          tempSizeWspMap[item.sizeName] = item.wsp;
        }

        Map<String, Map<String, TextEditingController>> tempControllers = {};
        for (var color in uniqueColors) {
          tempControllers[color] = {};
          for (var size in uniqueSizes) {
            final match = items.firstWhere(
              (item) => item.shadeName == color && item.sizeName == size,
              orElse: () => CatalogItem(
                styleCode: catalog.styleCode,
                shadeName: color,
                sizeName: size,
                clQty: 0,
                mrp: tempSizeMrpMap[size] ?? 0,
                wsp: tempSizeWspMap[size] ?? 0,
              ),
            );
            final controller = TextEditingController();
            controller.addListener(() => setState(() {}));
            tempControllers[color]![size] = controller;
          }
        }

        setState(() {
          catalogItemsMap[catalog.styleCode] = items;
          sizesMap[catalog.styleCode] = uniqueSizes;
          colorsMap[catalog.styleCode] = uniqueColors;
          styleCodeMap[catalog.styleCode] = catalog.styleCode;
          sizeMrpMap[catalog.styleCode] = tempSizeMrpMap;
          sizeWspMap[catalog.styleCode] = tempSizeWspMap;
          controllersMap[catalog.styleCode] = tempControllers;
          isLoadingMap[catalog.styleCode] = false;
          if (uniqueSizes.length > maxSizes) {
            maxSizes = uniqueSizes.length;
          }
          _loadingCounter--;
          if (_loadingCounter == 0) {
            isLoading = false;
          }
        });
      } else {
        setState(() {
          isLoadingMap[catalog.styleCode] = false;
          _loadingCounter--;
          if (_loadingCounter == 0) {
            isLoading = false;
          }
        });
      }
    } else {
      debugPrint('Failed to fetch catalog data for ${catalog.styleCode}: ${response.statusCode}');
      setState(() {
        isLoadingMap[catalog.styleCode] = false;
        _loadingCounter--;
        if (_loadingCounter == 0) {
          isLoading = false;
        }
      });
    }
  } catch (e) {
    debugPrint('Error fetching catalog data for ${catalog.styleCode}: $e');
    setState(() {
      isLoadingMap[catalog.styleCode] = false;
      _loadingCounter--;
      if (_loadingCounter == 0) {
        isLoading = false;
      }
    });
  }
}
  int getTotalQty(String styleCode) {
    int total = 0;
    final controllers = controllersMap[styleCode];
    if (controllers != null) {
      for (var row in controllers.values) {
        for (var cell in row.values) {
          total += int.tryParse(cell.text) ?? 0;
        }
      }
    }
    return total;
  }

  double getTotalAmount(String styleCode) {
    double total = 0;
    final controllers = controllersMap[styleCode];
    final wspMap = sizeWspMap[styleCode];
    if (controllers != null && wspMap != null) {
      for (var colorEntry in controllers.entries) {
        for (var sizeEntry in colorEntry.value.entries) {
          final qty = int.tryParse(sizeEntry.value.text) ?? 0;
          final wsp = wspMap[sizeEntry.key] ?? 0;
          total += qty * wsp;
        }
      }
    }
    return total;
  }

  int getTotalItems() {
    return widget.catalogs.length;
  }

  int getTotalQtyAllStyles() {
    int total = 0;
    for (var catalog in widget.catalogs) {
      total += getTotalQty(catalog.styleCode);
    }
    return total;
  }

  double getTotalAmountAllStyles() {
    double total = 0;
    for (var catalog in widget.catalogs) {
      total += getTotalAmount(catalog.styleCode);
    }
    return total;
  }

  int getTotalStock(String styleCode) {
    int total = 0;
    final items = catalogItemsMap[styleCode];
    if (items != null) {
      for (var item in items) {
        total += item.clQty;
      }
    }
    return total;
  }

  void _copyQtyInAllShade(String styleCode) {
    final colors = colorsMap[styleCode] ?? [];
    final sizes = sizesMap[styleCode] ?? [];
    if (colors.isEmpty || sizes.isEmpty) return;

    final sourceColor = colors.first;
    final sourceSize = sizes.first;
    final valueToCopy =
        controllersMap[styleCode]?[sourceColor]?[sourceSize]?.text ?? '';

    for (var color in colors) {
      for (var size in sizes) {
        controllersMap[styleCode]?[color]?[size]?.text = valueToCopy;
      }
    }

    setState(() {});
  }

  void _copySizeQtyInAllShade(String styleCode) {
    final colors = colorsMap[styleCode] ?? [];
    final sizes = sizesMap[styleCode] ?? [];
    if (colors.isEmpty || sizes.isEmpty) return;

    final sourceColor = colors.first;
    for (var size in sizes) {
      final valueToCopy =
          controllersMap[styleCode]?[sourceColor]?[size]?.text ?? '';
      for (var color in colors) {
        controllersMap[styleCode]?[color]?[size]?.text = valueToCopy;
      }
    }

    setState(() {});
  }

  void _copySizeQtyToOtherStyles(String sourceStyleCode) {
    final sourceControllers = controllersMap[sourceStyleCode];
    if (sourceControllers == null) return;

    for (var catalog in widget.catalogs) {
      final targetStyleCode = catalog.styleCode;
      if (targetStyleCode == sourceStyleCode) continue;
      final targetControllers = controllersMap[targetStyleCode];
      if (targetControllers == null) continue;

      for (var shade in sourceControllers.keys) {
        if (targetControllers.containsKey(shade)) {
          for (var size in sourceControllers[shade]!.keys) {
            if (targetControllers[shade]!.containsKey(size)) {
              final sourceQty = sourceControllers[shade]![size]!.text;
              targetControllers[shade]![size]!.text = sourceQty;
            }
          }
        }
      }
    }
    setState(() {});
  }

  void _deleteCatalog(Catalog catalog) {
    setState(() {
      widget.catalogs.removeWhere((c) => c.styleCode == catalog.styleCode);
      catalogItemsMap.remove(catalog.styleCode);
      sizesMap.remove(catalog.styleCode);
      colorsMap.remove(catalog.styleCode);
      controllersMap.remove(catalog.styleCode);
      styleCodeMap.remove(catalog.styleCode);
      sizeMrpMap.remove(catalog.styleCode);
      sizeWspMap.remove(catalog.styleCode);
      noteControllersMap[catalog.styleCode]?.dispose();
      noteControllersMap.remove(catalog.styleCode);
      isLoadingMap.remove(catalog.styleCode);
      copiedRowsMap.remove(catalog.styleCode);
       aiGeneratedImages.remove(catalog.styleCode); // Add this line
       isGeneratingAIImage.remove(catalog.styleCode); // Add this line
    });
  }

  Color _getColorCode(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow[800]!;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getImageUrl(Catalog catalog) {
    final path = catalog.fullImagePath ?? '';
    if (UserSession.onlineImage == '0') {
      final imageName = path.split('/').last.split('?').first;
      return imageName.isEmpty
          ? ''
          : '${AppConstants.BASE_URL}/images/$imageName';
    } else if (UserSession.onlineImage == '1') {
      return path;
    }
    return '';
  }


  // Add this method after _getImageUrl method
Future<Uint8List?> generateAIImageWithShade(
  String baseImageUrl,
  String shadeName,
  String styleCode,
) async {
  try {
    final imageResponse = await http.get(Uri.parse(baseImageUrl));
    if (imageResponse.statusCode != 200) {
      print("Failed to download image: ${imageResponse.statusCode}");
      return null;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(stabilityApiUrl),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $stabilityApiKey',
      'Accept': 'image/*',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageResponse.bodyBytes,
        filename: 'original_image.png',
        contentType: MediaType('image', 'png'),
      ),
    );

    request.fields['prompt'] = 
        "Transform this garment to $shadeName color. "
        "Keep the exact same style, design, patterns, and fabric texture. "
        "Only change the color to $shadeName. Maintain high quality and realism.";
    
    request.fields['search_prompt'] = "garment, clothing, dress, shirt, top";
    request.fields['strength'] = '0.75';
    request.fields['output_format'] = 'png';

    final response = await request.send();

    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      return bytes;
    } else {
      final errorBody = await response.stream.bytesToString();
      print("AI API Error (${response.statusCode}): $errorBody");
      return null;
    }
  } catch (e) {
    print("AI Generation Error: $e");
    return null;
  }
}


// Add this method after generateAIImageWithShade
Future<void> generateImageForShade(
  Catalog catalog,
  String shadeName,
  String baseImageUrl,
) async {
  if (isGeneratingAIImage[catalog.styleCode]?[shadeName] == true) {
    return; // Already generating
  }

  setState(() {
    isGeneratingAIImage[catalog.styleCode] ??= {};
    isGeneratingAIImage[catalog.styleCode]![shadeName] = true;
  });

  final generatedImage = await generateAIImageWithShade(
    baseImageUrl,
    shadeName,
    catalog.styleCode,
  );

  setState(() {
    isGeneratingAIImage[catalog.styleCode]![shadeName] = false;
    if (generatedImage != null) {
      aiGeneratedImages[catalog.styleCode] ??= {};
      aiGeneratedImages[catalog.styleCode]![shadeName] = generatedImage;
      
      // Show the generated image in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        generatedImage,
                        height: 300,
                        width: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Generated: $shadeName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  });
}


// Add this method after generateImageForShade
Uint8List? getDisplayImage(Catalog catalog, String shadeName) {
  // Check if we have AI generated image for this shade
  if (aiGeneratedImages[catalog.styleCode]?.containsKey(shadeName) == true &&
      aiGeneratedImages[catalog.styleCode]![shadeName] != null) {
    return aiGeneratedImages[catalog.styleCode]![shadeName];
  }
  return null;
}

@override
Widget build(BuildContext context) {
  return Scaffold(
   appBar: isSearching
    ? AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        toolbarHeight: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          child: TextField(
            controller: searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.black87, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search by Style Code...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600], size: 18),
                      onPressed: () {
                        setState(() {
                          searchController.clear();
                          filterCatalogs('');
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: filterCatalogs,
          ),
        ),
        actions: [
          // Add Cancel button to exit search
          TextButton(
            onPressed: () {
              setState(() {
                isSearching = false;
                searchController.clear();
                filterCatalogs('');
              });
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
           
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withOpacity(0.9),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryChip(
                          icon: Icons.currency_rupee,
                          label: 'Total: ₹${getTotalAmountAllStyles().toStringAsFixed(2)}',
                          color: Colors.amber,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        _buildSummaryChip(
                          icon: Icons.inventory,
                          label: 'Items: ${getTotalItems()}',
                          color: Colors.lightBlue,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        _buildSummaryChip(
                          icon: Icons.shopping_cart,
                          label: 'Qty: ${getTotalQtyAllStyles()}',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          )
        : AppBar(
            title: const Text(
              'Book Multiple Items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                },
              ),
            ],
            toolbarHeight: 40,
            titleSpacing: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withOpacity(0.9),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryChip(
                          icon: Icons.currency_rupee,
                          label: 'Total: ₹${getTotalAmountAllStyles().toStringAsFixed(2)}',
                          color: Colors.amber,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        _buildSummaryChip(
                          icon: Icons.inventory,
                          label: 'Items: ${getTotalItems()}',
                          color: Colors.lightBlue,
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        _buildSummaryChip(
                          icon: Icons.shopping_cart,
                          label: 'Qty: ${getTotalQtyAllStyles()}',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
    body: SafeArea(
      child: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading catalog data...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : filteredCatalogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No items found for '${searchController.text}'",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredCatalogs.length,
                        itemBuilder: (context, index) {
                          final catalog = filteredCatalogs[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildItemBookingSection(context, catalog),
                          );
                        },
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
    ),
  );
}
  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemBookingSection(BuildContext context, Catalog catalog) {
    if ((catalogItemsMap[catalog.styleCode] ?? []).isEmpty) {
      return const Center(child: Text("Empty"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with image, style code and actions in same line
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image - fixed size, cover fit
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      final imageUrl = _getImageUrl(catalog);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ImageZoomScreen(
                                imageUrls: [imageUrl],
                                initialIndex: 0,
                              ),
                        ),
                      );
                    },
                    child: Image.network(
                      _getImageUrl(catalog),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Style Code and Actions in a single row with background
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.08),
                        Colors.white,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Style Code with label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'STYLE CODE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor.withOpacity(0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catalog.styleCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Copy and Delete buttons
                      Container(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildIconButton(
                              icon: Icons.copy_outlined,
                              color: AppColors.primaryColor,
                              onPressed: () => _showCopyDialog(catalog),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              color: Colors.grey.shade200,
                            ),
                            _buildIconButton(
                              icon: Icons.delete_outline,
                              color: AppColors.maroon,
                              onPressed: () => _showDeleteDialog(catalog),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Stats row with Qty, Stock, Amount in same line
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
                Colors.grey.shade50,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              // Qty
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50.withOpacity(0.7),
                        Colors.blue.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Qty: ${getTotalQty(catalog.styleCode)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stock
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade50.withOpacity(0.7),
                        Colors.green.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${getTotalStock(catalog.styleCode)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Amount
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade50.withOpacity(0.7),
                        Colors.amber.shade100.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Amt: ${getTotalAmount(catalog.styleCode).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table - full width
        _buildCatalogTable(catalog),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 23, color: color),
        ),
      ),
    );
  }

  void _showCopyDialog(Catalog catalog) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea (
       child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Copy Quantities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _buildCopyOption(
                icon: Icons.copy_all,
                title: 'Copy Qty in All Shade',
                description: 'Copy first quantity to all shades',
                color: AppColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _copyQtyInAllShade(catalog.styleCode);
                },
              ),
              _buildCopyOption(
                icon: Icons.content_copy,
                title: 'Copy Size Qty in All Shade',
                description: 'Copy each size quantity across all shades',
                color: AppColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _copySizeQtyInAllShade(catalog.styleCode);
                },
              ),
              _buildCopyOption(
                icon: Icons.copy_all_rounded,
                title: 'Copy Size Qty to other Styles',
                description: 'Copy quantities to other selected styles',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _copySizeQtyToOtherStyles(catalog.styleCode);
                },
              ),
            ],
          ),
         ), );
      },
    );
  }

  Widget _buildCopyOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(Catalog catalog) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm Delete',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete style "${catalog.styleCode}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _deleteCatalog(catalog);
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceTag(BuildContext context, String styleCode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        styleCode,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF800000),
        ),
      ),
    );
  }

Widget _buildCatalogTable(Catalog catalog) {
  final sizes = sizesMap[catalog.styleCode] ?? [];
  final hasShades = _hasShades(catalog);
  
  // For no-shade, still use the same table structure but with empty shade cells
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(0),
    ),
    child: ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 24,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 0.5,
              ),
              columnWidths: _buildColumnWidths(sizes.length),
              children: [
                _buildPriceRow("MRP", sizeMrpMap[catalog.styleCode] ?? {}, FontWeight.w600, sizes),
                _buildPriceRow("WSP", sizeWspMap[catalog.styleCode] ?? {}, FontWeight.w400, sizes),
                // Use empty header cell for no-shade
                _buildHeaderRow(catalog.styleCode, sizes, hasShades),
                for (var i = 0; i < (colorsMap[catalog.styleCode]?.length ?? 0); i++)
                  _buildQuantityRow(
                    catalog,
                    colorsMap[catalog.styleCode]![i],
                    i,
                    sizes,
                    hasShades, // Pass hasShades flag
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


  Map<int, TableColumnWidth> _buildColumnWidths(int sizeCount) {
    // Calculate dynamic column widths based on screen size
    double screenWidth =
        MediaQuery.of(context).size.width - 24; // Subtract padding

    // First column takes 120px, remaining space divided among size columns
    double firstColumnWidth = 140;
    double remainingWidth = screenWidth - firstColumnWidth;
    double sizeColumnWidth = remainingWidth / (sizeCount > 0 ? sizeCount : 1);

    // Ensure minimum width for size columns
    if (sizeColumnWidth < 70) {
      sizeColumnWidth = 70;
    }

    return {
      0: FixedColumnWidth(firstColumnWidth),
      for (int i = 0; i < maxSizes; i++)
        (i + 1): FixedColumnWidth(sizeColumnWidth),
    };
  }

  Widget _buildBottomBar() {
    final hasQty = widget.catalogs.any((c) => getTotalQty(c.styleCode) > 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderPage(),
                    settings: RouteSettings(arguments: widget.routeArguments),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: hasQty ? _submitAllOrders : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: hasQty ? AppColors.primaryColor : Colors.grey.shade400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Confirm Order',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildPriceRow(
    String label,
    Map<String, double> sizePriceMap,
    FontWeight weight,
    List<String> sizes,
  ) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade50),
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: weight,
                color: Colors.grey.shade800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        ...List.generate(maxSizes, (index) {
          if (index < sizes.length) {
            final size = sizes[index];
            final price = sizePriceMap[size] ?? 0.0;
            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(
                child: Text(
                  price.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: weight,
                    color: Colors.grey.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          } else {
            return const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Center(child: Text('')),
            );
          }
        }),
      ],
    );
  }

TableRow _buildHeaderRow(String styleCode, List<String> sizes, bool hasShades) {
  return TableRow(
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 236, 212, 204).withOpacity(0.2),
    ),
    children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: hasShades
            ? const _TableHeaderCell() // Show diagonal with Shade/Size
            : Container(
                height: 48,
                padding: const EdgeInsets.only(left: 16), // Add left padding
                child: const Align(
                  alignment: Alignment.centerLeft, // Align to left
                  child: Text(
                    'SIZE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
      ),
      ...List.generate(maxSizes, (index) {
        if (index < sizes.length) {
          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  sizes[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          return const TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(child: Text('')),
          );
        }
      }),
    ],
  );
}
 TableRow _buildQuantityRow(
  Catalog catalog,
  String color,
  int i,
  List<String> sizes,
  bool hasShades, // Add this parameter
) {
  final imageUrl = hasShades ? _getShadeImageUrl(catalog, color) : null;
  final baseStyleImageUrl = hasShades ? _getImageUrl(catalog) : '';
  final isGenerating = hasShades ? (isGeneratingAIImage[catalog.styleCode]?[color] == true) : false;

  return TableRow(
    children: [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Only show copy icon if has shades
              if (hasShades) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showShadeCopyDialog(catalog, color),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.copy_all,
                        size: 14,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        hasShades ? color : '', // Empty for no-shade
                        style: TextStyle(
                          color: hasShades ? _getColorCode(color) : Colors.transparent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Only show AI and image icons if has shades
                    if (hasShades && UserSession.imageDependsOn == 'S' && baseStyleImageUrl.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: isGenerating
                              ? null
                              : () async {
                                  await generateImageForShade(
                                    catalog,
                                    color,
                                    baseStyleImageUrl,
                                  );
                                },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: isGenerating
                                ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primaryColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: Colors.purple,
                                  ),
                          ),
                        ),
                      ),
                    if (hasShades && UserSession.imageDependsOn == 'S' && imageUrl != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageZoomScreen(
                                  imageUrls: [imageUrl],
                                  initialIndex: 0,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.image,
                              size: 12,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ...List.generate(maxSizes, (index) {
        if (index < sizes.length) {
          final size = sizes[index];
          final controller = controllersMap[catalog.styleCode]?[color]?[size];
          final originalQty = catalogItemsMap[catalog.styleCode]
              ?.firstWhere(
                (item) => item.shadeName == color && item.sizeName == size,
                orElse: () => CatalogItem(
                  styleCode: catalog.styleCode,
                  shadeName: color,
                  sizeName: size,
                  clQty: 0,
                  mrp: sizeMrpMap[catalog.styleCode]?[size] ?? 0,
                  wsp: sizeWspMap[catalog.styleCode]?[size] ?? 0,
                ),
              )
              .clQty ?? 0;

          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: originalQty > 0 ? originalQty.toString() : '0',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          );
        } else {
          return const TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Center(child: Text('')),
          );
        }
      }),
    ],
  );
}

  void _showShadeCopyDialog(Catalog catalog, String color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea (
          child:
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Copy Options for $color',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              _buildCopyOption(
                icon: Icons.copy_all,
                title: 'Copy Qty in shade only',
                description: 'Copy first quantity to all sizes in this shade',
                color: AppColors.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  final firstQty =
                      controllersMap[catalog.styleCode]?[color]
                          ?.values
                          .first
                          .text;
                  for (var size in sizesMap[catalog.styleCode] ?? []) {
                    controllersMap[catalog.styleCode]?[color]?[size]?.text =
                        firstQty ?? '0';
                  }
                  setState(() {});
                },
              ),
              _buildCopyOption(
                icon: Icons.content_copy,
                title: 'Copy Row',
                description: 'Copy this entire row',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  List<String> copiedRow = [];
                  for (var size in sizesMap[catalog.styleCode] ?? []) {
                    final qty =
                        controllersMap[catalog.styleCode]?[color]?[size]
                            ?.text ??
                        '0';
                    copiedRow.add(qty);
                  }
                  copiedRowsMap[catalog.styleCode] = copiedRow;
                  setState(() {});
                },
              ),
              _buildCopyOption(
                icon: Icons.paste,
                title: 'Paste Row',
                description: 'Paste previously copied row here',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  final copiedRow = copiedRowsMap[catalog.styleCode] ?? [];
                  for (
                    int j = 0;
                    j < (sizesMap[catalog.styleCode]?.length ?? 0);
                    j++
                  ) {
                    controllersMap[catalog.styleCode]?[color]?[sizesMap[catalog
                            .styleCode]![j]]
                        ?.text = copiedRow[j];
                  }
                  setState(() {});
                },
              ),
            ],
          ),
         ), );
        },
    );
  }

  String? _getShadeImageUrl(Catalog catalog, String shadeName) {
    if (catalog.shadeImages.isEmpty) return null;

    // Parse the shadeImages string - handle both ', ' and ',' separators
    String shadeImagesStr = catalog.shadeImages;

    // First try splitting by ', ' (comma + space)
    List<String> shadeEntries = shadeImagesStr.split(', ');

    // If that doesn't work (only one item), try splitting by ','
    if (shadeEntries.length == 1 && shadeImagesStr.contains(',')) {
      shadeEntries = shadeImagesStr.split(',');
    }

    for (var entry in shadeEntries) {
      // Trim the entry to remove any extra spaces
      entry = entry.trim();
      if (entry.isEmpty) continue;

      // Find the first ':' to split
      final colonIndex = entry.indexOf(':');
      if (colonIndex > 0) {
        final shade = entry.substring(0, colonIndex).trim().toLowerCase();
        final imageUrl = entry.substring(colonIndex + 1).trim();

        // Case-insensitive comparison and trim both strings
        if (shade.toLowerCase().trim() == shadeName.toLowerCase().trim()) {
          return imageUrl;
        }
      }
    }

    return null;
  }

  Future<void> _submitAllOrders() async {
    List<Future<http.Response>> apiCalls = [];
    List<String> apiCallStyles = [];
    final cartModel = Provider.of<CartModel>(context, listen: false);
    Set<String> processedStyles = {};

    for (var catalog in widget.catalogs) {
      final controllers = controllersMap[catalog.styleCode];
      final noteController = noteControllersMap[catalog.styleCode];
      final styleCode = styleCodeMap[catalog.styleCode] ?? '';
      final sizes = sizesMap[catalog.styleCode] ?? [];

      // Skip if the item is already in the cart
      if (cartModel.addedItems.contains(styleCode)) {
        continue;
      }

      if (controllers != null) {
        for (var colorEntry in controllers.entries) {
          String color = colorEntry.key;
          for (var sizeEntry in colorEntry.value.entries) {
            String size = sizeEntry.key;
            String qty = sizeEntry.value.text;
            if (qty.isNotEmpty &&
                int.tryParse(qty) != null &&
                int.parse(qty) > 0) {
              final payload = {
                "userId": userId,
                "coBrId": coBrId,
                "fcYrId": fcYrId,
                "data": {
                  "designcode": styleCode,
                  "mrp":
                      sizeMrpMap[catalog.styleCode]?[size]?.toStringAsFixed(
                        0,
                      ) ??
                      '0',
                  "WSP":
                      sizeWspMap[catalog.styleCode]?[size]?.toStringAsFixed(
                        0,
                      ) ??
                      '0',
                  "size": size,
                  "TotQty": getTotalQty(catalog.styleCode).toString(),
                  "Note": noteController?.text ?? '',
                  "color": color,
                  "Qty": qty,
                  "cobrid": coBrId,
                  "user": userId.toLowerCase(),
                  "barcode": "",
                },
                "typ": 0,
              };

              apiCalls.add(
                http.post(
                  Uri.parse(
                    '${AppConstants.BASE_URL}/orderBooking/Insertsalesorderdetails',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                ),
              );
              apiCallStyles.add(styleCode);
            }
          }
        }
      }
    }

    if (apiCalls.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Warning"),
                  ],
                ),
                content: const Text(
                  "No new items with valid quantities to submit.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
      return;
    }

    try {
      final responses = await Future.wait(apiCalls);
      final successfulStyles = <String>{};

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        if (response.statusCode == 200) {
          try {
            // Try parsing as JSON first
            final responseBody = jsonDecode(response.body);
            if (responseBody is Map<String, dynamic> &&
                responseBody['success'] == true) {
              successfulStyles.add(apiCallStyles[i]);
              cartModel.addItem(apiCallStyles[i]);
            }
          } catch (e) {
            // Handle plain text "Success" response
            if (response.body.trim() == "Success") {
              successfulStyles.add(apiCallStyles[i]);
              cartModel.addItem(apiCallStyles[i]);
            } else {
              print(
                'Failed to parse response for style ${apiCallStyles[i]}: $e, response: ${response.body}',
              );
            }
          }
        } else {
          print(
            'API call failed for style ${apiCallStyles[i]}: ${response.statusCode}, response: ${response.body}',
          );
        }
      }

      if (successfulStyles.isNotEmpty) {
        cartModel.updateCount(cartModel.count + successfulStyles.length);
        processedStyles = successfulStyles;
        widget.onSuccess();

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Success"),
                    ],
                  ),
                  content: Text(
                    "Successfully submitted ${successfulStyles.length} item${successfulStyles.length > 1 ? 's' : ''}.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => OrderPage(),
                        //     settings: RouteSettings(
                        //       arguments: widget.routeArguments,
                        //     ),
                        //   ),
                        // );
                      },
                      // Pop only the dialog
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Error"),
                    ],
                  ),
                  content: const Text("No items were successfully submitted."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Error"),
                  ],
                ),
                content: Text("Failed to submit orders: $e"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }
    }
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      child: CustomPaint(
        painter: _DiagonalLinePainter(),
        child: const Stack(
          children: [
            Positioned(
              left: 12,
              top: 22,
              child: Text(
                'Shade',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 22,
              child: Text(
                'Size',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
