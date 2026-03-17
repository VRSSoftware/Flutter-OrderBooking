import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as pw;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:installed_apps/installed_apps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrs_erp/catalog/dotIndicatorDesign.dart';
import 'package:vrs_erp/catalog/download_options.dart';
import 'package:vrs_erp/catalog/filter.dart';
import 'package:vrs_erp/catalog/image_zoom1.dart';
import 'package:vrs_erp/catalog/imagezoom.dart';
import 'package:vrs_erp/catalog/share_option_screen.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/catalog.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'dart:html' as html;

class CatalogPage extends StatefulWidget {
  @override
  _CatalogPageState createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String filterOption = 'New Arrival';
  int viewOption = 0;
  List<Style> selectedStyles = [];
  List<Shade> selectedShades = [];
  List<Catalog> catalogItems = [];
  List<Style> styles = [];
  List<Shade> shades = [];
  List<Sizes> sizes = [];
  String? itemKey;
  String? itemSubGrpKey;
  String? coBr;
  String? fcYrId;
  List<Catalog> selectedItems = [];
  List<Sizes> selectedSize = [];
  String fromMRP = "";
  String toMRP = "";
  String WSPto = "";
  String WSPfrom = "";
  String? itemNamee;
  bool showWSP = false;
  bool showSizes = true;
  bool showMRP = true;
  bool showShades = true;
  bool isLoading = true;
  bool showProduct = true;
  bool showRemark = true;
  bool showonlySizes = true;
  bool showFullSizeDetails = false;
  String sortBy = "";
  String fromDate = "";
  String? stockFilter;
  String? imageFilter;
  String toDate = "";
  List<Brand> brands = [];
  List<Brand> selectedBrands = [];

  bool includeDesign = true;
  bool includeShade = true;
  bool includeRate = true;
  bool includeWsp = false;
  bool includeSize = true;
  bool includeSizeMrp = true;
  bool includeSizeWsp = false;
  bool includeProduct = true;
  bool includeRemark = true;
  int total = 0;

  // Pagination variables
  int pageNo = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final int pageSize = 10; // Adjust based on backend API

  @override
  void initState() {
    super.initState();
    _loadToggleStates(); // Load toggle states from shared_preferences
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        setState(() {
          itemKey =
              args['itemKey'] == null ? null : args['itemKey']?.toString();
          itemSubGrpKey = args['itemSubGrpKey']?.toString();
          coBr = args['coBr']?.toString();
          fcYrId = args['fcYrId']?.toString();
          itemNamee = args['itemName']?.toString();
        });

        if (itemSubGrpKey != null && coBr != null) {
          _fetchCatalogItems();
        }

        if (itemKey != null) {
          _fetchStylesByItemKey(itemKey!);
          _fetchShadesByItemKey(itemKey!);
          _fetchStylesSizeByItemKey(itemKey!);
          _fetchBrands();
        } else if (itemSubGrpKey != null) {
          _fetchStylesByItemGrpKey(itemSubGrpKey!);
          _fetchShadesByItemGrpKey(itemSubGrpKey!);
          _fetchStylesSizeByItemGrpKey(itemSubGrpKey!);
          _fetchBrands();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      if (catalogItems.length <= total) {
        setState(() {
          hasMore = true;
        });
      } else {
        setState(() {
          hasMore = false;
        });
      }
      // Fetch next page when user scrolls near the bottom
      setState(() {
        isLoadingMore = true;
        pageNo++;
      });
      _fetchCatalogItems();
    }
  }

