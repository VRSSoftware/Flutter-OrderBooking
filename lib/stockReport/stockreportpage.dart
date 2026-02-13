import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/stockReportModel.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/stockReport/stockfilter.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart'; // Import StockFilterPage

class StockReportPage extends StatefulWidget {
  const StockReportPage({super.key});

  @override
  State<StockReportPage> createState() => _StockReportPageState();
}

class _StockReportPageState extends State<StockReportPage> {
  String? selectedCategoryKey;
  String? selectedCategoryName;
  String? selectedItem;

  List<Category> categories = [];
  List<Item> items = [];
  List<StockReportItem> stockReportItems = [];
  bool isLoadingCategories = true;
  bool isLoadingItems = true;
  bool isLoadingStockReport = false;
  // Filter-related state variables
  List<Style> styles = [];
  List<Shade> shades = [];
  List<Sizes> sizes = [];
  List<Brand> brands = [];
  List<Style> selectedStyles = [];
  List<Shade> selectedShades = [];
  List<Sizes> selectedSizes = [];
  List<Brand> selectedBrands = [];
  String fromMRP = '';
  String toMRP = '';
  String coBr = '';
  bool withImage = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAllItems();
    _fetchBrands();
  }

  Future<void> _fetchStockReport() async {
    if (selectedCategoryKey == null || selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both category and item')),
      );
      return;
    }

    setState(() {
      isLoadingStockReport = true;
      stockReportItems = [];
    });

    try {
      final selectedItemObj = items.firstWhere(
        (item) => item.itemName == selectedItem,
      );

      final stockReport = await ApiService.fetchStockReport(
        itemSubGrpKey: selectedCategoryKey!,
        itemKey: selectedItemObj.itemKey ?? '',
        userId: 'admin',
        fcYrId: '24',
        cobr: '01',
        brandKey:
            selectedBrands.isNotEmpty
                ? selectedBrands.map((b) => b.brandKey).join(',')
                : null,
        styleKey:
            selectedStyles.isNotEmpty
                ? selectedStyles.map((s) => s.styleKey).join(',')
                : null,
        shadeKey:
            selectedShades.isNotEmpty
                ? selectedShades.map((s) => s.shadeKey).join(',')
                : null,
        sizeKey:
            selectedSizes.isNotEmpty
                ? selectedSizes.map((s) => s.itemSizeKey).join(',')
                : null,
        fromMRP: fromMRP.isNotEmpty ? double.tryParse(fromMRP) : null,
        toMRP: toMRP.isNotEmpty ? double.tryParse(toMRP) : null,
      );

      setState(() {
        stockReportItems = stockReport;
        isLoadingStockReport = false;
      });
    } catch (e) {
      setState(() {
        isLoadingStockReport = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading stock report: $e')));
    }
  }

  String _getImageUrl(StockReportItem item) {
    if (UserSession.onlineImage == '0') {
      final imageName =
          item.fullImagePath?.split('/').last.split('?').first ?? '';
      if (imageName.isEmpty) {
        // Return default no-image URL if no valid image name found
        return '${AppConstants.BASE_URL}/images/NoImage.jpg';
      }
      return '${AppConstants.BASE_URL}/images/$imageName';
    } else if (UserSession.onlineImage == '1') {
      // Return fullImagePath if not null, else default no-image URL
      return item.fullImagePath ??
          '${AppConstants.BASE_URL}/images/NoImage.jpg';
    }
    // Default fallback to no-image URL for invalid UserSession.onlineImage values
    return '${AppConstants.BASE_URL}/images/NoImage.jpg';
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    try {
      final fetchedCategories = await ApiService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCategories = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
    }
  }

  Future<void> _fetchAllItems() async {
    setState(() {
      isLoadingItems = true;
    });
    try {
      final fetchedItems = await ApiService.fetchAllItems();
      setState(() {
        items = fetchedItems;
        isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        isLoadingItems = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    }
  }

  Future<void> _fetchItemsByCategory(String categoryKey) async {
    setState(() {
      isLoadingItems = true;
    });
    try {
      final fetchedItems = await ApiService.fetchItemsByCategory(categoryKey);
      setState(() {
        items = fetchedItems;
        isLoadingItems = false;
      });
      await _fetchStyles(categoryKey);
      await _fetchShades(categoryKey);
      await _fetchSizes(categoryKey);
    } catch (e) {
      setState(() {
        isLoadingItems = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading items: $e')));
    }
  }

  Future<void> _fetchStyles(String itemGrpKey) async {
    try {
      final fetchedStyles = await ApiService.fetchStylesByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        styles = fetchedStyles;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading styles: $e')));
    }
  }

  Future<void> _fetchShades(String itemGrpKey) async {
    try {
      final fetchedShades = await ApiService.fetchShadesByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        shades = fetchedShades;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading shades: $e')));
    }
  }

  Future<void> _fetchSizes(String itemGrpKey) async {
    try {
      final fetchedSizes = await ApiService.fetchStylesSizeByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        sizes = fetchedSizes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sizes: $e')));
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final fetchedBrands = await ApiService.fetchBrands();
      setState(() {
        brands = fetchedBrands;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading brands: $e')));
    }
  }

  void _showFilterDialog() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => StockFilterPage(),
        settings: RouteSettings(
          arguments: {
            'styles': styles,
            'shades': shades,
            'sizes': sizes,
            'brands': brands,
            'selectedStyles': selectedStyles,
            'selectedShades': selectedShades,
            'selectedSizes': selectedSizes,
            'selectedBrands': selectedBrands,
            'fromMRP': fromMRP,
            'toMRP': toMRP,
            'withImage': withImage,
          },
        ),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomRight,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );

    if (result != null) {
      Map<String, dynamic> selectedFilters = result;
      setState(() {
        selectedStyles = selectedFilters['styles'] ?? [];
        selectedShades = selectedFilters['shades'] ?? [];
        selectedSizes = selectedFilters['sizes'] ?? [];
        selectedBrands = selectedFilters['brands'] ?? [];
        fromMRP = selectedFilters['fromMRP'] ?? '';
        toMRP = selectedFilters['toMRP'] ?? '';
        withImage = selectedFilters['withImage'] ?? false;
      });

      if (selectedCategoryKey != null && selectedItem != null) {
        await _fetchStockReport();
      } else {
        setState(() {
          stockReportItems = [];
        });
        await _fetchAllItems();
      }
    }
  }

  void clearFilters() {
    setState(() {
      selectedCategoryKey = null;
      selectedCategoryName = null;
      selectedItem = null;
      selectedStyles = [];
      selectedShades = [];
      selectedSizes = [];
      selectedBrands = [];
      fromMRP = '';
      toMRP = '';
      stockReportItems = [];
    });
    _fetchAllItems();
  }

  // Helper method to group stock report items by style code
  Map<String, List<StockReportItem>> _groupItemsByStyleCode() {
    Map<String, List<StockReportItem>> groupedItems = {};
    for (var item in stockReportItems) {
      final styleCode = item.styleCode ?? 'Unknown';
      if (!groupedItems.containsKey(styleCode)) {
        groupedItems[styleCode] = [];
      }
      groupedItems[styleCode]!.add(item);
    }
    return groupedItems;
  }

  // Helper method to get unique shades for a style code
  List<String> _getShadesForStyle(List<StockReportItem> items) {
    return items.map((item) => item.shadeName ?? 'Unknown').toSet().toList();
  }

  // Helper method to get quantities for a specific shade and size
  int _getQuantityForShadeAndSize(
    List<StockReportItem> items,
    String shade,
    String size,
  ) {
    for (var item in items) {
      if (item.shadeName == shade && item.sizeName == size) {
        return item.total ?? 0;
      }
    }
    return 0;
  }

  // Helper method to get total quantity for a shade
  int _getTotalQuantityForShade(List<StockReportItem> items, String shade) {
    return items
        .where((item) => item.shadeName == shade)
        .fold(0, (sum, item) => sum + (item.total ?? 0));
  }

  // Helper method to get total quantity for a style
  int _getTotalQuantityForStyle(List<StockReportItem> items) {
    return items.fold(0, (sum, item) => sum + (item.total ?? 0));
  }

  Widget _buildStyleTable(
    String styleCode,
    List<StockReportItem> items,
    BuildContext context,
  ) {
    // Parse details to extract size-wise quantities
    Map<String, Map<String, int>> shadeSizeQuantities = {};
    List<String> allSizes = [];

    for (var item in items) {
      if (item.details != null && item.details!.isNotEmpty) {
        Map<String, int> sizeMap = {};
        List<String> sizePairs = item.details!.split(',');

        for (String pair in sizePairs) {
          List<String> parts = pair.split(':');
          if (parts.length == 2) {
            String size = parts[0].trim();
            int quantity = int.tryParse(parts[1].trim()) ?? 0;
            sizeMap[size] = quantity;

            if (!allSizes.contains(size)) {
              allSizes.add(size);
            }
          }
        }

        shadeSizeQuantities[item.shadeName ?? 'Unknown'] = sizeMap;
      }
    }

    // Sort sizes numerically
    allSizes.sort((a, b) {
      int? aNum = int.tryParse(a);
      int? bNum = int.tryParse(b);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      }
      return a.compareTo(b);
    });

    // Calculate totals
    Map<String, int> sizeTotals = {};
    int styleTotal = 0;

    for (var size in allSizes) {
      sizeTotals[size] = 0;
    }

    for (var item in items) {
      styleTotal += item.total ?? 0;

      if (shadeSizeQuantities.containsKey(item.shadeName)) {
        var sizeMap = shadeSizeQuantities[item.shadeName]!;
        for (var size in sizeMap.keys) {
          sizeTotals[size] = (sizeTotals[size] ?? 0) + (sizeMap[size] ?? 0);
        }
      }
    }

    // Get the screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Define the number of columns: "Shade" + all sizes + "Total"
    int totalColumns = 1 + allSizes.length + 1; // Shade + sizes + Total

    // Calculate the minimum width for each column
    double minColumnWidth =
        screenWidth / totalColumns; // Distribute screen width evenly
    double shadeColumnWidth = minColumnWidth.clamp(
      100,
      double.infinity,
    ); // Ensure "Shade" column is at least 100px
    double sizeColumnWidth = minColumnWidth.clamp(
      60,
      double.infinity,
    ); // Ensure size and total columns are at least 60px

    // Calculate the total width of the table content
    double totalContentWidth =
        shadeColumnWidth +
        (allSizes.length * sizeColumnWidth) +
        sizeColumnWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Style Code Header (itemName without Total)
        Container(
          width: double.infinity, // Ensure header takes full width
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF0288D1), // Vibrant teal for header
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Add image display here
              if (withImage && items.isNotEmpty)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _getImageUrl(items.first),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  '$styleCode - ${items.first.type ?? ''}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // High contrast white text
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Horizontally Scrollable Table (if needed)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  screenWidth, // Ensure the table takes at least the screen width
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Header (Shades and Sizes)
                Container(
                  color: const Color(
                    0xFF4FC3F7,
                  ), // Lighter teal for column headers
                  child: Row(
                    children: [
                      SizedBox(
                        width: shadeColumnWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Shade',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white, // White for contrast
                            ),
                          ),
                        ),
                      ),
                      ...allSizes.map(
                        (size) => SizedBox(
                          width: sizeColumnWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              size,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white, // White for contrast
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: sizeColumnWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.white, // White for contrast
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows (Shade-wise quantities)
                ...shadeSizeQuantities.entries.map((entry) {
                  String shade = entry.key;
                  Map<String, int> sizeMap = entry.value;
                  int shadeTotal =
                      items
                          .firstWhere(
                            (item) => item.shadeName == shade,
                            orElse: () => StockReportItem(),
                          )
                          .total ??
                      0;

                  return Container(
                    color:
                        Colors
                            .grey[100], // Very light grey for rows, clean and subtle
                    child: Row(
                      children: [
                        SizedBox(
                          width: shadeColumnWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              shade,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color:
                                    Colors
                                        .black87, // Consistent with card's primary text
                              ),
                            ),
                          ),
                        ),
                        ...allSizes.map(
                          (size) => SizedBox(
                            width: sizeColumnWidth,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                sizeMap[size]?.toString() ?? '0',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87, // Consistent with card
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: sizeColumnWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              shadeTotal.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors
                                        .black, // Bold and black like card's value
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Total Row for the Style
                Container(
                  color: const Color(
                    0xFFB0BEC5,
                  ), // Muted grey-blue, distinct yet cohesive
                  child: Row(
                    children: [
                      SizedBox(
                        width: shadeColumnWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'TOTAL',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87, // Strong, readable text
                            ),
                          ),
                        ),
                      ),
                      ...allSizes.map(
                        (size) => SizedBox(
                          width: sizeColumnWidth,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              sizeTotals[size]?.toString() ?? '0',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87, // Consistent and bold
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: sizeColumnWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            styleTotal.toString(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color:
                                  Colors
                                      .black, // Bold and black like card's value
                            ),
                            textAlign: TextAlign.center,
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

        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int grandTotal = 0;
    _groupItemsByStyleCode().forEach((styleCode, items) {
      grandTotal += items.fold(0, (sum, item) => sum + (item.total ?? 0));
    });
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Stock Report', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      body: Container(
        color: Colors.white, // Set background color to white
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Category Dropdown
              DropdownSearch<String>(
                items:
                    categories
                        .map((category) => category.itemSubGrpName)
                        .toList(),
                selectedItem: selectedCategoryName,
                onChanged: (value) {
                  setState(() {
                    selectedCategoryName = value;
                    selectedItem = null;
                    if (value != null) {
                      Category? selectedCategory;
                      try {
                        for (var cat in categories) {
                          if (cat.itemSubGrpName == value) {
                            selectedCategory = cat;
                            break;
                          }
                        }
                        if (selectedCategory != null) {
                          selectedCategoryKey = selectedCategory.itemSubGrpKey;
                          _fetchItemsByCategory(selectedCategoryKey!);
                        } else {
                          selectedCategoryKey = null;
                          _fetchAllItems();
                        }
                      } catch (e) {
                        selectedCategoryKey = null;
                        _fetchAllItems();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error selecting category: $e'),
                          ),
                        );
                      }
                    } else {
                      selectedCategoryKey = null;
                      _fetchAllItems();
                    }
                  });
                },
                dropdownDecoratorProps:  DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Select Category",
                    border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true, // Add this
                    fillColor: Colors.white,
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  fit: FlexFit.loose,
                  containerBuilder:
                      (context, popupWidget) => Container(
                        color: Colors.white, // Set popup background color
                        child: popupWidget,
                      ),
                  loadingBuilder:
                      isLoadingCategories
                          ? (context, searchEntry) => Center(
                            child: LoadingAnimationWidget.waveDots(
                              color: Colors.blue,
                              size: 40,
                            ),
                          )
                          : null,
                ),
              ),

              const SizedBox(height: 16),
              // Item Dropdown
              DropdownSearch<String>(
                items: items.map((item) => item.itemName).toList(),
                selectedItem: selectedItem,
                onChanged: (value) {
                  setState(() {
                    selectedItem = value;
                    if (value != null) {
                      Item? selectedItemObj;
                      try {
                        for (var item in items) {
                          if (item.itemName == value) {
                            selectedItemObj = item;
                            break;
                          }
                        }
                        if (selectedItemObj != null) {
                          String itemSubGrpKey =
                              selectedItemObj.itemSubGrpKey ?? 'default_key';
                          Category? matchingCategory;
                          for (var cat in categories) {
                            if (cat.itemSubGrpKey == itemSubGrpKey) {
                              matchingCategory = cat;
                              break;
                            }
                          }
                          if (matchingCategory != null) {
                            selectedCategoryKey =
                                matchingCategory.itemSubGrpKey;
                            selectedCategoryName =
                                matchingCategory.itemSubGrpName;
                            _fetchItemsByCategory(selectedCategoryKey!);
                          } else {
                            selectedCategoryKey = null;
                            selectedCategoryName = null;
                            _fetchAllItems();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No matching category found for the selected item',
                                ),
                              ),
                            );
                          }
                        } else {
                          selectedCategoryKey = null;
                          selectedCategoryName = null;
                          _fetchAllItems();
                        }
                      } catch (e) {
                        selectedCategoryKey = null;
                        selectedCategoryName = null;
                        _fetchAllItems();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error selecting item: $e')),
                        );
                      }
                    } else {
                      if (selectedCategoryKey == null) {
                        _fetchAllItems();
                      }
                    }
                  });
                },
                dropdownDecoratorProps:  DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: "Select Item",
                    border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true, // Add this
                    fillColor: Colors.white, // Set background color
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  fit: FlexFit.loose,
                  containerBuilder:
                      (context, popupWidget) => Container(
                        color: Colors.white, // Set popup background color
                        child: popupWidget,
                      ),
                  loadingBuilder:
                      isLoadingItems
                          ? (context, searchEntry) => Center(
                            child: LoadingAnimationWidget.waveDots(
                              color: Colors.blue,
                              size: 40,
                            ),
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 24),
         Row(
  children: [
    _buildActionButton(
      icon: Icons.visibility,
      label: "View",
      color: Colors.blue,
      onTap: _fetchStockReport,
    ),
    _buildActionButton(
      icon: Icons.download,
      label: "Download",
      color: Colors.deepPurple,
      onTap: () {},
    ),
    _buildActionButton(
      icon: FontAwesomeIcons.whatsapp,
      label: "WhatsApp",
      color: Colors.green,
      isFaIcon: true,
      onTap: () {},
    ),
    _buildActionButton(
      icon: Icons.clear,
      label: "Clear",
      color: Colors.red,
      onTap: clearFilters,
    ),
  ],
),

              const SizedBox(height: 16),
              // Stock Items Table
              Expanded(
                child:
                    isLoadingStockReport
                        ? Center(
                          child: LoadingAnimationWidget.waveDots(
                            color: Colors.blue,
                            size: 40,
                          ),
                        )
                        : stockReportItems.isEmpty
                        ? const Center(child: Text('No stock data found'))
                        : SingleChildScrollView(
                          child: Column(
                            children: [
                              // Add category name as header if available
                              if (selectedCategoryName != null &&
                                  selectedItem != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${selectedItem!.toUpperCase()} - ${selectedCategoryName!.toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                ),

                              // Group and display tables by style code
                              ..._groupItemsByStyleCode().entries.map((entry) {
                                return _buildStyleTable(
                                  entry.key,
                                  entry.value,
                                  context,
                                );
                              }).toList(),

                              if (_groupItemsByStyleCode().isNotEmpty &&
                                  selectedItem != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: const Color(
                                    0xFF0288D1,
                                  ), // Same teal as style header
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${selectedItem!.toUpperCase()} TOTAL:',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        grandTotal.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 10),
                              if (_groupItemsByStyleCode().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: const Color(
                                    0xFF1976D2,
                                  ), // Dark blue as per the image
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'GRAND TOTAL',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        grandTotal.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
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
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0), // Adjust value as needed
        child: FloatingActionButton(
          onPressed: _showFilterDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.filter_list, color: Colors.white),
          tooltip: 'Filter Options',
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen:  '/stockReport',),
      // bottomNavigationBar: BottomNavigationWidget(
      //   currentIndex: 4, // 👈 Highlight Order icon
      //   onTap: (index) {
      //     if (index == 0) Navigator.pushNamed(context, '/home');
      //     if (index == 1) Navigator.pushNamed(context, '/catalog');
      //     if (index == 2) Navigator.pushNamed(context, '/orderbooking');
      //     if (index == 3) Navigator.pushNamed(context, '/dashboard');
      //     if (index == 4) return;
      //   },
      // ),
    );
  }
Widget _buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
  bool isFaIcon = false,
}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60, // 🔥 Reduced height
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.20),
                  shape: BoxShape.circle,
                ),
                child: isFaIcon
                    ? FaIcon(icon, size: 20, color: color)
                    : Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9, // 🔥 Smaller text
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }
}
