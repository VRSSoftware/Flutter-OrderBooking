import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:google_fonts/google_fonts.dart';

// New model class for image-based items
class ImageItem {
  final String itemKey;
  final String itemName;
  final String imageUrl; // URL or asset path for the image

  ImageItem({
    required this.itemKey,
    required this.itemName,
    required this.imageUrl,
  });
}

class StockFilterPage extends StatefulWidget {
  @override
  _StockFilterPageState createState() => _StockFilterPageState();
}

class _StockFilterPageState extends State<StockFilterPage> {
  List<Style> styles = [];
  List<Shade> shades = [];
  List<Sizes> sizes = [];
  List<Shade> selectedShades = [];
  List<Sizes> selectedSizes = [];
  List<Style> selectedStyles = [];
  List<Brand> brands = [];
  List<Brand> selectedBrands = [];
  bool isCheckboxModeBrand = true;
  bool isBrandExpanded = true;
  bool withImage = false;
  bool _isInitialized = false;

  TextEditingController fromMRPController = TextEditingController();
  TextEditingController toMRPController = TextEditingController();

  bool isCheckboxModeShade = true;
  bool isShadeExpanded = true;
  bool isCheckboxModeSize = true;
  bool isSizeExpanded = true;

  // New fields for image items and stock status
  List<ImageItem> imageItems = [];
  List<ImageItem> selectedImageItems = [];
  bool isImageExpanded = true;
  String stockStatus = 'All'; // Default stock status

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_isInitialized) return;
    _isInitialized = true;
    
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      styles = args['styles'] is List<Style> ? args['styles'] : [];
      shades = args['shades'] is List<Shade> ? args['shades'] : [];
      selectedShades =
          args['selectedShades'] is List<Shade> ? args['selectedShades'] : [];
      sizes = args['sizes'] is List<Sizes> ? args['sizes'] : [];
      selectedStyles =
          args['selectedStyles'] is List<Style> ? args['selectedStyles'] : [];
      selectedSizes =
          args['selectedSizes'] is List<Sizes> ? args['selectedSizes'] : [];
      selectedBrands =
          args['selectedBrands'] is List<Brand> ? args['selectedBrands'] : [];
      fromMRPController.text = args['fromMRP'] is String ? args['fromMRP'] : "";
      toMRPController.text = args['toMRP'] is String ? args['toMRP'] : "";
      brands = args['brands'] is List<Brand> ? args['brands'] : [];
      imageItems = args['imageItems'] is List<ImageItem> ? args['imageItems'] : [];
      selectedImageItems =
          args['selectedImageItems'] is List<ImageItem> ? args['selectedImageItems'] : [];
      stockStatus = args['stockStatus'] is String ? args['stockStatus'] : 'All';
      withImage = args['withImage'] ?? false; 
    }
  }

  void syncSelectedBrands(List<Brand> newSelectedBrands) {
    setState(() {
      selectedBrands = List.from(newSelectedBrands);
    });
  }

  void syncSelectedShades(List<Shade> newSelectedShades) {
    setState(() {
      selectedShades = List.from(newSelectedShades);
    });
  }

  void syncSelectedSizes(List<Sizes> newSelectedSizes) {
    setState(() {
      selectedSizes = List.from(newSelectedSizes);
    });
  }

  void syncSelectedImageItems(List<ImageItem> newSelectedImageItems) {
    setState(() {
      selectedImageItems = List.from(newSelectedImageItems);
    });
  }

  Widget _buildCheckboxSection<T>(
    List<T> items,
    List<T> selectedItems,
    bool Function(T, T) compareFn,
    String Function(T) labelFn,
    Function(List<T>) onChanged,
  ) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 3) {
      List<T> rowItems = items.sublist(
        i,
        i + 3 > items.length ? items.length : i + 3,
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children:
                rowItems.map((item) {
                  bool isSelected = selectedItems.any((s) => compareFn(s, item));
                  return Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  if (!selectedItems.any(
                                    (s) => compareFn(s, item),
                                  )) {
                                    selectedItems.add(item);
                                  }
                                } else {
                                  selectedItems.removeWhere(
                                    (s) => compareFn(s, item),
                                  );
                                }
                              });
                              onChanged(selectedItems);
                            },
                            activeColor: AppColors.primaryColor,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? AppColors.primaryColor
                                      : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            labelFn(item),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  // Updated method for image checkbox section with circular images
  Widget _buildImageCheckboxSection(
    List<ImageItem> items,
    List<ImageItem> selectedItems,
    Function(List<ImageItem>) onChanged,
  ) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) { // 2 items per row for better layout
      List<ImageItem> rowItems = items.sublist(
        i,
        i + 2 > items.length ? items.length : i + 2,
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowItems.map((item) {
              bool isSelected = selectedItems.any((s) => s.itemKey == item.itemKey);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!selectedItems.any((s) => s.itemKey == item.itemKey)) {
                                  selectedItems.add(item);
                                }
                              } else {
                                selectedItems.removeWhere((s) => s.itemKey == item.itemKey);
                              }
                            });
                            onChanged(selectedItems);
                          },
                          activeColor: AppColors.primaryColor,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipOval(
                              child: Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                ),
                                child: item.imageUrl.startsWith('http')
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Icon(Icons.broken_image, size: 30, color: Colors.grey.shade400),
                                      )
                                    : Image.asset(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Icon(Icons.broken_image, size: 30, color: Colors.grey.shade400),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.itemName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  // Stock status radio buttons
  Widget _buildStockStatusRadio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildRadioOption(
            'All',
            isSelected: stockStatus == 'All',
            onTap: () => setState(() => stockStatus = 'All'),
          ),
          const SizedBox(width: 20),
          _buildRadioOption(
            'Ready',
            isSelected: stockStatus == 'Ready',
            onTap: () => setState(() => stockStatus = 'Ready'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Radio<bool>(
                value: isSelected,
                groupValue: true,
                activeColor: AppColors.primaryColor,
                onChanged: (_) => onTap(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = true,
    ValueChanged<bool>? onExpansionChanged,
  }) {
    return CustomExpansionTile(
      title: title,
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text(
          'Stock Filter',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey.shade50,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  children: [
                    // Styles Section
                    _buildExpansionTile(
                      title: 'Select Styles',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          child: DropdownSearch<Style>.multiSelection(
                            items: styles,
                            selectedItems: selectedStyles,
                            onChanged: (selectedItems) {
                              selectedStyles.clear();
                              selectedStyles.addAll(selectedItems ?? []);
                            },
                            popupProps: PopupPropsMultiSelection.menu(
                              showSearchBox: true,
                              searchDelay: Duration(milliseconds: 300),
                              menuProps: MenuProps(
                                backgroundColor: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 4,
                              ),
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: 'Search styles...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade400,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            itemAsString: (Style s) => s.styleCode,
                            compareFn: (a, b) => a.styleKey == b.styleKey,
                            dropdownBuilder: (context, selectedItems) {
                              if (selectedItems.isEmpty) {
                                return Text(
                                  'Select styles',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                );
                              }
                              return Container(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  selectedItems
                                      .map((e) => e.styleCode)
                                      .join(', '),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                hintText: 'Select styles',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade600,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Shades Section
                    _buildExpansionTile(
                      title: 'Select Shades',
                      initiallyExpanded: isShadeExpanded,
                      onExpansionChanged:
                          (expanded) => setState(() => isShadeExpanded = expanded),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildModeSelector(
                                    isCheckboxMode: isCheckboxModeShade,
                                    onChanged:
                                        (value) => setState(
                                          () =>
                                              isCheckboxModeShade =
                                                  value == 'Checkbox',
                                        ),
                                  ),
                                  _buildSelectAllButton(
                                    selectedCount: selectedShades.length,
                                    totalCount: shades.length,
                                    onPressed:
                                        () => setState(() {
                                          selectedShades =
                                              selectedShades.length == shades.length
                                                  ? []
                                                  : List.from(shades);
                                        }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              isCheckboxModeShade
                                  ? _buildCheckboxSection<Shade>(
                                    shades,
                                    selectedShades,
                                    (a, b) => a.shadeKey == b.shadeKey,
                                    (s) => s.shadeName,
                                    syncSelectedShades,
                                  )
                                  : _buildDropdownSection<Shade>(
                                    items: shades,
                                    selectedItems: selectedShades,
                                    hintText: 'Search and select shades',
                                    itemAsString: (s) => s.shadeName,
                                    compareFn:
                                        (a, b) => a.shadeKey == b.shadeKey,
                                    onChanged: syncSelectedShades,
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Sizes Section
                    _buildExpansionTile(
                      title: 'Select Sizes',
                      initiallyExpanded: isSizeExpanded,
                      onExpansionChanged:
                          (expanded) => setState(() => isSizeExpanded = expanded),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildModeSelector(
                                    isCheckboxMode: isCheckboxModeSize,
                                    onChanged:
                                        (value) => setState(
                                          () =>
                                              isCheckboxModeSize =
                                                  value == 'Checkbox',
                                        ),
                                  ),
                                  _buildSelectAllButton(
                                    selectedCount: selectedSizes.length,
                                    totalCount: sizes.length,
                                    onPressed:
                                        () => setState(() {
                                          selectedSizes =
                                              selectedSizes.length == sizes.length
                                                  ? []
                                                  : List.from(sizes);
                                        }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              isCheckboxModeSize
                                  ? _buildCheckboxSection<Sizes>(
                                    sizes,
                                    selectedSizes,
                                    (a, b) => a.itemSizeKey == b.itemSizeKey,
                                    (s) => s.sizeName,
                                    syncSelectedSizes,
                                  )
                                  : _buildDropdownSection<Sizes>(
                                    items: sizes,
                                    selectedItems: selectedSizes,
                                    hintText: 'Search and select sizes',
                                    itemAsString: (s) => s.sizeName,
                                    compareFn:
                                        (a, b) => a.itemSizeKey == b.itemSizeKey,
                                    onChanged: syncSelectedSizes,
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Brands Section
                    _buildExpansionTile(
                      title: 'Select Brands',
                      initiallyExpanded: isBrandExpanded,
                      onExpansionChanged:
                          (expanded) => setState(() => isBrandExpanded = expanded),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildModeSelector(
                                    isCheckboxMode: isCheckboxModeBrand,
                                    onChanged:
                                        (value) => setState(
                                          () =>
                                              isCheckboxModeBrand =
                                                  value == 'Checkbox',
                                        ),
                                  ),
                                  _buildSelectAllButton(
                                    selectedCount: selectedBrands.length,
                                    totalCount: brands.length,
                                    onPressed:
                                        () => setState(() {
                                          selectedBrands =
                                              selectedBrands.length == brands.length
                                                  ? []
                                                  : List.from(brands);
                                        }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              isCheckboxModeBrand
                                  ? _buildCheckboxSection<Brand>(
                                    brands,
                                    selectedBrands,
                                    (a, b) => a.brandKey == b.brandKey,
                                    (b) => b.brandName,
                                    syncSelectedBrands,
                                  )
                                  : _buildDropdownSection<Brand>(
                                    items: brands,
                                    selectedItems: selectedBrands,
                                    hintText: 'Search and select brands',
                                    itemAsString: (b) => b.brandName,
                                    compareFn:
                                        (a, b) => a.brandKey == b.brandKey,
                                    onChanged: syncSelectedBrands,
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Image Items Section (if available)
                    if (imageItems.isNotEmpty)
                      Column(
                        children: [
                          _buildExpansionTile(
                            title: 'Select Images',
                            initiallyExpanded: isImageExpanded,
                            onExpansionChanged:
                                (expanded) => setState(() => isImageExpanded = expanded),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildModeSelector(
                                          isCheckboxMode: true, // Force checkbox mode for images
                                          onChanged: (_) {}, // No-op since we only support checkbox
                                        ),
                                        _buildSelectAllButton(
                                          selectedCount: selectedImageItems.length,
                                          totalCount: imageItems.length,
                                          onPressed:
                                              () => setState(() {
                                                selectedImageItems =
                                                    selectedImageItems.length == imageItems.length
                                                        ? []
                                                        : List.from(imageItems);
                                              }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    _buildImageCheckboxSection(
                                      imageItems,
                                      selectedImageItems,
                                      syncSelectedImageItems,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),

                    // With Image Checkbox
                    _buildExpansionTile(
                      title: 'Image Options',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: withImage,
                                  onChanged: (value) {
                                    setState(() {
                                      withImage = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.primaryColor,
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(
                                    color: withImage ? AppColors.primaryColor : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Show Images in Report',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Stock Status Section
                    _buildExpansionTile(
                      title: 'Stock Status',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: _buildStockStatusRadio(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // MRP Range Section
                    _buildExpansionTile(
                      title: 'MRP Range',
                      children: [
                        _buildRangeInputs(
                          fromMRPController,
                          toMRPController,
                          'From MRP',
                          'To MRP',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Buttons at the Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Map<String, dynamic> selectedFilters = {
                              'styles': selectedStyles,
                              'shades': selectedShades,
                              'sizes': selectedSizes,
                              'brands': selectedBrands,
                              'fromMRP': fromMRPController.text,
                              'toMRP': toMRPController.text,
                              'imageItems': selectedImageItems,
                              'stockStatus': stockStatus,
                              'withImage': withImage,
                            };
                            Navigator.pop(context, selectedFilters);
                          },
                          child: Text(
                            'Apply Filters',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedStyles = [];
                              selectedShades = [];
                              selectedSizes = [];
                              selectedBrands = [];
                              fromMRPController.clear();
                              toMRPController.clear();
                              selectedImageItems = [];
                              stockStatus = 'All';
                              withImage = false;
                            });
                          },
                          child: Text(
                            'Clear',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  Widget _buildModeSelector({
    required bool isCheckboxMode,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            icon: Icons.check_box,
            label: 'Checkbox',
            isSelected: isCheckboxMode,
            onTap: () => onChanged('Checkbox'),
          ),
          _buildModeButton(
            icon: Icons.list,
            label: 'Combo',
            isSelected: !isCheckboxMode,
            onTap: () => onChanged('Combo'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllButton({
    required int selectedCount,
    required int totalCount,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.primaryColor,
      ),
      child: Text(
        selectedCount == totalCount ? 'Deselect All' : 'Select All',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selectedCount == totalCount ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildDropdownSection<T>({
    required List<T> items,
    required List<T> selectedItems,
    required String hintText,
    required String Function(T) itemAsString,
    required bool Function(T, T) compareFn,
    required Function(List<T>) onChanged,
  }) {
    return DropdownSearch<T>.multiSelection(
      items: items,
      selectedItems: selectedItems,
      onChanged: (selectedItems) => onChanged(selectedItems ?? []),
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        searchDelay: Duration(milliseconds: 300),
        menuProps: MenuProps(
          backgroundColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 4,
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
      itemAsString: itemAsString,
      compareFn: compareFn,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: 'Select ${hintText.split(' ').last}',
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      dropdownBuilder: (context, selectedItems) {
        if (selectedItems?.isEmpty ?? true) {
          return Text(
            'Select ${hintText.split(' ').last}',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 14),
          );
        }
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            selectedItems!.map(itemAsString).join(', '),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Widget _buildRangeInputs(
    TextEditingController fromController,
    TextEditingController toController,
    String fromLabel,
    String toLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Expanded(child: _buildNumberInput(fromController, fromLabel)),
          SizedBox(width: 12),
          Expanded(child: _buildNumberInput(toController, toLabel)),
        ],
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(color: AppColors.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.plusJakartaSans(),
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const CustomExpansionTile({
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
    this.onExpansionChanged,
  });

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            _isExpanded
                ? Border.all(color: Colors.grey.shade200, width: 1)
                : Border(
                  left: BorderSide(color: AppColors.primaryColor, width: 4),
                ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            widget.onExpansionChanged?.call(expanded);
          },
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          childrenPadding: EdgeInsets.only(bottom: 4),
          trailing: Icon(
            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 22,
            color: AppColors.primaryColor,
          ),
          children: widget.children,
        ),
      ),
    );
  }
}