  // Add this helper function to your class
  Future<void> _showMessageDialog(
    String message, {
    bool isError = false,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isError ? 'Error' : 'Success',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadToggleStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      includeDesign = prefs.getBool('includeDesign') ?? true;
      includeShade = prefs.getBool('includeShade') ?? true;
      includeRate = prefs.getBool('includeRate') ?? true;
      includeWsp = prefs.getBool('includeWsp') ?? false;
      includeSize = prefs.getBool('includeSize') ?? true;
      includeSizeMrp = prefs.getBool('includeSizeMrp') ?? true;
      includeSizeWsp = prefs.getBool('includeSizeWsp') ?? false;
      includeProduct = prefs.getBool('includeProduct') ?? true;
      includeRemark = prefs.getBool('includeRemark') ?? true;
    });
  }

  Future<void> _saveToggleStates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('includeDesign', includeDesign);
    await prefs.setBool('includeShade', includeShade);
    await prefs.setBool('includeRate', includeRate);
    await prefs.setBool('includeWsp', includeWsp);
    await prefs.setBool('includeSize', includeSize);
    await prefs.setBool('includeSizeMrp', includeSizeMrp);
    await prefs.setBool('includeSizeWsp', includeSizeWsp);
    await prefs.setBool('includeProduct', includeProduct);
    await prefs.setBool('includeRemark', includeRemark);
  }

  Future<void> _fetchBrands() async {
    brands = await ApiService.fetchBrands();
    setState(() {});
  }

  String _getSizeText(Catalog item) {
    if (showMRP && showWSP && showFullSizeDetails) {
      return item.sizeDetails;
    }
    if (!showMRP) {
      return showWSP
          ? _extractWspSizes(item.sizeDetailsWithoutWSp)
          : item.onlySizes;
    }
    return showWSP ? item.sizeDetailsWithoutWSp : item.sizeWithMrp;
  }

  String _extractWspSizes(String sizeDetails) {
    try {
      List<String> sizeEntries = sizeDetails.split(', ');
      List<String> wspSizes = [];
      for (String entry in sizeEntries) {
        List<String> parts = entry.split(' (');
        if (parts.length >= 2) {
          String size = parts[0];
          String values = parts[1].replaceAll(')', '');
          List<String> mrpWsp = values.split(',');
          if (mrpWsp.length >= 2) {
            String wsp = mrpWsp[1].trim();
            wspSizes.add('$size : $wsp');
          }
        }
      }
      return wspSizes.join(', ');
    } catch (e) {
      return "Size info unavailable";
    }
  }

  Future<void> _fetchCatalogItems() async {
    try {
      if (pageNo == 1) {
        setState(() {
          catalogItems = [];
          isLoading = true;
          hasMore = true;
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final result = await ApiService.fetchCatalogItem(
        itemSubGrpKey: itemSubGrpKey!,
        itemKey: itemKey,
        cobr: coBr!,
        sortBy: sortBy,
        styleKey:
            selectedStyles.isEmpty
                ? null
                : selectedStyles.map((s) => s.styleKey).join(','),
        shadeKey:
            selectedShades.isEmpty
                ? null
                : selectedShades.map((s) => s.shadeKey).join(','),
        sizeKey:
            selectedSize.isEmpty
                ? null
                : selectedSize.map((s) => s.itemSizeKey).join(','),
        fromMRP: fromMRP == "" ? null : fromMRP,
        toMRP: toMRP == "" ? null : toMRP,
        fromDate: fromDate == "" ? null : fromDate,
        toDate: toDate == "" ? null : toDate,
        brandKey: selectedBrands.isEmpty ? null : selectedBrands[0].brandKey,
        stockFilter: stockFilter == "" ? null : stockFilter, // ADD THIS
        imageFilter: imageFilter == "" ? null : imageFilter, // ADD THIS
        pageNo: pageNo,
      );

      final List<Catalog> items = result["catalogs"] as List<Catalog>;
      if (!mounted) return;
      setState(() {
        catalogItems.addAll(items);
        total = result["total"] ?? items.length;
        isLoading = false;
        isLoadingMore = false;
        hasMore = items.length >= pageSize;
      });
    } catch (e) {
      debugPrint('Failed to load catalog items: $e');
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }
  // Future<void> _fetchStylesByItemGrpKey(String itemKey) async {
  //   try {
  //     final fetchedStyles = await ApiService.fetchStylesByItem(itemKey);
  //     setState(() {
  //       styles = fetchedStyles;
  //     });
  //   } catch (e) {
  //     print('Failed to load styles: $e');
  //   }
  // }

  Future<void> _fetchStylesByItemKey(String itemKey) async {
    try {
      final fetchedStyles = await ApiService.fetchStylesByItemKey(itemKey);
      setState(() {
        styles = fetchedStyles;
      });
    } catch (e) {
      print('Failed to load styles: $e');
    }
  }

  Future<void> _fetchStylesByItemGrpKey(String itemGrpKey) async {
    try {
      final fetchedStyles = await ApiService.fetchStylesByItemGrpKey(
        itemGrpKey,
      );
      setState(() {
        styles = fetchedStyles;
      });
    } catch (e) {
      print('Failed to load styles: $e');
    }
  }

  Future<void> _fetchShadesByItemKey(String itemKey) async {
    try {
      final fetchedShades = await ApiService.fetchShadesByItemKey(itemKey);
      setState(() {
        shades = fetchedShades;
      });
    } catch (e) {
      print('Failed to load shades: $e');
    }
  }

  Future<void> _fetchShadesByItemGrpKey(String itemKey) async {
    try {
      final fetchedShades = await ApiService.fetchShadesByItemGrpKey(itemKey);
      setState(() {
        shades = fetchedShades;
      });
    } catch (e) {
      print('Failed to load shades: $e');
    }
  }

  Future<void> _fetchStylesSizeByItemKey(String itemKey) async {
    try {
      if (itemKey != null) {
        final fetchedSizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
        setState(() {
          sizes = fetchedSizes;
        });
      } else if (itemSubGrpKey != null) {
        final fetchedSizes = await ApiService.fetchStylesSizeByItemGrpKey(
          itemSubGrpKey!,
        );
        setState(() {
          sizes = fetchedSizes;
        });
      }
    } catch (e) {
      print('Failed to load sizes: $e');
    }
  }

  Future<void> _fetchStylesSizeByItemGrpKey(String itemKey) async {
    try {
      if (itemKey != null) {
        final fetchedSizes = await ApiService.fetchStylesSizeByItemKey(itemKey);
        setState(() {
          sizes = fetchedSizes;
        });
      } else if (itemSubGrpKey != null) {
        final fetchedSizes = await ApiService.fetchStylesSizeByItemGrpKey(
          itemSubGrpKey!,
        );
        setState(() {
          sizes = fetchedSizes;
        });
      }
    } catch (e) {
      print('Failed to load sizes: $e');
    }
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (selectedStyles.isNotEmpty) count++;
    if (selectedShades.isNotEmpty) count++;
    if (selectedSize.isNotEmpty) count++;
    if (selectedBrands.isNotEmpty) count++;
    if (fromMRP.isNotEmpty || toMRP.isNotEmpty) count++;
    if (WSPfrom.isNotEmpty || WSPto.isNotEmpty) count++;
    if (fromDate.isNotEmpty || toDate.isNotEmpty) count++;
    if (sortBy != null && sortBy!.isNotEmpty) count++;
    if (stockFilter != null && stockFilter!.isNotEmpty && stockFilter != '')
      count++;
    if (imageFilter != null && imageFilter!.isNotEmpty && imageFilter != 'All')
      count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Existing build method remains unchanged...
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          toTitleCase(itemNamee ?? ''),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.download, color: Colors.white),
              onPressed: _showDownloadOptions,
            ),
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: _showShareOptions,
            ),
          IconButton(
            icon: Icon(
              viewOption == 0
                  ? CupertinoIcons.list_bullet_below_rectangle
                  : viewOption == 1
                  ? CupertinoIcons.rectangle_expand_vertical
                  : CupertinoIcons.square_grid_2x2_fill,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                viewOption = (viewOption + 1) % 3;
              });
            },
          ),
          Builder(
            builder:
                (context) => IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width > 600
                                    ? 24.0
                                    : 20.0,
                              ),
                              child: StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width >
                                                    600
                                                ? 600
                                                : 440,
                                        minWidth: 320,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header with icon and title
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryColor
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.tune_rounded,
                                                  color: AppColors.primaryColor,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Options",
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 22
                                                          : 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              // Close button
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.grey.shade700,
                                                    size: 18,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          // Options
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isWide =
                                                  constraints.maxWidth > 400;
                                              return isWide
                                                  ? Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          children: [
                                                            _buildToggleRow(
                                                              "Show MRP",
                                                              showMRP,
                                                              (val) {
                                                                showMRP = val;
                                                                setStateDialog(
                                                                  () {},
                                                                );
                                                              },
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            _buildToggleRow(
                                                              "Show WSP",
                                                              showWSP,
                                                              (val) {
                                                                showWSP = val;
                                                                setStateDialog(
                                                                  () {},
                                                                );
                                                              },
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            _buildToggleRow(
                                                              "Show Product",
                                                              showProduct,
                                                              (val) {
                                                                showProduct =
                                                                    val;
                                                                setStateDialog(
                                                                  () {},
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          children: [
                                                            _buildSizeToggleRow(
                                                              setState,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            _buildToggleRow(
                                                              "Show Shades",
                                                              showShades,
                                                              (val) {
                                                                showShades =
                                                                    val;
                                                                setStateDialog(
                                                                  () {},
                                                                );
                                                              },
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            _buildToggleRow(
                                                              "Show Remark",
                                                              showRemark,
                                                              (val) {
                                                                showRemark =
                                                                    val;
                                                                setStateDialog(
                                                                  () {},
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                  : Column(
                                                    children: [
                                                      _buildToggleRow(
                                                        "Show MRP",
                                                        showMRP,
                                                        (val) {
                                                          showMRP = val;
                                                          setStateDialog(() {});
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildToggleRow(
                                                        "Show WSP",
                                                        showWSP,
                                                        (val) {
                                                          showWSP = val;
                                                          setStateDialog(() {});
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildSizeToggleRow(
                                                        setState,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildToggleRow(
                                                        "Show Shades",
                                                        showShades,
                                                        (val) {
                                                          showShades = val;
                                                          setStateDialog(() {});
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildToggleRow(
                                                        "Show Product",
                                                        showProduct,
                                                        (val) {
                                                          showProduct = val;
                                                          setStateDialog(() {});
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildToggleRow(
                                                        "Show Remark",
                                                        showRemark,
                                                        (val) {
                                                          showRemark = val;
                                                          setStateDialog(() {});
                                                        },
                                                      ),
                                                    ],
                                                  );
                                            },
                                          ),

                                          const SizedBox(height: 24),

                                          // Action Buttons
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.grey.shade700,
                                                    side: BorderSide(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primaryColor,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Apply',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 16.0 : 8.0,
                vertical: 8.0,
              ),
              child:
                  isLoading
                      ? Center(
                        child: LoadingAnimationWidget.waveDots(
                          color: AppColors.primaryColor,
                          size: 30,
                        ),
                      )
                      : catalogItems.isEmpty
                      ? Center(child: Text("No Item Available"))
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          if (viewOption == 0) {
                            return _buildListView(constraints, isLargeScreen);
                          } else if (viewOption == 1) {
                            return _buildExpandedView(isLargeScreen);
                          }
                          return _buildGridView(
                            constraints,
                            isLargeScreen,
                            isPortrait,
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            onPressed: _showFilterDialog,
            backgroundColor:
                _getActiveFilterCount() > 0
                    ? Colors.pink
                    : AppColors.primaryColor,
            child: Icon(Icons.filter_alt_outlined, color: Colors.white),
            tooltip: 'Filter',
          ),
          if (_getActiveFilterCount() > 0)
            Positioned(
              right: 0,
              top: -5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '${_getActiveFilterCount()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: BottomNavigationWidget(currentScreen: '/catalog'),
      // bottomNavigationBar: BottomNavigationWidget(
      //   currentIndex: 1,
      //   onTap: (index) {
      //     if (index == 0) Navigator.pushNamed(context, '/home');
      //     if (index == 1) return;
      //     if (index == 2) Navigator.pushNamed(context, '/orderbooking');
      //   },
      // ),
    );
  }

  Widget _buildGridView(
    BoxConstraints constraints,
    bool isLargeScreen,
    bool isPortrait,
  ) {
    final filteredItems = _getFilteredItems();
    final crossAxisCount =
        isPortrait
            ? (isLargeScreen ? 3 : 2)
            : (constraints.maxWidth ~/ 300).clamp(3, 4);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isLargeScreen ? 14.0 : 8.0,
        mainAxisSpacing: isLargeScreen ? 1.0 : 8.0,
        childAspectRatio: _getChildAspectRatio(constraints, isLargeScreen),
      ),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primaryColor,
              size: 30,
            ),
          );
        }
        final item = filteredItems[index];
        return GestureDetector(
          onDoubleTap: () => _openImageZoom(context, item),
          child: _buildItemCard(item, isLargeScreen),
        );
      },
    );
  }

  double _getChildAspectRatio(BoxConstraints constraints, bool isLargeScreen) {
    if (constraints.maxWidth > 1000) return isLargeScreen ? 0.35 : 0.4;
    if (constraints.maxWidth > 400) return isLargeScreen ? 0.4 : 0.35;
    return 0.4;
  }

  Widget _buildListView(BoxConstraints constraints, bool isLargeScreen) {
    final filteredItems = _getFilteredItems();

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primaryColor,
              size: 30,
            ),
          );
        }

        final item = filteredItems[index];
        bool isSelected = selectedItems.contains(item);

        List<String> shades =
            item.shadeName.isNotEmpty
                ? item.shadeName
                    .split(',')
                    .map((shade) => shade.trim())
                    .toList()
                : [];

        final imageUrls = _getImageUrl(item);
        final ValueNotifier<int> currentImageIndex = ValueNotifier<int>(0);

        return GestureDetector(
          onDoubleTap: () {
            _openImageZoom1(
              context,
              item,
              showShades: showShades,
              showMRP: showMRP,
              showWSP: showWSP,
              showSizes: showSizes,
              showProduct: showProduct,
              showRemark: showRemark,
              isLargeScreen: isLargeScreen,
            );
          },
          onLongPress: () => _toggleItemSelection(item),
          onTap: () {
            if (selectedItems.isNotEmpty) _toggleItemSelection(item);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: isSelected ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isSelected ? Colors.blue.shade50 : Colors.white,
              child: Stack(
                children: [
                  // Left curved color strip
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 12.0 : 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column with image and range
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image section
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxImageHeight =
                                        constraints.maxWidth * 1.2;

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: maxImageHeight,
                                      ),
                                      child:
                                          imageUrls.isNotEmpty &&
                                                  imageUrls[0].isNotEmpty
                                              ? Stack(
                                                children: [
                                                  SizedBox(
                                                    height: maxImageHeight,
                                                    width: double.infinity,
                                                    child: PageView.builder(
                                                      itemCount:
                                                          imageUrls.length,
                                                      onPageChanged: (index) {
                                                        currentImageIndex
                                                            .value = index;
                                                      },
                                                      itemBuilder: (
                                                        context,
                                                        index,
                                                      ) {
                                                        final imageUrl =
                                                            imageUrls[index];
                                                        return _buildSingleImage(
                                                          imageUrl,
                                                          maxImageHeight,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  if (imageUrls.length > 1)
                                                    Positioned(
                                                      bottom: 8,
                                                      left: 0,
                                                      right: 0,
                                                      child: ValueListenableBuilder<
                                                        int
                                                      >(
                                                        valueListenable:
                                                            currentImageIndex,
                                                        builder: (
                                                          context,
                                                          index,
                                                          child,
                                                        ) {
                                                          return DotIndicator(
                                                            count:
                                                                imageUrls
                                                                    .length,
                                                            currentIndex: index,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                ],
                                              )
                                              : _buildSingleImage(
                                                '',
                                                maxImageHeight,
                                              ),
                                    );
                                  },
                                ),
                              ),

                              // Range text below the image (only if showMRP is true)
                              if (showMRP &&
                                  item.minMRP != null &&
                                  item.maxMRP != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    left: 4.0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${item.minMRP} - ${item.maxMRP}',
                                          style: TextStyle(
                                            fontSize: isLargeScreen ? 12 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: isLargeScreen ? 16 : 8),

                        // Right column with details table
                        Flexible(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(
                                  isLargeScreen ? 16 : 12,
                                ),
                                child: Table(
                                  columnWidths: const {
                                    0: IntrinsicColumnWidth(),
                                    1: FixedColumnWidth(8),
                                    2: FlexColumnWidth(),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: [
                                    TableRow(
                                      children: [
                                        _buildLabelText('Design'),
                                        const Text(':'),
                                        Text(
                                          item.styleCodeWithcount,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isLargeScreen ? 20 : 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildSpacerRow(),
                                    if (showShades && shades.isNotEmpty)
                                      TableRow(
                                        children: [
                                          _buildLabelText('Shade'),
                                          const Text(':'),
                                          Text(
                                            shades.join(', '),
                                            style: TextStyle(
                                              fontSize: isLargeScreen ? 14 : 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (showShades && shades.isNotEmpty)
                                      _buildSpacerRow(),
                                    if (showMRP)
                                      TableRow(
                                        children: [
                                          _buildLabelText('MRP'),
                                          const Text(':'),
                                          Text(
                                            item.mrp.toStringAsFixed(2),
                                            style: _valueTextStyle(),
                                          ),
                                        ],
                                      ),
                                    if (showMRP) _buildSpacerRow(),

                                    // REMOVE THE RANGE ROW FROM HERE (it's now below the image)
                                    // if (showMRP &&
                                    //     item.minMRP != null &&
                                    //     item.maxMRP != null)
                                    //   TableRow(...), // Remove this entire block
                                    // if (showMRP &&
                                    //     item.minMRP != null &&
                                    //     item.maxMRP != null)
                                    //   _buildSpacerRow(), // Remove this too
                                    if (showWSP)
                                      TableRow(
                                        children: [
                                          _buildLabelText('WSP'),
                                          const Text(':'),
                                          Text(
                                            item.wsp.toStringAsFixed(2),
                                            style: _valueTextStyle(),
                                          ),
                                        ],
                                      ),
                                    if (showWSP) _buildSpacerRow(),
                                    if (item.sizeName.isNotEmpty && showSizes)
                                      TableRow(
                                        children: [
                                          _buildLabelText('Size'),
                                          const Text(':'),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              _getSizeText(item),
                                              style: _valueTextStyle(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (item.sizeName.isNotEmpty && showSizes)
                                      _buildSpacerRow(),
                                    if (showProduct)
                                      TableRow(
                                        children: [
                                          _buildLabelText('Product'),
                                          const Text(':'),
                                          Text(
                                            item.itemName,
                                            style: _valueTextStyle(),
                                          ),
                                        ],
                                      ),
                                    if (showProduct) _buildSpacerRow(),
                                    if (showRemark)
                                      TableRow(
                                        children: [
                                          _buildLabelText('Remark'),
                                          const Text(':'),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              item.remark?.trim().isNotEmpty ==
                                                      true
                                                  ? item.remark!
                                                  : '--',
                                              style: _valueTextStyle(),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedView(bool isLargeScreen) {
    final filteredItems = _getFilteredItems();
    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primaryColor,
              size: 30,
            ),
          );
        }
        final item = filteredItems[index];
        final isSelected = selectedItems.contains(item);
        final shades = item.shadeName.split(',').map((s) => s.trim()).toList();
        final imageUrls = _getImageUrl(item);
        print('Image URLs: $imageUrls');
        final ValueNotifier<int> currentImageIndex = ValueNotifier<int>(0);

        return GestureDetector(
          onDoubleTap: () {
            _openImageZoom1(
              context,
              item,
              showShades: showShades,
              showMRP: showMRP,
              showWSP: showWSP,
              showSizes: showSizes,
              showProduct: showProduct,
              showRemark: showRemark,
              isLargeScreen: isLargeScreen,
            );
          },
          onLongPress: () => _toggleItemSelection(item),
          onTap: () {
            if (selectedItems.isNotEmpty) _toggleItemSelection(item);
          },
          child: Card(
            elevation: isSelected ? 8 : 4,
            margin: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: isLargeScreen ? 16 : 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(0),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxImageHeight = constraints.maxWidth * 1.2;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: maxImageHeight,
                              minHeight: constraints.maxWidth,
                            ),
                            child:
                                imageUrls.isNotEmpty && imageUrls[0].isNotEmpty
                                    ? Stack(
                                      children: [
                                        SizedBox(
                                          height: maxImageHeight,
                                          width: double.infinity,
                                          child: PageView.builder(
                                            itemCount: imageUrls.length,
                                            onPageChanged: (index) {
                                              currentImageIndex.value = index;
                                            },
                                            itemBuilder: (context, index) {
                                              final imageUrl = imageUrls[index];
                                              return _buildSingleImage(
                                                imageUrl,
                                                maxImageHeight,
                                              );
                                            },
                                          ),
                                        ),
                                        if (imageUrls.length > 1)
                                          Positioned(
                                            bottom: 8,
                                            left: 0,
                                            right: 0,
                                            child: ValueListenableBuilder<int>(
                                              valueListenable:
                                                  currentImageIndex,
                                              builder: (context, index, child) {
                                                return DotIndicator(
                                                  count: imageUrls.length,
                                                  currentIndex: index,
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    )
                                    : _buildSingleImage('', maxImageHeight),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                      child: Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FixedColumnWidth(8),
                          2: FlexColumnWidth(),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            children: [
                              Text(
                                'Design',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(':'),
                              Text(
                                item.styleCodeWithcount,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isLargeScreen ? 20 : 16,
                                ),
                              ),
                            ],
                          ),
                          _buildSpacerRow(),
                          if (showShades && shades.isNotEmpty)
                            TableRow(
                              children: [
                                Text(
                                  'Shade',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(':'),
                                Text(
                                  shades.join(', '),
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 14 : 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          if (showShades && shades.isNotEmpty)
                            _buildSpacerRow(),
                          if (showMRP)
                            TableRow(
                              children: [
                                Text(
                                  'MRP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(':'),
                                Text(
                                  item.mrp.toStringAsFixed(2),
                                  style: _valueTextStyle(),
                                ),
                              ],
                            ),
                          if (showMRP) _buildSpacerRow(),
                          if (showMRP &&
                              item.minMRP != null &&
                              item.maxMRP != null)
                            TableRow(
                              children: [
                                Text(
                                  'Range',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(':'),
                                Text(
                                  '${item.minMRP} - ${item.maxMRP}',
                                  style: _valueTextStyle(),
                                ),
                              ],
                            ),
                          if (showMRP &&
                              item.minMRP != null &&
                              item.maxMRP != null)
                            _buildSpacerRow(),
                          if (showWSP)
                            TableRow(
                              children: [
                                Text(
                                  'WSP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(':'),
                                Text(
                                  item.wsp.toStringAsFixed(2),
                                  style: _valueTextStyle(),
                                ),
                              ],
                            ),
                          if (showWSP) _buildSpacerRow(),
                          if (item.sizeName.isNotEmpty && showSizes)
                            TableRow(
                              children: [
                                Text(
                                  'Size',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(':'),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    _getSizeText(item),
                                    style: _valueTextStyle(),
                                  ),
                                ),
                              ],
                            ),
                          if (item.sizeName.isNotEmpty && showSizes)
                            _buildSpacerRow(),
                          if (showProduct)
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Text(
                                    'Product',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Text(':'),
                                Text(item.itemName, style: _valueTextStyle()),
                              ],
                            ),
                          if (showProduct) _buildSpacerRow(),
                          if (showRemark)
                            TableRow(
                              children: [
                                Text(
                                  'Remark',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Text(':'),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    item.remark?.trim().isNotEmpty == true
                                        ? item.remark!
                                        : '--',
                                    style: _valueTextStyle(),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelText(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  TextStyle _valueTextStyle() {
    return TextStyle(color: Colors.grey[800], fontSize: 14);
  }

  TableRow _buildSpacerRow() {
    return const TableRow(
      children: [SizedBox(height: 8), SizedBox(height: 8), SizedBox(height: 8)],
    );
  }

  Widget _buildDetailText(String label, String value, bool isLargeScreen) {
    return AutoSizeText.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
      maxLines: 1,
      minFontSize: 10,
      style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
      overflow: TextOverflow.ellipsis,
    );
  }

  void _openImageZoom1(
    BuildContext context,
    Catalog item, {
    required bool showShades,
    required bool showMRP,
    required bool showWSP,
    required bool showSizes,
    required bool showProduct,
    required bool showRemark,
    required bool isLargeScreen,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ImageZoomScreen1(
              imageUrls: _getImageUrl(item),
              item: item,
              showShades: showShades,
              showMRP: showMRP,
              showWSP: showWSP,
              showSizes: showSizes,
              showProduct: showProduct,
              showRemark: showRemark,
              isLargeScreen: isLargeScreen,
            ),
      ),
    );
  }

  void _openImageZoom(BuildContext context, Catalog item) {
    final imageUrls = _getImageUrl(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageZoomScreen(imageUrls: imageUrls),
      ),
    );
  }

  Widget _buildItemCard(Catalog item, bool isLargeScreen) {
    bool isSelected = selectedItems.contains(item);
    List<String> shades =
        item.shadeName.split(',').map((s) => s.trim()).toList();
    final imageUrls = _getImageUrl(item);
    print('Image URLs before use: $imageUrls');
    final ValueNotifier<int> currentImageIndex = ValueNotifier<int>(0);

    return GestureDetector(
      onDoubleTap: () {
        _openImageZoom1(
          context,
          item,
          showShades: showShades,
          showMRP: showMRP,
          showWSP: showWSP,
          showSizes: showSizes,
          showProduct: showProduct,
          showRemark: showRemark,
          isLargeScreen: isLargeScreen,
        );
      },
      onLongPress: () => _toggleItemSelection(item),
      onTap: () {
        if (selectedItems.isNotEmpty) _toggleItemSelection(item);
      },
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxImageHeight = constraints.maxWidth * 1.2;
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: maxImageHeight),
                        child:
                            imageUrls.isNotEmpty && imageUrls[0].isNotEmpty
                                ? Stack(
                                  children: [
                                    SizedBox(
                                      height: maxImageHeight,
                                      child: PageView.builder(
                                        itemCount: imageUrls.length,
                                        onPageChanged: (index) {
                                          currentImageIndex.value = index;
                                        },
                                        itemBuilder: (context, index) {
                                          final imageUrl = imageUrls[index];
                                          return _buildSingleImage(
                                            imageUrl,
                                            maxImageHeight,
                                          );
                                        },
                                      ),
                                    ),
                                    if (imageUrls.length > 1)
                                      Positioned(
                                        bottom: 8,
                                        left: 0,
                                        right: 0,
                                        child: ValueListenableBuilder<int>(
                                          valueListenable: currentImageIndex,
                                          builder: (context, index, child) {
                                            return DotIndicator(
                                              count: imageUrls.length,
                                              currentIndex: index,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                )
                                : _buildSingleImage('', maxImageHeight),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FixedColumnWidth(8),
                      2: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          _buildLabelText('Design'),
                          const Text(':'),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              item.styleCodeWithcount,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: isLargeScreen ? 20 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildSpacerRow(),
                      if (showShades && shades.isNotEmpty)
                        TableRow(
                          children: [
                            _buildLabelText('Shade'),
                            const Text(':'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                shades.join(', '),
                                style: TextStyle(
                                  fontSize: isLargeScreen ? 14 : 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (showShades && shades.isNotEmpty) _buildSpacerRow(),
                      if (showMRP)
                        TableRow(
                          children: [
                            _buildLabelText('MRP'),
                            const Text(':'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                item.mrp.toStringAsFixed(2),
                                style: _valueTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      if (showMRP) _buildSpacerRow(),
                      if (showMRP && item.minMRP != null && item.maxMRP != null)
                        TableRow(
                          children: [
                            _buildLabelText('Range'),
                            const Text(':'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                '${item.minMRP} - ${item.maxMRP}',
                                style: _valueTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      if (showMRP && item.minMRP != null && item.maxMRP != null)
                        _buildSpacerRow(),
                      if (showWSP)
                        TableRow(
                          children: [
                            _buildLabelText('WSP'),
                            const Text(':'),
                            Text(
                              item.wsp.toStringAsFixed(2),
                              style: _valueTextStyle(),
                            ),
                          ],
                        ),
                      if (showWSP) _buildSpacerRow(),
                      if (item.sizeName.isNotEmpty && showSizes)
                        TableRow(
                          children: [
                            _buildLabelText('Size'),
                            const Text(':'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                _getSizeText(item),
                                style: _valueTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      if (item.sizeName.isNotEmpty && showSizes)
                        _buildSpacerRow(),
                      if (showProduct)
                        TableRow(
                          children: [
                            _buildLabelText('Product'),
                            const Text(':'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                item.itemName,
                                style: _valueTextStyle(),
                              ),
                            ),
                          ],
                        ),
                      if (showProduct) _buildSpacerRow(),
                      if (showRemark)
                        TableRow(
                          children: [
                            _buildLabelText('Remark'),
                            const Text(':'),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                item.remark?.trim().isNotEmpty == true
                                    ? item.remark!
                                    : '--',
                                style: _valueTextStyle(),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImage(String imageUrl, double maxHeight) {
    return SizedBox(
      height: maxHeight,
      width: double.infinity,
      child: Center(
        child:
            imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  cacheWidth: 800,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.error)),
                    );
                  },
                )
                : Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
      ),
    );
  }

  Widget _buildBottomButtons(bool isLargeScreen) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 24 : 12,
          vertical: 12,
        ),
        color: Colors.white,
        child:
            isLargeScreen
                ? Row(children: _buildButtonChildren(isLargeScreen))
                : Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildButtonChildren(isLargeScreen),
                ),
      ),
    );
  }

  List<Widget> _buildButtonChildren(bool isLargeScreen) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showFilterDialog,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryColor),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 24 : 16,
                  vertical: 12,
                ),
              ),
              icon: Icon(Icons.filter_list, size: isLargeScreen ? 24 : 20),
              label: Text(
                'Filter',
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildFilterButton(String label, bool isLargeScreen) {
    return OutlinedButton(
      onPressed: () => setState(() => filterOption = label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: filterOption == label ? AppColors.primaryColor : Colors.grey,
        ),
        backgroundColor: Colors.white,
        foregroundColor:
            filterOption == label ? AppColors.primaryColor : Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(
          vertical: isLargeScreen ? 16 : 12,
          horizontal: isLargeScreen ? 24 : 16,
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: isLargeScreen ? 16 : 14)),
    );
  }

  List<Catalog> _getFilteredItems() {
    return catalogItems;
  }

  // String _getImageUrl(Catalog catalog) {
  //   if (UserSession.onlineImage == '1') {
  //     // fullImagePath is already a full URL, return as is or empty string if null
  //     return catalog.fullImagePath ?? '';
  //   } else if (UserSession.onlineImage == '0') {
  //     // Extract image name from fullImagePath safely
  //     final fullPath = catalog.fullImagePath ?? '';
  //     if (fullPath.isEmpty) return '';
  //     final imageName = fullPath.split('/').last.split('?').first;
  //     if (imageName.isEmpty) return '';
  //     return '${AppConstants.BASE_URL}/images/$imageName';
  //   }
  //   // Fallback for invalid onlineImage values
  //   return '';
  // }

  List<String> _getImageUrl(Catalog catalog) {
    final shadeImages = catalog.shadeImages ?? '';
    final fullImagePath = catalog.fullImagePath ?? '';

    print('ShadeImages for catalog ${catalog.styleCode}: $shadeImages');
    print('fullImagePath for catalog ${catalog.styleCode}: $fullImagePath');
    print('Base URL: ${AppConstants.BASE_URL}');
    print('imageDependsOn: ${UserSession.imageDependsOn}');

    List<String> imageUrls = [];

    // Always add full image path first if it exists
    if (fullImagePath.isNotEmpty) {
      if (UserSession.onlineImage == '1') {
        // fullImagePath is already a full URL
        imageUrls.add(fullImagePath);
      } else {
        // Extract image name and construct URL
        final fileName =
            fullImagePath.split('/').last.split('\\').last.split('?').first;
        if (fileName.isNotEmpty) {
          final url = '${AppConstants.BASE_URL}/images/$fileName';
          imageUrls.add(url);
        }
      }
    }

    // Add shade images if imageDependsOn == 'S' and shadeImages exist
    if (UserSession.imageDependsOn == 'S' && shadeImages.isNotEmpty) {
      final imageEntries =
          shadeImages.split(',').map((entry) => entry.trim()).toList();

      for (var entry in imageEntries) {
        final parts = entry.split(':');
        if (parts.length < 2) continue;

        final path = parts.sublist(1).join(':').trim();
        if (path.isEmpty) continue;

        final fileName = path.split('/').last.split('\\').last;
        if (fileName.isEmpty) continue;

        final url = '${AppConstants.BASE_URL}/images/$fileName';
        imageUrls.add(url);
      }
    }

    // If no images were added, return a placeholder
    if (imageUrls.isEmpty) {
      return [''];
    }

    return imageUrls;
  }

  void _showFilterDialog() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FilterPage(),
        settings: RouteSettings(
          arguments: {
            'itemKey': itemKey,
            'itemSubGrpKey': itemSubGrpKey,
            'coBr': coBr,
            'fcYrId': fcYrId,
            'styles': styles,
            'shades': shades,
            'sizes': sizes,
            'selectedShades': selectedShades,
            'selectedSizes': selectedSize,
            'selectedStyles': selectedStyles,
            'selectedBrands': selectedBrands, // ADD THIS
            'fromMRP': fromMRP,
            'toMRP': toMRP,
            'WSPfrom': WSPfrom,
            'WSPto': WSPto,
            'sortBy': sortBy,
            'fromDate': fromDate,
            'toDate': toDate,
            'brands': brands.isEmpty ? [] : brands,
            'stockFilter': stockFilter, // ADD THIS
            'imageFilter': imageFilter, // ADD THIS
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
      setState(() {
        selectedStyles = result['styles'] ?? [];
        selectedSize = result['sizes'] ?? [];
        selectedShades = result['shades'] ?? [];
        selectedBrands = result['brands'] ?? []; // ADD THIS
        fromMRP = result['fromMRP'] ?? "";
        toMRP = result['toMRP'] ?? "";
        WSPfrom = result['WSPfrom'] ?? "";
        WSPto = result['WSPto'] ?? "";
        sortBy = result['sortBy'];
        fromDate = result['fromDate'] ?? "";
        toDate = result['toDate'] ?? "";
        stockFilter = result['stockFilter']; // ADD THIS
        imageFilter = result['imageFilter']; // ADD THIS

        // Reset pagination
        pageNo = 1;
        catalogItems = [];
        hasMore = true;
      });

      _fetchCatalogItems();
    }
  }

Future<void> _shareSelectedItemsPDF({
  required String shareType,
  bool includeDesign = true,
  bool includeShade = true,
  bool includeRate = true,
  bool includeWsp = true,
  bool includeSize = true,
  bool includeSizeMrp = true,
  bool includeSizeWsp = true,
  bool includeProduct = true,
  bool includeRemark = true,
  bool shadeWiseImage = false,
}) async {
  if (selectedItems.isEmpty) {
    _showMessageDialog('Please select items to share', isError: true);
    return;
  }

  try {
    // Show loading indicator
    final loadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sharing PDF .....'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final apiUrl = '${AppConstants.BASE_URL}/pdf/generate';
    List<Map<String, dynamic>> catalogItems = [];

    for (var item in selectedItems) {
      // Get all image URLs for this item
      final allImageUrls = _getImageUrl(item);

      // Get shade list
      final shadeList =
          item.shadeName.isNotEmpty
              ? item.shadeName.split(',').map((s) => s.trim()).toList()
              : [];

      print('Processing item: ${item.styleCode}');
      print('All Image URLs: $allImageUrls');
      print('Shade List: $shadeList');
      print('shadeWiseImage option: $shadeWiseImage');

      if (shadeWiseImage && UserSession.imageDependsOn == 'S') {
        // ===== SHADE WISE IMAGE MODE =====
        // Send ONLY shade images, exclude main image

        if (allImageUrls.length == 1) {
          // TYPE 1: Only one image available (main image)
          // Since no shade images exist, don't send anything for this item
          print('No shade images available for ${item.styleCode}');
          continue;
        } else if (allImageUrls.length > 1) {
          // TYPE 2: Multiple images available (main + shade images)
          // Skip the first image (index 0) which is the main image
          // Only add shade images starting from index 1

          if (shadeList.isNotEmpty) {
            // Add shade images with their corresponding shades
            int shadeImagesCount =
                allImageUrls.length - 1; // Number of shade images

            for (int i = 0; i < shadeImagesCount; i++) {
              int imageIndex = i + 1; // Start from second image (index 1)
              if (imageIndex < allImageUrls.length) {
                // Determine which shade this image belongs to
                String imageSpecificShade = '';

                if (i < shadeList.length) {
                  // We have a matching shade for this image
                  imageSpecificShade = shadeList[i];
                } else {
                  // More images than shades, use empty or first shade for remaining images
                  imageSpecificShade =
                      shadeList.isNotEmpty ? shadeList[0] : '';
                }

                Map<String, dynamic> shadeCatalogItem = _buildCatalogItem(
                  item,
                  allImageUrls[imageIndex],
                  imageSpecificShade, // Specific shade for this image
                  includeDesign,
                  includeShade,
                  includeRate,
                  includeWsp,
                  includeSize,
                  includeSizeMrp,
                  includeSizeWsp,
                  includeProduct,
                  includeRemark,
                );
                catalogItems.add(shadeCatalogItem);
              }
            }
          } else {
            // No shades available, add remaining images with empty shade
            for (int i = 1; i < allImageUrls.length; i++) {
              if (allImageUrls[i].isNotEmpty) {
                Map<String, dynamic> extraCatalogItem = _buildCatalogItem(
                  item,
                  allImageUrls[i],
                  '', // Empty shade
                  includeDesign,
                  includeShade,
                  includeRate,
                  includeWsp,
                  includeSize,
                  includeSizeMrp,
                  includeSizeWsp,
                  includeProduct,
                  includeRemark,
                );
                catalogItems.add(extraCatalogItem);
              }
            }
          }
        }
      } else {
        // ===== NORMAL MODE (not shade wise) =====
        // Send ONLY the first/main image for each item
        if (allImageUrls.isNotEmpty && allImageUrls.first.isNotEmpty) {
          Map<String, dynamic> catalogItem = _buildCatalogItem(
            item,
            allImageUrls.first,
            includeShade ? item.shadeName : '', // Include shade if enabled
            includeDesign,
            includeShade,
            includeRate,
            includeWsp,
            includeSize,
            includeSizeMrp,
            includeSizeWsp,
            includeProduct,
            includeRemark,
          );
          catalogItems.add(catalogItem);
        }
      }
    }

    // If no catalog items after filtering, show message
    if (catalogItems.isEmpty) {
      // Clear loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images to share based on selection'),
        ),
      );
      return;
    }

    // Prepare request body
    final requestBody = {
      "company": UserSession.coBrName,
      "createdBy": "admin",
      "mobile": "",
      "catalogItems": catalogItems,
    };

    print('Sending to PDF API: ${jsonEncode(requestBody)}');

    // Clear loading snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final file = File(
        '${tempDir.path}/catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(response.bodyBytes);

      // Use shareXFiles which returns a Future<ShareResult>
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Please find the Catalog as an attachment.',
      );

      // Check if sharing was completed or cancelled
      if (result.status == ShareResultStatus.success) {
        // Only show success message if sharing was actually completed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                shadeWiseImage
                    ? 'PDF with ${catalogItems.length} shade images generated successfully'
                    : 'PDF generated successfully',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Optionally clear selected items after successful share
        setState(() {
          selectedItems = [];
        });
      } else if (result.status == ShareResultStatus.dismissed) {
        // User cancelled the share - show subtle message or nothing
        print('PDF share was cancelled by user');
        
        // Optionally show a subtle message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share cancelled'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${response.statusCode}'),
          ),
        );
      }
    }
  } catch (e) {
    // Clear any loading snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share items: ${e.toString()}')),
      );
    }
    print('Error in _shareSelectedItemsPDF: $e');
  }
}
  Map<String, dynamic> _buildCatalogItem(
    Catalog item,
    String imageUrl,
    String shadeValue,
    bool includeDesign,
    bool includeShade,
    bool includeRate,
    bool includeWsp,
    bool includeSize,
    bool includeSizeMrp,
    bool includeSizeWsp,
    bool includeProduct,
    bool includeRemark,
  ) {
    Map<String, dynamic> catalogItem = {'fullImagePath': imageUrl};

    if (includeDesign) catalogItem['design'] = item.styleCode;
    if (includeShade) catalogItem['shade'] = shadeValue;
    if (includeRate) catalogItem['rate'] = item.mrp;
    if (includeWsp) catalogItem['wsp'] = item.wsp;

    if (includeSize) {
      if (includeSizeMrp && includeSizeWsp) {
        catalogItem['sizeDetailsWithoutWSp'] = item.sizeDetailsWithoutWSp ?? '';
      } else if (!includeSizeMrp && !includeSizeWsp) {
        catalogItem['onlySizes'] = item.onlySizes ?? '';
      } else {
        catalogItem['sizeWithMrp'] = item.sizeWithMrp ?? '';
      }
    }

    if (includeProduct) catalogItem['product'] = item.itemName;
    if (includeRemark) catalogItem['remark'] = item.remark;

    return catalogItem;
  }

 Future<void> _sendViaUnifiedWhatsAppAPI({
  required String mobileNo,
  required String shareType,
  bool includeDesign = true,
  bool includeShade = true,
  bool includeRate = true,
  bool includeWsp = true,
  bool includeSize = true,
  bool includeSizeMrp = true,
  bool includeSizeWsp = true,
  bool includeProduct = true,
  bool includeRemark = true,
  bool shadeWiseImage = false,
}) async {
  // Store reference to mounted state at the beginning
  final bool isMounted = mounted;
  
  try {
    List<Map<String, dynamic>> catalogItems = [];

    for (var item in selectedItems) {
      final allImageUrls = _getImageUrl(item);
      final shadeList =
          item.shadeName.isNotEmpty
              ? item.shadeName.split(',').map((s) => s.trim()).toList()
              : [];

      if (shadeWiseImage && UserSession.imageDependsOn == 'S') {
        if (allImageUrls.length == 1) {
          continue;
        } else if (allImageUrls.length > 1) {
          if (shadeList.isNotEmpty) {
            int shadeImagesCount = allImageUrls.length - 1;

            for (int i = 0; i < shadeImagesCount; i++) {
              int imageIndex = i + 1;
              if (imageIndex < allImageUrls.length) {
                String imageSpecificShade = '';

                if (i < shadeList.length) {
                  imageSpecificShade = shadeList[i];
                } else {
                  imageSpecificShade =
                      shadeList.isNotEmpty ? shadeList[0] : '';
                }

                Map<String, dynamic> shadeCatalogItem =
                    _buildCatalogItemForWhatsApp(
                      item,
                      includeDesign,
                      includeShade,
                      includeRate,
                      includeWsp,
                      includeSize,
                      includeSizeMrp,
                      includeSizeWsp,
                      includeProduct,
                      includeRemark,
                    );

                if (shareType == "pdf") {
                  shadeCatalogItem['fullImagePath'] =
                      allImageUrls[imageIndex];
                  if (includeShade)
                    shadeCatalogItem['shade'] = imageSpecificShade;
                } else {
                  shadeCatalogItem['imageUrl'] = allImageUrls[imageIndex];
                  if (includeShade)
                    shadeCatalogItem['shade'] = imageSpecificShade;
                }

                catalogItems.add(shadeCatalogItem);
              }
            }
          } else {
            for (int i = 1; i < allImageUrls.length; i++) {
              if (allImageUrls[i].isNotEmpty) {
                Map<String, dynamic> extraCatalogItem =
                    _buildCatalogItemForWhatsApp(
                      item,
                      includeDesign,
                      includeShade,
                      includeRate,
                      includeWsp,
                      includeSize,
                      includeSizeMrp,
                      includeSizeWsp,
                      includeProduct,
                      includeRemark,
                    );

                if (shareType == "pdf") {
                  extraCatalogItem['fullImagePath'] = allImageUrls[i];
                  if (includeShade) extraCatalogItem['shade'] = '';
                } else {
                  extraCatalogItem['imageUrl'] = allImageUrls[i];
                  if (includeShade) extraCatalogItem['shade'] = '';
                }

                catalogItems.add(extraCatalogItem);
              }
            }
          }
        }
      } else {
        if (allImageUrls.isNotEmpty && allImageUrls.first.isNotEmpty) {
          Map<String, dynamic> catalogItem = _buildCatalogItemForWhatsApp(
            item,
            includeDesign,
            includeShade,
            includeRate,
            includeWsp,
            includeSize,
            includeSizeMrp,
            includeSizeWsp,
            includeProduct,
            includeRemark,
          );

          if (shareType == "pdf") {
            catalogItem['fullImagePath'] = allImageUrls.first;
            if (includeShade) catalogItem['shade'] = item.shadeName;
          } else {
            catalogItem['imageUrl'] = allImageUrls.first;
            if (includeShade) catalogItem['shade'] = item.shadeName;
          }

          catalogItems.add(catalogItem);
        }
      }
    }

    if (catalogItems.isEmpty) {
      if (isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to share based on selection')),
        );
      }
      return;
    }

    final requestBody = {
      "catalogItems": catalogItems,
      "includeDesign": includeDesign,
      "includeShade": includeShade,
      "includeRate": includeRate,
      "includeWsp": includeWsp,
      "includeSize": includeSize,
      "includeProduct": includeProduct,
      "includeRemark": includeRemark,
      "mobile": "91$mobileNo",
    };

    String apiUrl;
    if (shareType == "pdf") {
      apiUrl = '${AppConstants.BASE_URL}/pdf/generate-and-send-whatsapp';
    } else {
      apiUrl = '${AppConstants.BASE_URL}/images/generate-and-send-whatsapp';
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200 && isMounted) {
      // Success - will be handled by parent method
      print('WhatsApp API call successful');
    } else {
      throw Exception('API call failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in _sendViaUnifiedWhatsAppAPI: $e');
    rethrow; // Rethrow to be caught by parent
  }
}
  Map<String, dynamic> _buildCatalogItemForWhatsApp(
    Catalog item,
    bool includeDesign,
    bool includeShade,
    bool includeRate,
    bool includeWsp,
    bool includeSize,
    bool includeSizeMrp,
    bool includeSizeWsp,
    bool includeProduct,
    bool includeRemark,
  ) {
    Map<String, dynamic> catalogItem = {};

    if (includeDesign) catalogItem['design'] = item.styleCode;
    if (includeRate) catalogItem['rate'] = item.mrp;
    if (includeWsp) catalogItem['wsp'] = item.wsp;

    if (includeSize) {
      if (includeSizeMrp && includeSizeWsp) {
        catalogItem['sizeDetailsWithoutWSp'] = item.sizeDetailsWithoutWSp ?? '';
      } else if (!includeSizeMrp && !includeSizeWsp) {
        catalogItem['onlySizes'] = item.onlySizes ?? '';
      } else {
        catalogItem['sizeWithMrp'] = item.sizeWithMrp ?? '';
      }
    }

    if (includeProduct) catalogItem['product'] = item.itemName;
    if (includeRemark) catalogItem['remark'] = item.remark ?? '';

    return catalogItem;
  }

  Future<void> _sendPDFViaOldWhatsAppAPI({
    required String mobileNo,
    bool includeDesign = true,
    bool includeShade = true,
    bool includeRate = true,
    bool includeWsp = true,
    bool includeSize = true,
    bool includeSizeMrp = true,
    bool includeSizeWsp = true,
    bool includeProduct = true,
    bool includeRemark = true,
    bool shadeWiseImage = false,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final apiUrl = '${AppConstants.BASE_URL}/pdf/generate';
      List<Map<String, dynamic>> catalogItems = [];

      for (var item in selectedItems) {
        final allImageUrls = _getImageUrl(item);
        final shadeList =
            item.shadeName.isNotEmpty
                ? item.shadeName.split(',').map((s) => s.trim()).toList()
                : [];

        if (shadeWiseImage && UserSession.imageDependsOn == 'S') {
          if (allImageUrls.length == 1) {
            continue;
          } else if (allImageUrls.length > 1) {
            if (shadeList.isNotEmpty) {
              int shadeImagesCount = allImageUrls.length - 1;

              for (int i = 0; i < shadeImagesCount; i++) {
                int imageIndex = i + 1;
                if (imageIndex < allImageUrls.length) {
                  String imageSpecificShade = '';

                  if (i < shadeList.length) {
                    imageSpecificShade = shadeList[i];
                  } else {
                    imageSpecificShade =
                        shadeList.isNotEmpty ? shadeList[0] : '';
                  }

                  Map<String, dynamic> shadeCatalogItem = _buildCatalogItem(
                    item,
                    allImageUrls[imageIndex],
                    imageSpecificShade,
                    includeDesign,
                    includeShade,
                    includeRate,
                    includeWsp,
                    includeSize,
                    includeSizeMrp,
                    includeSizeWsp,
                    includeProduct,
                    includeRemark,
                  );
                  catalogItems.add(shadeCatalogItem);
                }
              }
            } else {
              for (int i = 1; i < allImageUrls.length; i++) {
                if (allImageUrls[i].isNotEmpty) {
                  Map<String, dynamic> extraCatalogItem = _buildCatalogItem(
                    item,
                    allImageUrls[i],
                    '',
                    includeDesign,
                    includeShade,
                    includeRate,
                    includeWsp,
                    includeSize,
                    includeSizeMrp,
                    includeSizeWsp,
                    includeProduct,
                    includeRemark,
                  );
                  catalogItems.add(extraCatalogItem);
                }
              }
            }
          }
        } else {
          if (allImageUrls.isNotEmpty && allImageUrls.first.isNotEmpty) {
            Map<String, dynamic> catalogItem = _buildCatalogItem(
              item,
              allImageUrls.first,
              includeShade ? item.shadeName : '',
              includeDesign,
              includeShade,
              includeRate,
              includeWsp,
              includeSize,
              includeSizeMrp,
              includeSizeWsp,
              includeProduct,
              includeRemark,
            );
            catalogItems.add(catalogItem);
          }
        }
      }

      if (catalogItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to share based on selection')),
        );
        return;
      }

      final requestBody = {
        "company": UserSession.coBrName ?? "VRS Software",
        "createdBy": "admin",
        "mobile": "",
        "catalogItems": catalogItems,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final file = File(
          '${tempDir.path}/catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);

        final imageBytes = await file.readAsBytes();

        String caption = 'Catalog PDF';

        bool result = await sendWhatsAppFile(
          fileBytes: imageBytes,
          mobileNo: mobileNo,
          fileType: 'pdf',
          caption: caption,
        );

        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF sent successfully to $mobileNo')),
          );
          setState(() {
            selectedItems = [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send PDF via WhatsApp')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _sendImagesViaOldWhatsAppAPI({
    required String mobileNo,
    bool includeDesign = true,
    bool includeShade = true,
    bool includeRate = true,
    bool includeWsp = true,
    bool includeSize = true,
    bool includeSizeMrp = true,
    bool includeSizeWsp = true,
    bool includeProduct = true,
    bool includeRemark = true,
    bool shadeWiseImage = false,
  }) async {
    try {
      for (var item in selectedItems) {
        final allImageUrls = _getImageUrl(item);
        final shadeList =
            item.shadeName.isNotEmpty
                ? item.shadeName.split(',').map((s) => s.trim()).toList()
                : [];

        if (shadeWiseImage && UserSession.imageDependsOn == 'S') {
          if (allImageUrls.length == 1) {
            continue;
          } else if (allImageUrls.length > 1) {
            if (shadeList.isNotEmpty) {
              int shadeImagesCount = allImageUrls.length - 1;

              for (int i = 0; i < shadeImagesCount; i++) {
                int imageIndex = i + 1;
                if (imageIndex < allImageUrls.length) {
                  String imageSpecificShade = '';

                  if (i < shadeList.length) {
                    imageSpecificShade = shadeList[i];
                  } else {
                    imageSpecificShade =
                        shadeList.isNotEmpty ? shadeList[0] : '';
                  }

                  await _sendSingleImageToWhatsApp(
                    item: item,
                    imageUrl: allImageUrls[imageIndex],
                    shadeValue: imageSpecificShade,
                    mobileNo: mobileNo,
                    includeDesign: includeDesign,
                    includeShade: includeShade,
                    includeRate: includeRate,
                    includeWsp: includeWsp,
                    includeSize: includeSize,
                    includeSizeMrp: includeSizeMrp,
                    includeSizeWsp: includeSizeWsp,
                    includeProduct: includeProduct,
                    includeRemark: includeRemark,
                  );
                }
              }
            } else {
              for (int i = 1; i < allImageUrls.length; i++) {
                if (allImageUrls[i].isNotEmpty) {
                  await _sendSingleImageToWhatsApp(
                    item: item,
                    imageUrl: allImageUrls[i],
                    shadeValue: '',
                    mobileNo: mobileNo,
                    includeDesign: includeDesign,
                    includeShade: includeShade,
                    includeRate: includeRate,
                    includeWsp: includeWsp,
                    includeSize: includeSize,
                    includeSizeMrp: includeSizeMrp,
                    includeSizeWsp: includeSizeWsp,
                    includeProduct: includeProduct,
                    includeRemark: includeRemark,
                  );
                }
              }
            }
          }
        } else {
          if (allImageUrls.isNotEmpty && allImageUrls.first.isNotEmpty) {
            await _sendSingleImageToWhatsApp(
              item: item,
              imageUrl: allImageUrls.first,
              shadeValue: includeShade ? item.shadeName : '',
              mobileNo: mobileNo,
              includeDesign: includeDesign,
              includeShade: includeShade,
              includeRate: includeRate,
              includeWsp: includeWsp,
              includeSize: includeSize,
              includeSizeMrp: includeSizeMrp,
              includeSizeWsp: includeSizeWsp,
              includeProduct: includeProduct,
              includeRemark: includeRemark,
            );
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images sent successfully...')),
      );
      setState(() {
        selectedItems = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _sendSingleImageToWhatsApp({
    required Catalog item,
    required String imageUrl,
    required String shadeValue,
    required String mobileNo,
    bool includeDesign = true,
    bool includeShade = true,
    bool includeRate = true,
    bool includeWsp = true,
    bool includeSize = true,
    bool includeSizeMrp = true,
    bool includeSizeWsp = true,
    bool includeProduct = true,
    bool includeRemark = true,
  }) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;

        int count = item.shadeName.split(',').length;

        String caption = '';
        if (includeDesign)
          caption += '*Design*\t\t: ${item.styleCode} (${count} Colors)\n';
        if (includeShade) caption += '*Shade*\t\t: $shadeValue\n';
        if (includeRate)
          caption += '*MRP*\t\t\t: ${item.mrp.toStringAsFixed(0)}\n';
        if (includeSize) {
          String sizeValue = '';
          if (includeSizeMrp && includeSizeWsp) {
            sizeValue = item.sizeDetailsWithoutWSp ?? '';
          } else if (!includeSizeMrp && !includeSizeWsp) {
            sizeValue = item.onlySizes ?? '';
          } else {
            sizeValue = item.sizeWithMrp ?? '';
          }
          caption += '*Sizes*\t\t\t: $sizeValue\n';
        }
        if (includeProduct) caption += '*Product*\t: ${item.itemName}\n';
        if (includeRemark) caption += '*Remark*\t\t: ${item.remark}\n';

        await sendWhatsAppFile(
          fileBytes: imageBytes,
          mobileNo: mobileNo,
          fileType: 'image',
          caption: caption,
        );
      }
    } catch (e) {
      print("Failed to send image for ${item.itemName}: $e");
    }
  }

  Future<void> _sendPDFViaNodeAPI({
    required String mobileNo,
    bool includeDesign = true,
    bool includeShade = true,
    bool includeRate = true,
    bool includeWsp = true,
    bool includeSize = true,
    bool includeSizeMrp = true,
    bool includeSizeWsp = true,
    bool includeProduct = true,
    bool includeRemark = true,
    bool shadeWiseImage = false,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final apiUrl = '${AppConstants.BASE_URL}/pdf/generate';
      List<Map<String, dynamic>> catalogItems = [];

      for (var item in selectedItems) {
        final allImageUrls = _getImageUrl(item);
        final shadeList =
            item.shadeName.isNotEmpty
                ? item.shadeName.split(',').map((s) => s.trim()).toList()
                : [];

        if (shadeWiseImage && UserSession.imageDependsOn == 'S') {
          if (allImageUrls.length == 1) {
            continue;
          } else if (allImageUrls.length > 1) {
            if (shadeList.isNotEmpty) {
              int shadeImagesCount = allImageUrls.length - 1;

              for (int i = 0; i < shadeImagesCount; i++) {
                int imageIndex = i + 1;
                if (imageIndex < allImageUrls.length) {
                  String imageSpecificShade = '';

                  if (i < shadeList.length) {
                    imageSpecificShade = shadeList[i];
                  } else {
                    imageSpecificShade =
                        shadeList.isNotEmpty ? shadeList[0] : '';
                  }

                  Map<String, dynamic> shadeCatalogItem = _buildCatalogItem(
                    item,
                    allImageUrls[imageIndex],
                    imageSpecificShade,
                    includeDesign,
                    includeShade,
                    includeRate,
                    includeWsp,
                    includeSize,
                    includeSizeMrp,
                    includeSizeWsp,
                    includeProduct,
                    includeRemark,
                  );
                  catalogItems.add(shadeCatalogItem);
                }
              }
            } else {
              for (int i = 1; i < allImageUrls.length; i++) {
                if (allImageUrls[i].isNotEmpty) {
                  Map<String, dynamic> extraCatalogItem = _buildCatalogItem(
                    item,
                    allImageUrls[i],
                    '',
                    includeDesign,
                    includeShade,
                    includeRate,
                    includeWsp,
                    includeSize,
                    includeSizeMrp,
                    includeSizeWsp,
                    includeProduct,
                    includeRemark,
                  );
                  catalogItems.add(extraCatalogItem);
                }
              }
            }
          }
        } else {
          if (allImageUrls.isNotEmpty && allImageUrls.first.isNotEmpty) {
            Map<String, dynamic> catalogItem = _buildCatalogItem(
              item,
              allImageUrls.first,
              includeShade ? item.shadeName : '',
              includeDesign,
              includeShade,
              includeRate,
              includeWsp,
              includeSize,
              includeSizeMrp,
              includeSizeWsp,
              includeProduct,
              includeRemark,
            );
            catalogItems.add(catalogItem);
          }
        }
      }

      if (catalogItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items to share based on selection')),
        );
        return;
      }

      final requestBody = {
        "company": UserSession.coBrName ?? "VRS Software",
        "createdBy": "admin",
        "mobile": "",
        "catalogItems": catalogItems,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final file = File(
          '${tempDir.path}/catalog_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);

        final pdfBytes = await file.readAsBytes();

        String fileBase64 = base64Encode(pdfBytes);

        final nodeResponse = await http.post(
          Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
          body: {
            'data': fileBase64,
            'filename': 'catalog.pdf',
            'key': AppConstants.whatsappKey,
            'number': '91$mobileNo',
            'caption': 'Catalog PDF',
          },
        );

        if (nodeResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF sent successfully to $mobileNo via Node API'),
            ),
          );
          setState(() {
            selectedItems = [];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send PDF via Node API')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

Future<void> _shareSelectedWhatsApp({
  required String shareType,
  bool includeDesign = true,
  bool includeShade = true,
  bool includeRate = true,
  bool includeSize = true,
  bool includeProduct = true,
  bool includeRemark = true,
  bool includeLabel = false,
  bool shadeWiseImage = false,
}) async {
  if (!mounted) return;
  
  if (selectedItems.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to share')),
      );
    }
    return;
  }

  try {
    final result = await _showMobileNumberDialog();

    if (result == null || !mounted) return; // User cancelled or widget disposed

    String mobileNo = result['mobileNo'] ?? '';
    String selectedShareType = result['shareType'] ?? 'image';

    // Store mounted state for use in callbacks
    final bool mountedBeforeApiCall = mounted;

    if (!mountedBeforeApiCall) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending via WhatsApp...'),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    String whatsappType = AppConstants.whatsappType ?? "2";
    bool success = false;

    try {
      if (whatsappType.toUpperCase() == "2") {
        await _sendViaUnifiedWhatsAppAPI(
          mobileNo: mobileNo,
          shareType: selectedShareType,
          includeDesign: includeDesign,
          includeShade: includeShade,
          includeRate: includeRate,
          includeWsp: true,
          includeSize: includeSize,
          includeSizeMrp: true,
          includeSizeWsp: false,
          includeProduct: includeProduct,
          includeRemark: includeRemark,
          shadeWiseImage: shadeWiseImage,
        );
        success = true;
      } else if (whatsappType.toUpperCase() == "1") {
        if (selectedShareType == "pdf") {
          await _sendPDFViaNodeAPI(
            mobileNo: mobileNo,
            includeDesign: includeDesign,
            includeShade: includeShade,
            includeRate: includeRate,
            includeWsp: true,
            includeSize: includeSize,
            includeSizeMrp: true,
            includeSizeWsp: false,
            includeProduct: includeProduct,
            includeRemark: includeRemark,
            shadeWiseImage: shadeWiseImage,
          );
          success = true;
        } else {
          await _sendImagesViaOldWhatsAppAPI(
            mobileNo: mobileNo,
            includeDesign: includeDesign,
            includeShade: includeShade,
            includeRate: includeRate,
            includeWsp: true,
            includeSize: includeSize,
            includeSizeMrp: true,
            includeSizeWsp: false,
            includeProduct: includeProduct,
            includeRemark: includeRemark,
            shadeWiseImage: shadeWiseImage,
          );
          success = true;
        }
      } else {
        if (selectedShareType == "pdf") {
          await _sendPDFViaOldWhatsAppAPI(
            mobileNo: mobileNo,
            includeDesign: includeDesign,
            includeShade: includeShade,
            includeRate: includeRate,
            includeWsp: true,
            includeSize: includeSize,
            includeSizeMrp: true,
            includeSizeWsp: false,
            includeProduct: includeProduct,
            includeRemark: includeRemark,
            shadeWiseImage: shadeWiseImage,
          );
          success = true;
        } else {
          await _sendImagesViaOldWhatsAppAPI(
            mobileNo: mobileNo,
            includeDesign: includeDesign,
            includeShade: includeShade,
            includeRate: includeRate,
            includeWsp: true,
            includeSize: includeSize,
            includeSizeMrp: true,
            includeSizeWsp: false,
            includeProduct: includeProduct,
            includeRemark: includeRemark,
            shadeWiseImage: shadeWiseImage,
          );
          success = true;
        }
      }
    } catch (apiError) {
      print('API Error: $apiError');
      success = false;
    }

    // Clear loading snackbar
    if (mountedBeforeApiCall && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    // Only proceed if widget is still mounted
    if (mounted && mountedBeforeApiCall) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'WhatsApp ${selectedShareType == "pdf" ? "PDF" : "images"} sent successfully to $mobileNo',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear selected items after successful share
        setState(() {
          selectedItems = [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send via WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    print('Error in _shareSelectedWhatsApp: $e');
    
    // Check if mounted before using context
    if (mounted) {
      // Clear loading snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share items: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
  Future<Map<String, String>?> _showMobileNumberDialog() async {
  TextEditingController mobileController = TextEditingController();
  String selectedType = 'image'; // default selection
  bool hasError = false;

  return showDialog<Map<String, String>?>(
    context: context,
    barrierDismissible: false, // Prevent dialog from closing when tapping outside
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            backgroundColor: Colors.white,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with title and close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Share Order',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mobile Number Input with red border when error
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: GoogleFonts.poppins(fontSize: 14),
                    onChanged: (value) {
                      // Clear error when user starts typing
                      if (hasError) {
                        setState(() {
                          hasError = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: hasError ? Colors.red : Colors.grey.shade700,
                      ),
                      hintText: 'Enter 10-digit number',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.phone_android_rounded,
                        color: hasError ? Colors.red : AppColors.primaryColor,
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasError ? Colors.red : Colors.grey.shade300,
                          width: hasError ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasError ? Colors.red : Colors.grey.shade300,
                          width: hasError ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: hasError ? Colors.red : AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      counterText: '',
                      errorText: hasError ? 'Please enter a valid 10-digit number' : null,
                      errorStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Options without radio buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectionOption(
                          title: 'Image',
                          isSelected: selectedType == 'image',
                          icon: Icons.image_rounded,
                          iconColor: Colors.blue[700]!,
                          onTap: () {
                            setState(() {
                              selectedType = 'image';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectionOption(
                          title: 'PDF',
                          isSelected: selectedType == 'pdf',
                          icon: Icons.picture_as_pdf_rounded,
                          iconColor: Colors.red[700]!,
                          onTap: () {
                            setState(() {
                              selectedType = 'pdf';
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final mobileNo = mobileController.text.trim();
                            
                            // Validate mobile number
                            if (mobileNo.isEmpty) {
                              setState(() {
                                hasError = true;
                              });
                              return;
                            }
                            
                            if (mobileNo.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(mobileNo)) {
                              setState(() {
                                hasError = true;
                              });
                              return;
                            }
                            
                            // If validation passes, return the data
                            Navigator.pop(context, {
                              'mobileNo': mobileNo,
                              'shareType': selectedType,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Send',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded, size: 16),
                            ],
                          ),
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
    },
  );
}
  // New helper widget for selection option without radio button
  Widget _buildSelectionOption({
    required String title,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color:
              isSelected
                  ? AppColors.primaryColor.withOpacity(0.05)
                  : Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon only - no radio button
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatSizes(String input) {
    RegExp regExp = RegExp(r'(\w+)(?=\s?\()');
    return input.replaceAllMapped(regExp, (match) {
      return '*${match.group(0)}*';
    });
  }

  Future<bool> sendWhatsAppFile({
    required List<int> fileBytes,
    required String mobileNo,
    required String fileType,
    String? caption,
  }) async {
    try {
      String fileBase64 = base64Encode(fileBytes);

      final response = await http.post(
        Uri.parse("http://node4.wabapi.com/v4/postfile.php"),
        body: {
          'data': fileBase64,
          'filename': fileType == 'image' ? 'catalog.jpg' : 'catalog.pdf',
          'key': AppConstants.whatsappKey,
          'number': '91$mobileNo',
          'caption': caption ?? 'Please find the file attached.',
        },
      );

      if (response.statusCode == 200) {
        print('File sent successfully');
        return true;
      } else {
        print('Failed to send file');
        return false;
      }
    } catch (e) {
      print('Error sending file: $e');
      return false;
    }
  }

 Future<void> _shareSelectedItems({
  required String shareType,
  bool includeDesign = true,
  bool includeShade = true,
  bool includeRate = true,
  bool includeWsp = true,
  bool includeSize = true,
  bool includeSizeMrp = true,
  bool includeSizeWsp = true,
  bool includeProduct = true,
  bool includeRemark = true,
  bool shadeWiseImage = false,
}) async {
  if (selectedItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select items to share')),
    );
    return;
  }

  try {
    // Show loading indicator
    final loadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Preparing items for sharing...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final List<Map<String, String>> catalogItems = [];

    for (var item in selectedItems) {
      final allImageUrls = _getImageUrl(item);
      final shadeList =
          item.shadeName.isNotEmpty
              ? item.shadeName.split(',').map((s) => s.trim()).toList()
              : [];

      if (shadeWiseImage && UserSession.imageDependsOn == 'S') {
        if (allImageUrls.length == 1) {
          continue;
        } else if (allImageUrls.length > 1) {
          if (shadeList.isNotEmpty) {
            int shadeImagesCount = allImageUrls.length - 1;

            for (int i = 0; i < shadeImagesCount; i++) {
              int imageIndex = i + 1;
              if (imageIndex < allImageUrls.length) {
                String imageSpecificShade = '';

                if (i < shadeList.length) {
                  imageSpecificShade = shadeList[i];
                } else {
                  imageSpecificShade = shadeList.isNotEmpty ? shadeList[0] : '';
                }

                Map<String, String> shadeCatalogItem = _buildImageCatalogItem(
                  item,
                  allImageUrls[imageIndex],
                  imageSpecificShade,
                  includeDesign,
                  includeShade,
                  includeRate,
                  includeWsp,
                  includeSize,
                  includeSizeMrp,
                  includeSizeWsp,
                  includeProduct,
                  includeRemark,
                );
                catalogItems.add(shadeCatalogItem);
              }
            }
          } else {
            for (int i = 1; i < allImageUrls.length; i++) {
              if (allImageUrls[i].isNotEmpty) {
                Map<String, String> extraCatalogItem = _buildImageCatalogItem(
                  item,
                  allImageUrls[i],
                  '',
                  includeDesign,
                  includeShade,
                  includeRate,
                  includeWsp,
                  includeSize,
                  includeSizeMrp,
                  includeSizeWsp,
                  includeProduct,
                  includeRemark,
                );
                catalogItems.add(extraCatalogItem);
              }
            }
          }
        }
      } else {
        if (allImageUrls.isNotEmpty && allImageUrls.first.isNotEmpty) {
          Map<String, String> catalogItem = _buildImageCatalogItem(
            item,
            allImageUrls.first,
            includeShade ? item.shadeName : '',
            includeDesign,
            includeShade,
            includeRate,
            includeWsp,
            includeSize,
            includeSizeMrp,
            includeSizeWsp,
            includeProduct,
            includeRemark,
          );
          catalogItems.add(catalogItem);
        }
      }
    }

    if (catalogItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No images to share based on selection'),
        ),
      );
      return;
    }

    // Clear loading snackbar
    ScaffoldMessenger.of(context).clearSnackBars();

    final response = await http.post(
      Uri.parse('${AppConstants.BASE_URL}/image/generate-and-share'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'catalogItems': catalogItems,
        'includeDesign': includeDesign,
        'includeShade': includeShade,
        'includeRate': includeRate,
        'includeWsp': includeWsp,
        'includeSize': includeSize,
        'includeProduct': includeProduct,
        'includeRemark': includeRemark,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as List;
      final tempDir = await getTemporaryDirectory();
      List<String> filePaths = [];

      for (var imageData in responseData) {
        try {
          final imageBytes = base64Decode(imageData['image']);
          final file = File(
            '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await file.writeAsBytes(imageBytes);
          filePaths.add(file.path);
        } catch (e) {
          print('Error saving image: $e');
        }
      }

      if (filePaths.isNotEmpty) {
        // Convert to XFile list for Share.shareXFiles
        final xFiles = filePaths.map((path) => XFile(path)).toList();
        
        // Use shareXFiles which returns a Future<ShareResult>
        final result = await Share.shareXFiles(xFiles);
        
        // Check if sharing was completed or cancelled
        if (result.status == ShareResultStatus.success) {
          // Only show success message if sharing was actually completed
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  shadeWiseImage
                      ? '${filePaths.length} shade images shared successfully'
                      : 'Images shared successfully',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          // Optionally clear selected items after successful share
          setState(() {
            selectedItems = [];
          });
        } else if (result.status == ShareResultStatus.dismissed) {
          // User cancelled the share - don't show any message
          print('Share was cancelled by user');
          
          // Optionally show a subtle message that share was cancelled
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share cancelled'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid images to share')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate images: ${response.statusCode}'),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share items: ${e.toString()}')),
      );
    }
    print('Error in _shareSelectedItems: $e');
  }
}
  Map<String, String> _buildImageCatalogItem(
    Catalog item,
    String imageUrl,
    String shadeValue,
    bool includeDesign,
    bool includeShade,
    bool includeRate,
    bool includeWsp,
    bool includeSize,
    bool includeSizeMrp,
    bool includeSizeWsp,
    bool includeProduct,
    bool includeRemark,
  ) {
    String sizeValue = '';
    if (includeSize) {
      if (includeSizeMrp && includeSizeWsp) {
        sizeValue = item.sizeDetailsWithoutWSp ?? '';
      } else if (!includeSizeMrp && !includeSizeWsp) {
        sizeValue = item.onlySizes ?? '';
      } else {
        sizeValue = item.sizeWithMrp ?? '';
      }
    }

    return {
      'imageUrl': imageUrl,
      'design': includeDesign ? item.styleCode : '',
      'shade': includeShade ? shadeValue : '',
      'rate': includeRate ? item.mrp.toString() : '',
      'wsp': includeWsp ? item.wsp.toString() : '',
      'size': sizeValue,
      'product': includeProduct ? item.itemName : '',
      'remark': includeRemark ? item.remark ?? '' : '',
    };
  }

  void _toggleItemSelection(Catalog item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
  }

  void _showShareOptions() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to share')),
      );
      return;
    }

    void _shareAsLink() async {
      try {
        if (selectedItems.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select items to share')),
            );
          }
          return;
        }

        // Show loading indicator
        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return const Center(child: CircularProgressIndicator());
          },
        );

        // Extract style keys from selected items
        final styleKeys = selectedItems.map((item) => item.styleKey).toList();

        // Prepare request body
        final requestBody = {"createdBy": "1", "styleKeys": styleKeys};

        print('Creating link with styleKeys: $styleKeys');
        print('Request body: ${jsonEncode(requestBody)}');

        // Make API call to create link
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/orderBooking/create-link'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final linkCode = responseData['link'];
          final shareUrl = '${AppConstants.BASE_URL}/link/$linkCode';

          print('Share URL: $shareUrl');

          // Show dialog with share link and QR code - FIXED VERSION
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: MediaQuery.of(dialogContext).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.link_rounded,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Share as Link',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Instructions
                        Text(
                          'Share this link or scan the QR code:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Link Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(
                            shareUrl,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: QrImageView(
                            data: shareUrl,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: shareUrl),
                                  );
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link copied to clipboard'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryColor,
                                  side: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Copy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await Share.share(
                                    shareUrl,
                                    subject: 'Catalog Share Link',
                                  );
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link shared successfully'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.share, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Share',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create link: ${response.statusCode}'),
              ),
            );
          }
        }
      } catch (e) {
        print('Error in _shareAsLink: $e');
        // Close loading dialog if it's open
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to share link: ${e.toString()}')),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ShareOptionsPage(
          includeDesign: includeDesign,
          includeShade: includeShade,
          includeRate: includeRate,
          includeWsp: includeWsp,
          includeSize: includeSize,
          includeSizeMrp: includeSizeMrp,
          includeSizeWsp: includeSizeWsp,
          includeProduct: includeProduct,
          includeRemark: includeRemark,
          shadeWiseImage: false,
          onWhatsAppShare: ({
            bool includeDesign = true,
            bool includeShade = true,
            bool includeRate = true,
            bool includeSize = true,
            bool includeProduct = true,
            bool includeRemark = true,
            bool shadeWiseImage = false,
          }) {
            Navigator.pop(context);
            _shareSelectedWhatsApp(
              shareType: 'WhatsApp',
              includeDesign: includeDesign,
              includeShade: includeShade,
              includeRate: includeRate,
              includeSize: includeSize,
              includeProduct: includeProduct,
              includeRemark: includeRemark,
              shadeWiseImage: shadeWiseImage,
            );
          },
          onLinkShare: () {
            _shareAsLink(); // This now calls the new API-based function
          },
          onImageShare: ({
            bool includeDesign = true,
            bool includeShade = true,
            bool includeRate = true,
            bool includeWsp = false,
            bool includeSize = true,
            bool includeSizeMrp = true,
            bool includeSizeWsp = false,
            bool includeProduct = true,
            bool includeRemark = true,
            bool shadeWiseImage = false,
          }) {
            Navigator.pop(context);
            _shareSelectedItems(
              shareType: 'image',
              includeDesign: includeDesign,
              includeShade: includeShade,
              includeRate: includeRate,
              includeWsp: includeWsp,
              includeSize: includeSize,
              includeSizeMrp: includeSizeMrp,
              includeSizeWsp: includeSizeWsp,
              includeProduct: includeProduct,
              includeRemark: includeRemark,
              shadeWiseImage: shadeWiseImage,
            );
          },
          onPDFShare: ({
            bool includeDesign = true,
            bool includeShade = true,
            bool includeRate = true,
            bool includeWsp = false,
            bool includeSize = true,
            bool includeSizeMrp = true,
            bool includeSizeWsp = false,
            bool includeProduct = true,
            bool includeRemark = true,
            bool shadeWiseImage = false,
          }) {
            Navigator.pop(context);
            _shareSelectedItemsPDF(
              shareType: 'pdf',
              includeDesign: includeDesign,
              includeShade: includeShade,
              includeRate: includeRate,
              includeWsp: includeWsp,
              includeSize: includeSize,
              includeSizeMrp: includeSizeMrp,
              includeSizeWsp: includeSizeWsp,
              includeProduct: includeProduct,
              includeRemark: includeRemark,
              shadeWiseImage: shadeWiseImage,
            );
          },
          onToggleOptions: (
            design,
            shade,
            rate,
            wsp,
            size,
            rate1,
            wsp1,
            product,
            remark,
            shadeWiseImage,
          ) {
            setState(() {
              includeDesign = design;
              includeShade = shade;
              includeRate = rate;
              includeWsp = wsp;
              includeSize = size;
              includeSizeMrp = rate1;
              includeSizeWsp = wsp1;
              includeProduct = product;
              includeRemark = remark;
            });
            _saveToggleStates();
          },
        );
      },
    );
  }

  List<String> _getFilteredImageUrls(Catalog item, bool shadeWiseImage) {
    final allImageUrls = _getImageUrl(item);

    if (allImageUrls.isEmpty || allImageUrls.first == '') {
      return [];
    }

    if (shadeWiseImage) {
      // Return all images (including shade images)
      return allImageUrls;
    } else {
      // Return only the first image (full image path)
      return [allImageUrls.first];
    }
  }

  Future<void> _handleDownloadOption(
    String option, {
    bool includeDesign = true,
    bool includeShade = true,
    bool includeRate = true,
    bool includeWsp = true,
    bool includeSize = true,
    bool includeSizeMrp = true,
    bool includeSizeWsp = true,
    bool includeProduct = true,
    bool includeRemark = true,
  }) async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to download')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing download...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      Directory? downloadsDir;

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      }

      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';

      /* ====================== PDF ====================== */

      if (option == 'pdf') {
        final apiUrl = '${AppConstants.BASE_URL}/pdf/generate';
        List<Map<String, dynamic>> catalogItems = [];

        for (var item in selectedItems) {
          final imageUrls = _getImageUrl(item);
          for (var imageUrl in imageUrls) {
            if (imageUrl.isEmpty) continue;

            Map<String, dynamic> catalogItem = {'fullImagePath': imageUrl};

            if (includeDesign) catalogItem['design'] = item.styleCode;
            if (includeShade) catalogItem['shade'] = item.shadeName;
            if (includeRate) catalogItem['rate'] = item.mrp;
            if (includeWsp) catalogItem['wsp'] = item.wsp;

            if (includeSize) {
              if (includeSizeMrp && includeSizeWsp) {
                catalogItem['sizeDetailsWithoutWSp'] =
                    item.sizeDetailsWithoutWSp ?? '';
              } else if (!includeSizeMrp && !includeSizeWsp) {
                catalogItem['onlySizes'] = item.onlySizes ?? '';
              } else {
                catalogItem['sizeWithMrp'] = item.sizeWithMrp ?? '';
              }
            }

            if (includeProduct) catalogItem['product'] = item.itemName;
            if (includeRemark) catalogItem['remark'] = item.remark;

            catalogItems.add(catalogItem);
          }
        }

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "company": "VRS Software",
            "createdBy": "admin",
            "mobile": "",
            "catalogItems": catalogItems,
          }),
        );

        if (response.statusCode == 200) {
          final fileName = 'catalog_$timestamp.pdf';

          if (kIsWeb) {
            _downloadFileWeb(
              bytes: response.bodyBytes,
              fileName: fileName,
              mimeType: 'application/pdf',
            );
          } else {
            final pdfFile = File('${downloadsDir!.path}/$fileName');
            await pdfFile.writeAsBytes(response.bodyBytes);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF downloaded successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate PDF: ${response.statusCode}'),
            ),
          );
        }
      }
      /* ====================== IMAGES ====================== */
      else if (option == 'image') {
        final List<Map<String, String>> catalogItems = [];

        for (var item in selectedItems) {
          final imageUrls = _getImageUrl(item);
          for (var imageUrl in imageUrls) {
            if (imageUrl.isEmpty) continue;

            String sizeValue = '';
            if (includeSize) {
              if (includeSizeMrp && includeSizeWsp) {
                sizeValue = item.sizeDetailsWithoutWSp ?? '';
              } else if (!includeSizeMrp && !includeSizeWsp) {
                sizeValue = item.onlySizes ?? '';
              } else {
                sizeValue = item.sizeWithMrp ?? '';
              }
            }

            catalogItems.add({
              'imageUrl': imageUrl,
              'design': includeDesign ? item.styleCode : '',
              'shade': includeShade ? item.shadeName : '',
              'rate': includeRate ? item.mrp.toString() : '',
              'wsp': includeWsp ? item.wsp.toString() : '',
              'size': sizeValue,
              'product': includeProduct ? item.itemName : '',
              'remark': includeRemark ? item.remark : '',
            });
          }
        }

        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/image/generate-and-share'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'catalogItems': catalogItems}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body) as List;
          int count = 1;

          for (var imageData in responseData) {
            final imageBytes = base64Decode(imageData['image']);
            final fileName = 'catalog_${count}_$timestamp.jpg';

            if (kIsWeb) {
              _downloadFileWeb(
                bytes: imageBytes,
                fileName: fileName,
                mimeType: 'image/jpeg',
              );
            } else {
              final file = File('${downloadsDir!.path}/$fileName');
              await file.writeAsBytes(imageBytes);
            }

            count++;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count images downloaded successfully')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to generate images')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  void _downloadFileWeb({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) {
    // final blob = html.Blob([bytes], mimeType);
    // final url = html.Url.createObjectUrlFromBlob(blob);

    // final anchor =
    //     html.AnchorElement(href: url)
    //       ..setAttribute('download', fileName)
    //       ..click();

    // html.Url.revokeObjectUrl(url);
  }

  // Future<void> _handleDownloadOption(
  //   String option, {
  //   bool includeDesign = true,
  //   bool includeShade = true,
  //   bool includeRate = true,
  //   bool includeWsp = true,
  //   bool includeSize = true,
  //   bool includeSizeMrp = true,
  //   bool includeSizeWsp = true,
  //   bool includeProduct = true,
  //   bool includeRemark = true,
  // }) async {
  //   if (selectedItems.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please select items to download')),
  //     );
  //     return;
  //   }

  //   try {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Row(
  //           children: [
  //             CircularProgressIndicator(),
  //             SizedBox(width: 16),
  //             Text('Preparing download...'),
  //           ],
  //         ),
  //         duration: Duration(seconds: 1),
  //       ),
  //     );

  //     Directory? downloadsDir;
  //     if (Platform.isAndroid) {
  //       downloadsDir = Directory('/storage/emulated/0/Download');
  //       if (!await downloadsDir.exists()) {
  //         downloadsDir = await getExternalStorageDirectory();
  //       }
  //     } else {
  //       downloadsDir = await getApplicationDocumentsDirectory();
  //     }

  //     final now = DateTime.now();
  //     final timestamp =
  //         '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';

  //     if (option == 'pdf') {
  //       final apiUrl = '${AppConstants.BASE_URL}/pdf/generate';
  //       List<Map<String, dynamic>> catalogItems = [];

  //       for (var item in selectedItems) {
  //         final imageUrls = _getImageUrl(item);
  //         print('Image URLs before use: $imageUrls');
  //         for (var imageUrl in imageUrls) {
  //           if (imageUrl.isEmpty) continue;
  //           Map<String, dynamic> catalogItem = {'fullImagePath': imageUrl};
  //           if (includeDesign) catalogItem['design'] = item.styleCode;
  //           if (includeShade) catalogItem['shade'] = item.shadeName;
  //           if (includeRate) catalogItem['rate'] = item.mrp;
  //           if (includeWsp) catalogItem['wsp'] = item.wsp;
  //           if (includeSize) {
  //             if (includeSizeMrp && includeSizeWsp) {
  //               catalogItem['sizeDetailsWithoutWSp'] =
  //                   item.sizeDetailsWithoutWSp ?? '';
  //             } else if (!includeSizeMrp && !includeSizeWsp) {
  //               catalogItem['onlySizes'] = item.onlySizes ?? '';
  //             } else {
  //               catalogItem['sizeWithMrp'] = item.sizeWithMrp ?? '';
  //             }
  //           }
  //           if (includeProduct) catalogItem['product'] = item.itemName;
  //           if (includeRemark) catalogItem['remark'] = item.remark;
  //           catalogItems.add(catalogItem);
  //         }
  //       }

  //       final requestBody = {
  //         "company": "VRS Software",
  //         "createdBy": "admin",
  //         "mobile": "",
  //         "catalogItems": catalogItems,
  //       };

  //       final response = await http.post(
  //         Uri.parse(apiUrl),
  //         headers: {'Content-Type': 'application/json'},
  //         body: jsonEncode(requestBody),
  //       );

  //       if (response.statusCode == 200) {
  //         final pdfFile = File('${downloadsDir?.path}/catalog_$timestamp.pdf');
  //         await pdfFile.writeAsBytes(response.bodyBytes);

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('PDF downloaded to ${pdfFile.path}')),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Failed to generate PDF: ${response.statusCode}'),
  //           ),
  //         );
  //       }
  //     } else if (option == 'image') {
  //       final List<Map<String, String>> catalogItems = [];
  //       for (var item in selectedItems) {
  //         final imageUrls = _getImageUrl(item);
  //         print('Image URLs before use: $imageUrls');
  //         for (var imageUrl in imageUrls) {
  //           if (imageUrl.isEmpty) continue;
  //           String sizeValue = '';
  //           if (includeSize) {
  //             if (includeSizeMrp && includeSizeWsp) {
  //               sizeValue = item.sizeDetailsWithoutWSp ?? '';
  //             } else if (!includeSizeMrp && !includeSizeWsp) {
  //               sizeValue = item.onlySizes ?? '';
  //             } else {
  //               sizeValue = item.sizeWithMrp ?? '';
  //             }
  //           }

  //           catalogItems.add({
  //             'fullImagePath': imageUrl,
  //             'design': includeDesign ? item.styleCode : '',
  //             'shade': includeShade ? item.shadeName : '',
  //             'rate': includeRate ? item.mrp.toString() : '',
  //             'wsp': includeWsp ? item.wsp.toString() : '',
  //             'size': sizeValue,
  //             'product': includeProduct ? item.itemName : '',
  //             'remark': includeRemark ? item.remark : '',
  //           });
  //         }
  //       }

  //       final response = await http.post(
  //         Uri.parse('${AppConstants.BASE_URL}/image/generate-and-share'),
  //         headers: {'Content-Type': 'application/json'},
  //         body: jsonEncode({
  //           'catalogItems': catalogItems,
  //           'includeDesign': includeDesign,
  //           'includeShade': includeShade,
  //           'includeRate': includeRate,
  //           'includeWsp': includeWsp,
  //           'includeSize': includeSize,
  //           'includeProduct': includeProduct,
  //           'includeRemark': includeRemark,
  //         }),
  //       );

  //       if (response.statusCode == 200) {
  //         final responseData = jsonDecode(response.body) as List;
  //         int count = 1;
  //         int successCount = 0;
  //         int imageIndex = 0;

  //         for (var item in selectedItems) {
  //           final imageUrls = _getImageUrl(item);
  //           print('Image URLs before use: $imageUrls');
  //           for (var _ in imageUrls) {
  //             if (imageIndex >= responseData.length) break;
  //             try {
  //               final imageData = responseData[imageIndex];
  //               final imageBytes = base64Decode(imageData['image']);
  //               final finalFile = File(
  //                 '${downloadsDir?.path}/catalog_${item.styleCode}_${count}_$timestamp.jpg',
  //               );
  //               await finalFile.writeAsBytes(imageBytes);
  //               successCount++;
  //               count++;
  //               imageIndex++;
  //             } catch (e) {
  //               print('Error saving image: $e');
  //               imageIndex++;
  //             }
  //           }
  //         }

  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               '$successCount images downloaded to Downloads folder',
  //             ),
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               'Failed to generate images: ${response.statusCode}',
  //             ),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Download failed: ${e.toString()}')),
  //     );
  //   }
  // }

  void _showDownloadOptions() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to download')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return DownloadOptionsSheet(
          initialOptions: {
            'design': includeDesign,
            'shade': includeShade,
            'rate': includeRate,
            'wsp': includeWsp,
            'size': includeSize,
            'rate1': includeSizeMrp,
            'wsp1': includeSizeWsp,
            'product': includeProduct,
            'remark': includeRemark,
          },
          onDownload: (type, selectedOptions) {
            _handleDownloadOption(
              type,
              includeDesign: selectedOptions['design'] ?? includeDesign,
              includeShade: selectedOptions['shade'] ?? includeShade,
              includeRate: selectedOptions['rate'] ?? includeRate,
              includeWsp: selectedOptions['wsp'] ?? includeWsp,
              includeSize: selectedOptions['size'] ?? includeSize,
              includeSizeMrp: selectedOptions['rate1'] ?? includeSizeMrp,
              includeSizeWsp: selectedOptions['wsp1'] ?? includeSizeWsp,
              includeProduct: selectedOptions['product'] ?? includeProduct,
              includeRemark: selectedOptions['remark'] ?? includeRemark,
            );
          },
          onToggleOptions: (options) {
            setState(() {
              includeDesign = options['design'] ?? includeDesign;
              includeShade = options['shade'] ?? includeShade;
              includeRate = options['rate'] ?? includeRate;
              includeWsp = options['wsp'] ?? includeWsp;
              includeSize = options['size'] ?? includeSize;
              includeSizeMrp = options['rate1'] ?? includeSizeMrp;
              includeSizeWsp = options['wsp1'] ?? includeSizeWsp;
              includeProduct = options['product'] ?? includeProduct;
              includeRemark = options['remark'] ?? includeRemark;
            });
            _saveToggleStates(); // Save updated toggle states
          },
        );
      },
    );
  }

  Widget _buildSizeToggleRow(void Function(void Function()) parentSetState) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  showSizes
                      ? AppColors.primaryColor.withOpacity(0.3)
                      : Colors.grey.shade200,
              width: showSizes ? 1.2 : 0.8,
            ),
            color:
                showSizes
                    ? AppColors.primaryColor.withOpacity(0.02)
                    : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (!showSizes)
                  parentSetState(() => showFullSizeDetails = false);
                parentSetState(() => showSizes = !showSizes);
                setStateDialog(() {});
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title with optional indicator
                    Row(
                      children: [
                        if (showSizes)
                          Text(
                            'Show Sizes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  showSizes
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                              color:
                                  showSizes
                                      ? AppColors.primaryColor
                                      : const Color(0xFF1E293B),
                            ),
                          ),
                      ],
                    ),

                    // Compact custom switch
                    GestureDetector(
                      onTap: () {
                        if (!showSizes)
                          parentSetState(() => showFullSizeDetails = false);
                        parentSetState(() => showSizes = !showSizes);
                        setStateDialog(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        height: 18,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              showSizes
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade300,
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              left: showSizes ? 15 : 2,
                              right: showSizes ? 2 : 15,
                              top: 2,
                              bottom: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 1,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
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
          ),
        );
      },
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              value
                  ? AppColors.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade200,
          width: value ? 1.2 : 0.8,
        ),
        color: value ? AppColors.primaryColor.withOpacity(0.02) : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                    color:
                        value
                            ? AppColors.primaryColor
                            : const Color(0xFF1E293B),
                  ),
                ),

                // Compact custom switch
                GestureDetector(
                  onTap: () => onChanged(!value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: 18,
                    width: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color:
                          value ? AppColors.primaryColor : Colors.grey.shade300,
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          left: value ? 15 : 2,
                          right: value ? 2 : 15,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 1,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
