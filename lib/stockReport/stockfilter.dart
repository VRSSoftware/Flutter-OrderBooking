import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';

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

  bool _isExpanded = true;

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              rowItems.map((item) {
                bool isSelected = selectedItems.any((s) => compareFn(s, item));
                return Expanded(
                  child: Row(
                    children: [
                      Checkbox(
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
                      ),
                      Expanded(
                        child: Text(
                          labelFn(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: rows),
        ),
      ],
    );
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowItems.map((item) {
            bool isSelected = selectedItems.any((s) => s.itemKey == item.itemKey);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
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
                    ),
                    SizedBox(width: 8),
                    Column(
                      children: [
                        ClipOval( // Makes the image circular
                          child: Container(
                            height: 80, // Fixed height for image
                            width: 80,  // Fixed width for image
                            child: item.imageUrl.startsWith('http')
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  )
                                : Image.asset(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.itemName,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: rows),
        ),
      ],
    );
  }

  // Stock status radio buttons
  Widget _buildStockStatusRadio() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          children: [
            Radio<String>(
              value: 'All',
              groupValue: stockStatus,
              onChanged: (String? value) {
                setState(() {
                  stockStatus = value ?? 'All';
                });
              },
              activeColor: AppColors.primaryColor,
            ),
            Text('All', style: TextStyle(color: AppColors.primaryColor)),
          ],
        ),
        SizedBox(width: 20),
        Row(
          children: [
            Radio<String>(
              value: 'Ready',
              groupValue: stockStatus,
              onChanged: (String? value) {
                setState(() {
                  stockStatus = value ?? 'All';
                });
              },
              activeColor: AppColors.primaryColor,
            ),
            Text('Ready', style: TextStyle(color: AppColors.primaryColor)),
          ],
        ),
      ],
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
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Stock Filter', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              children: [
                // Styles Section
                _buildExpansionTile(
                  title: 'Select Styles',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
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
                          menuProps: MenuProps(backgroundColor: Colors.white),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search and select styles',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        itemAsString: (Style s) => s.styleCode,
                        compareFn: (a, b) => a.styleKey == b.styleKey,
                        dropdownBuilder:
                            (context, selectedItems) => Text(
                              selectedItems.isEmpty
                                  ? 'Select styles'
                                  : selectedItems
                                      .map((e) => e.styleCode)
                                      .join(', '),
                            ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

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
                        vertical: 8,
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child:
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

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
                        vertical: 8,
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child:
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
                                          (a, b) =>
                                              a.itemSizeKey == b.itemSizeKey,
                                      onChanged: syncSelectedSizes,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child:
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

              // With Image Checkbox
              const SizedBox(height: 10),
              _buildExpansionTile(
  title: 'Image Options',
  children: [
    Row(
      children: [
        Checkbox(
          value: withImage,
          onChanged: (value) {
            setState(() {
              withImage = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
        ),
        const Text('Show Images in Report'),
      ],
    ),
  ],
),

                SizedBox(height: 16),

                // Stock Status Section
                _buildExpansionTile(
                  title: 'Stock Status',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: _buildStockStatusRadio(),
                    ),
                  ],
                ),

                SizedBox(height: 16),

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

                SizedBox(height: 20),
              ],
            ),
          ),

      // Filter Buttons at the Bottom
Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
            // Apply Filters Button
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
            child: const Text(
              'Apply Filters',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
         const SizedBox(width: 10),
    
        // Clear Filters Button
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
               // stockStatus = null;
                withImage = false;
              });
            },
            child: const Text(
              'Clear Filters',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
       
      ],
    ),
  ),
),

        ],
      ),
    );
  }

  Widget _buildModeSelector({
    required bool isCheckboxMode,
    required ValueChanged<String?> onChanged,
  }) {
    return ToggleButtons(
      isSelected: [isCheckboxMode, !isCheckboxMode],
      onPressed: (int index) {
        final value = index == 0 ? 'Checkbox' : 'select';
        onChanged(value);
      },
      color: AppColors.primaryColor.withOpacity(0.2),
      selectedColor: AppColors.primaryColor,
      fillColor: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(8),
      borderColor: AppColors.primaryColor,
      selectedBorderColor: AppColors.primaryColor,
      constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_box,
                color: isCheckboxMode ? Colors.white : AppColors.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Checkbox',
                style: TextStyle(
                  color: isCheckboxMode ? Colors.white : AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.list,
                color: !isCheckboxMode ? Colors.white : AppColors.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Combo',
                style: TextStyle(
                  color:
                      !isCheckboxMode ? Colors.white : AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllButton({
    required int selectedCount,
    required int totalCount,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        selectedCount == totalCount ? 'Deselect All' : 'Select All',
        style: TextStyle(color: AppColors.primaryColor),
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
        menuProps: MenuProps(backgroundColor: Colors.white),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
          ),
        ),
      ),
      itemAsString: itemAsString,
      compareFn: compareFn,
      dropdownBuilder:
          (context, selectedItems) => Text(
            selectedItems?.isEmpty ?? true
                ? 'Select ${hintText.split(' ').last}'
                : selectedItems!.map(itemAsString).join(', '),
          ),
    );
  }

  Widget _buildRangeInputs(
    TextEditingController fromController,
    TextEditingController toController,
    String fromLabel,
    String toLabel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildNumberInput(fromController, fromLabel)),
          SizedBox(width: 10),
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
        labelStyle: TextStyle(color: const Color(0xFF87898A)),
        floatingLabelStyle: TextStyle(color: AppColors.primaryColor),
        hintStyle: TextStyle(color: const Color(0xFF87898A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
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
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (expanded) {
          setState(() => _isExpanded = expanded);
          widget.onExpansionChanged?.call(expanded);
        },
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: const Color.fromARGB(255, 202, 201, 201),
            width: 0.5,
          ), // Expanded border
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: const Color.fromARGB(255, 202, 201, 201),
            width: 0.5,
          ), // Collapsed border
        ),
        trailing: RotationTransition(
          turns: AlwaysStoppedAnimation(_isExpanded ? 0.5 : 0),
          child: Icon(
            Icons.keyboard_arrow_down,
            size: 24,
            color: AppColors.primaryColor,
          ),
        ),
        children: widget.children,
      ),
    );
  }
}