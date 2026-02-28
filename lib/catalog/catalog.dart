import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as pw;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        // styleKey: selectedStyles.length == 1 ? selectedStyles[0].styleKey : null,
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
        pageNo: pageNo,
      );

      // print('Full API Response: ${jsonEncode(result)}'); // Log raw JSON
      final List<Catalog> items = result["catalogs"] as List<Catalog>;
      // print(
      //   'Catalog Items: ${items.map((e) => {'styleCode': e.styleCode, 'ShadeImages': e.shadeImages, 'fullImagePath': e.fullImagePath ?? ''}).toList()}',
      // );

      setState(() {
        catalogItems.addAll(items);
        total = result["total"] ?? items.length; // Adjust based on API response
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
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width > 600
                                  ? 24.0
                                  : 16.0,
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isWide =
                                                constraints.maxWidth > 400;
                                            return isWide
                                                ? Row(
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
                                                          _buildToggleRow(
                                                            "Show Product",
                                                            showProduct,
                                                            (val) {
                                                              showProduct = val;
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
                                                          _buildToggleRow(
                                                            "Show Shades",
                                                            showShades,
                                                            (val) {
                                                              showShades = val;
                                                              setStateDialog(
                                                                () {},
                                                              );
                                                            },
                                                          ),
                                                          _buildToggleRow(
                                                            "Show Remark",
                                                            showRemark,
                                                            (val) {
                                                              showRemark = val;
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
                                                    _buildToggleRow(
                                                      "Show WSP",
                                                      showWSP,
                                                      (val) {
                                                        showWSP = val;
                                                        setStateDialog(() {});
                                                      },
                                                    ),
                                                    _buildSizeToggleRow(
                                                      setState,
                                                    ),
                                                    _buildToggleRow(
                                                      "Show Shades",
                                                      showShades,
                                                      (val) {
                                                        showShades = val;
                                                        setStateDialog(() {});
                                                      },
                                                    ),
                                                    _buildToggleRow(
                                                      "Show Product",
                                                      showProduct,
                                                      (val) {
                                                        showProduct = val;
                                                        setStateDialog(() {});
                                                      },
                                                    ),
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
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                  ),
                                              child: Text(
                                                "Close",
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 18
                                                          : 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.filter_alt_outlined, color: Colors.white),
        tooltip: 'Filter',
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
                        Flexible(
                          flex: 2,
                          child: ClipRRect(
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
                                                  itemCount: imageUrls.length,
                                                  onPageChanged: (index) {
                                                    currentImageIndex.value =
                                                        index;
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
                                                        count: imageUrls.length,
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
                        ),
                        SizedBox(width: isLargeScreen ? 16 : 8),
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

    if (shadeImages.isNotEmpty && UserSession.imageDependsOn == 'S') {
      final imageEntries =
          shadeImages.split(',').map((entry) => entry.trim()).toList();
      List<String> imageUrls = [];
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
      return imageUrls.isEmpty ? [''] : imageUrls;
    } else if (fullImagePath.isNotEmpty) {
      final fileName = fullImagePath.split('/').last.split('?').first;
      if (fileName.isEmpty) return [''];
      final url = '${AppConstants.BASE_URL}/images/$fileName';
      // return [url];
      return [fullImagePath];
    }

    return [''];
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
            'fromMRP': fromMRP,
            'toMRP': toMRP,
            'WSPfrom': WSPfrom,
            'WSPto': WSPto,
            'sortBy': sortBy,
            'fromDate': fromDate,
            'toDate': toDate,
            'brands': brands.isEmpty ? [] : brands,
            // 'selectedBrands': selectedBrands,
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
        selectedStyles = selectedFilters['styles'];
        selectedSize = selectedFilters['sizes'];
        selectedShades = selectedFilters['shades'];
        fromMRP = selectedFilters['fromMRP'];
        toMRP = selectedFilters['toMRP'];
        WSPfrom = selectedFilters['WSPfrom'];
        WSPto = selectedFilters['WSPto'];
        sortBy = selectedFilters['sortBy'];
        fromDate = selectedFilters['fromDate'];
        toDate = selectedFilters['toDate'];
        //selectedBrands = selectedFilters['selectedBrands'];
        // Reset pagination
        pageNo = 1;
        catalogItems = [];
        hasMore = true;
      });
      print("fromDate  ${selectedFilters['fromDate']}");
      print("todate  ${selectedFilters['toDate']}");
      print("aaaaaaaa  ${selectedFilters['styles']}");
      print("aaaaaaaa  ${selectedFilters['WSPfrom']}");
      print("aaaaaaaa  ${selectedFilters['WSPto']}");
      print("aaaaaaaa  ${selectedFilters['styles']}");
      if (!(selectedStyles.isEmpty &&
          selectedSize.isEmpty &&
          selectedShades.isEmpty &&
          fromMRP == "" &&
          toMRP == "" &&
          WSPfrom == "" &&
          WSPto == "" &&
          selectedBrands.isEmpty &&
          sortBy == "" &&
          fromDate == "" &&
          toDate == "")) {
        _fetchCatalogItems();
      }
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
  }) async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to share')),
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
              Text('Sharing PDF .....'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final tempDir = await getTemporaryDirectory();
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

      final requestBody = {
        "company": UserSession.coBrName,
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

        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Please find the Catalog as an attachment.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share items: ${e.toString()}')),
      );
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
  }) async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to share')),
      );
      return;
    }

    try {
      //String mobileNo = await _showMobileNumberDialog();
      final result = await _showMobileNumberDialog();

      if (result == null) return;

      String mobileNo = result['mobileNo'] ?? '';
      String shareType = result['shareType'] ?? 'image';
      if (shareType != "image") {
        if (mobileNo.isNotEmpty) {
          for (var item in selectedItems) {
            final imageUrls = _getImageUrl(item);
            for (var url in imageUrls) {
              if (url.isEmpty) continue;
              final response = await http.get(Uri.parse(url));

              if (response.statusCode == 200) {
                final imageBytes = response.bodyBytes;

                String caption = '';
                if (includeDesign)
                  caption += '*Design*\t\t: ${item.styleCode}\n';
                if (includeShade) caption += '*Shade*\t\t: ${item.shadeName}\n';
                if (includeRate)
                  caption += '*MRP*\t\t\t: ${item.mrp.toString()}\n';
                if (includeSize) {
                  caption +=
                      '*Sizes*\t\t\t: ${includeLabel ? item.sizeDetails : formatSizes(item.sizeWithMrp)}\n';
                }
                if (includeProduct)
                  caption += '*Product*\t: ${item.itemName}\n';
                if (includeRemark) caption += '*Remark*\t\t: ${item.remark}\n';
                if(AppConstants.whatsappType == "U")
                {
                bool result = await sendWhatsAppFile(
                  fileBytes: imageBytes,
                  mobileNo: mobileNo,
                  fileType: 'image',
                  caption: caption,
                );

                if (!result) {
                  print("Failed to send image for ${item.itemName}.");
                }
                }
                else{
                   bool result = await sendWhatsAppOfficialFile(
                  fileBytes: imageBytes,
                  mobileNo: mobileNo,
                  fileType: 'image',
                  caption: caption,
                );

                if (!result) {
                  print("Failed to send image for ${item.itemName}.");
                }

                }
              } else {
                print(
                  "Failed to download the image for ${item.itemName}. Status Code: ${response.statusCode}",
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
        }
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share items: ${e.toString()}')),
      );
    }
  }

  Future<Map<String, String>?> _showMobileNumberDialog() async {
    TextEditingController mobileController = TextEditingController();
    String selectedType = 'image'; // default selection

    return showDialog<Map<String, String>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Mobile Number"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Mobile Number",
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// Image Radio
                  RadioListTile<String>(
                    title: const Text("Image"),
                    value: 'image',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),

                  /// PDF Radio
                  RadioListTile<String>(
                    title: const Text("PDF"),
                    value: 'pdf',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'mobileNo': mobileController.text.trim(),
                  'shareType': selectedType,
                });
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
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
  }) async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to share')),
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
              Text('Preparing items for sharing...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final List<Map<String, String>> catalogItems = [];
      for (var item in selectedItems) {
        final imageUrls = _getImageUrl(item);
        print('Image URLs before use: $imageUrls');

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
            'fullImagePath': imageUrl,
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
          await Share.shareFiles(filePaths);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Images shared successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid images to share')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate images: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share items: ${e.toString()}')),
      );
      print('Error in _shareSelectedItems: $e');
    }
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
    void _shareAsLink() {
      try {
        // Concatenate styleKey values with commas
        final styleKeys = selectedItems.map((item) => item.styleKey).join(',');
        // Encode in Base64
        final encodedStyleKeys = base64Encode(utf8.encode(styleKeys));
        // Construct the shareable URL
        final shareUrl = '${AppConstants.BASE_URL}/share/$encodedStyleKeys';

        // Show dialog with share link and QR code
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: const Text('Share as Link'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Share this link or scan the QR code:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      shareUrl,
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('Link copied to clipboard')),
                    // );
                    Clipboard.setData(ClipboardData(text: shareUrl));
                    // Navigator.pop(context); // Optional: close dialog after copy
                  },
                  child: const Text('Copy Link'),
                ),
                TextButton(
                  onPressed: () async {
                    await Share.share(shareUrl, subject: 'Catalog Share Link');
                    Navigator.pop(
                      context,
                    ); // Optional: close dialog after share
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link shared successfully')),
                    );
                  },
                  child: const Text('Share Link'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share link: ${e.toString()}')),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final styleKeys = selectedItems.map((item) => item.styleKey).join(',');
        final encodedStyleKeys = base64Encode(utf8.encode(styleKeys));
        final shareUrl = '${AppConstants.BASE_URL}/share/$encodedStyleKeys';
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
          onWhatsAppShare: ({
            bool includeDesign = true,
            bool includeShade = true,
            bool includeRate = true,
            bool includeSize = true,
            bool includeProduct = true,
            bool includeRemark = true,
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
            );
          },
          onLinkShare: () {
            _shareAsLink();
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
            _saveToggleStates(); // Save updated toggle states
          },
        );
      },
    );
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
              'fullImagePath': imageUrl,
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Show Sizes', style: TextStyle(fontSize: 16)),
                  if (showMRP && showWSP && showSizes) Row(),
                ],
              ),
              Switch(
                value: showSizes,
                onChanged: (val) {
                  if (!val) parentSetState(() => showFullSizeDetails = false);
                  parentSetState(() => showSizes = val);
                  setStateDialog(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title), Switch(value: value, onChanged: onChanged)],
    );
  }
}
