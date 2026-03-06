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

class FilterPage extends StatefulWidget {
  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  List<Style> styles = [];
  List<Shade> shades = [];
  List<Sizes> sizes = [];
  List<Shade> selectedShades = [];
  List<Sizes> selectedSizes = [];
  List<Style> selectedStyles = [];
  List<String> selectedStyleKeys = [];

  List<Brand> brands = [];
  List<Brand> selectedBrands = [];
  bool isCheckboxModeBrand = true;
  bool isBrandExpanded = true;

  TextEditingController fromMRPController = TextEditingController();
  TextEditingController toMRPController = TextEditingController();
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();
  TextEditingController wspFromController = TextEditingController();
  TextEditingController wspToController = TextEditingController();

  bool isCheckboxModeShade = true;
  bool isShadeExpanded = true;
  bool isCheckboxModeSize = true;
  bool isSizeExpanded = true;
  
  String? sortBy;
  String? stockFilter;
  String? imageFilter;
  
  DateTime? fromDate;
  DateTime? toDate;
  bool _isInitialized = false;

  final List<Map<String, String>> sortOptions = [
    {'value': 'design desc', 'label': 'Design: New to Old'},
    {'value': 'design asc', 'label': 'Design: Old to New'},
    {'value': 'MRP asc', 'label': 'Price: Low to High'},
    {'value': 'MRP desc', 'label': 'Price: High to Low'},
  ];

  final List<Map<String, String>> stockOptions = [
    {'value': '', 'label': 'All'},
    {'value': 'upcoming', 'label': 'Upcoming'},
    {'value': 'ready', 'label': 'Ready Stock'},
  ];

  final List<Map<String, String>> imageOptions = [
    {'value': 'All', 'label': 'All'},
    {'value': 'Having Image', 'label': 'Having Image'},
    {'value': 'Not Having Image', 'label': 'Not Having Image'},
  ];

  // Helper methods to check if a section has active filters
  bool get hasSortFilter => sortBy != null && sortBy!.isNotEmpty;
  bool get hasMRPFilter => fromMRPController.text.isNotEmpty || toMRPController.text.isNotEmpty;
  bool get hasWSPFilter => wspFromController.text.isNotEmpty || wspToController.text.isNotEmpty;
  bool get hasDateFilter => fromDateController.text.isNotEmpty || toDateController.text.isNotEmpty;
  bool get hasStockFilter => stockFilter != null && stockFilter!.isNotEmpty && stockFilter != '';
  bool get hasImageFilter => imageFilter != null && imageFilter!.isNotEmpty && imageFilter != 'All';
  bool get hasStyleFilter => selectedStyles.isNotEmpty;
  bool get hasShadeFilter => selectedShades.isNotEmpty;
  bool get hasSizeFilter => selectedSizes.isNotEmpty;
  bool get hasBrandFilter => selectedBrands.isNotEmpty;

  // Get total active filter count
  int get activeFilterCount {
    int count = 0;
    if (hasSortFilter) count++;
    if (hasMRPFilter) count++;
    if (hasWSPFilter) count++;
    if (hasDateFilter) count++;
    if (hasStockFilter) count++;
    if (hasImageFilter) count++;
    if (hasStyleFilter) count++;
    if (hasShadeFilter) count++;
    if (hasSizeFilter) count++;
    if (hasBrandFilter) count++;
    return count;
  }

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
      sizes = args['sizes'] is List<Sizes> ? args['sizes'] : [];
      brands = args['brands'] is List<Brand> ? args['brands'] : [];

      selectedShades =
          args['selectedShades'] is List<Shade> ? args['selectedShades'] : [];
      selectedStyles =
          args['selectedStyles'] is List<Style> ? args['selectedStyles'] : [];
      selectedSizes =
          args['selectedSizes'] is List<Sizes> ? args['selectedSizes'] : [];
      selectedBrands =
          args['selectedBrands'] is List<Brand> ? args['selectedBrands'] : [];

      fromMRPController.text = args['fromMRP'] ?? "";
      toMRPController.text = args['toMRP'] ?? "";
      wspFromController.text = args['WSPfrom'] ?? "";
      wspToController.text = args['WSPto'] ?? "";

      fromDateController.text = args['fromDate'] ?? "";
      toDateController.text = args['toDate'] ?? "";

      fromDate = DateTime.tryParse(args['fromDate'] ?? '');
      toDate = DateTime.tryParse(args['toDate'] ?? '');

      sortBy = args['sortBy'];
      stockFilter = args['stockFilter'];
      imageFilter = args['imageFilter'];
    }
  }

  void syncSelectedBrands(List<Brand> newSelectedBrands) {
    setState(() {
      selectedBrands = List.from(newSelectedBrands);
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    DateTime? initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (controller == fromDateController) {
          fromDate = picked;
        } else if (controller == toDateController) {
          toDate = picked;
        }
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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

  Widget _buildCheckboxSection<T>(
    List<T> items,
    List<T> selectedItems,
    bool Function(T, T) compareFn,
    String Function(T) labelFn,
    Function(List<T>) onChanged,
  ) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No items available',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

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
                  bool isSelected = selectedItems.any(
                    (s) => compareFn(s, item),
                  );
                  return Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
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
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
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

Widget _buildExpansionTile({
  required String title,
  required List<Widget> children,
  bool initiallyExpanded = true,
  ValueChanged<bool>? onExpansionChanged,
  required bool hasActiveFilter,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 6, top: 4), // Added top margin for checkmark space
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasActiveFilter ? Colors.blue : Colors.transparent,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            title: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            initiallyExpanded: initiallyExpanded,
            onExpansionChanged: onExpansionChanged,
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            childrenPadding: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
            trailing: Icon(
              initiallyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.primaryColor,
            ),
            children: children,
          ),
        ),
      ),
      if (hasActiveFilter)
        Positioned(
          top: -2, // Position above the card
          right: -2, // Position to the right of the card
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
    ],
  );
}
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: DropdownButtonFormField<T>(
        value: value,
        isDense: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
          floatingLabelStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel(item),
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        hint: hintText != null
            ? Text(
                hintText,
                style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13),
              )
            : null,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text(
          'Filter',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                child: Column(
                  children: [
                    // Sort By Dropdown
                    _buildExpansionTile(
                      title: 'Sort By',
                      initiallyExpanded: true,
                      hasActiveFilter: hasSortFilter,
                      children: [
                        _buildDropdownField<Map<String, String>>(
                          label: 'Select Sort Option',
                          value: sortOptions.firstWhere(
                            (option) => option['value'] == sortBy,
                            orElse: () => sortOptions.first,
                          ),
                          items: sortOptions,
                          itemLabel: (option) => option['label']!,
                          onChanged: (selectedOption) {
                            setState(() {
                              sortBy = selectedOption?['value'];
                            });
                          },
                          hintText: 'Choose sorting order',
                        ),
                      ],
                    ),

                    // MRP Range
                    _buildExpansionTile(
                      title: 'MRP Range',
                      hasActiveFilter: hasMRPFilter,
                      children: [
                        _buildRangeInputs(
                          fromMRPController,
                          toMRPController,
                          'From MRP',
                          'To MRP',
                        ),
                      ],
                    ),

                    // WSP Range
                    _buildExpansionTile(
                      title: 'WSP Range',
                      hasActiveFilter: hasWSPFilter,
                      children: [
                        _buildRangeInputs(
                          wspFromController,
                          wspToController,
                          'From WSP',
                          'To WSP',
                        ),
                      ],
                    ),

                    // Date Range
                    _buildExpansionTile(
                      title: 'Date Range',
                      hasActiveFilter: hasDateFilter,
                      children: [_buildDateInputs()],
                    ),

                    // Stock Filter
                    _buildExpansionTile(
                      title: 'Stock',
                      initiallyExpanded: true,
                      hasActiveFilter: hasStockFilter,
                      children: [
                        _buildDropdownField<Map<String, String>>(
                          label: 'Select Stock Type',
                          value: stockOptions.firstWhere(
                            (option) => option['value'] == stockFilter,
                            orElse: () => stockOptions.first,
                          ),
                          items: stockOptions,
                          itemLabel: (option) => option['label']!,
                          onChanged: (selectedOption) {
                            setState(() {
                              stockFilter = selectedOption?['value'];
                            });
                          },
                          hintText: 'Choose stock filter',
                        ),
                      ],
                    ),

                    // Image Filter
                    _buildExpansionTile(
                      title: 'Image',
                      initiallyExpanded: true,
                      hasActiveFilter: hasImageFilter,
                      children: [
                        _buildDropdownField<Map<String, String>>(
                          label: 'Select Image Option',
                          value: imageOptions.firstWhere(
                            (option) => option['value'] == imageFilter,
                            orElse: () => imageOptions.first,
                          ),
                          items: imageOptions,
                          itemLabel: (option) => option['label']!,
                          onChanged: (selectedOption) {
                            setState(() {
                              imageFilter = selectedOption?['value'];
                            });
                          },
                          hintText: 'Choose image filter',
                        ),
                      ],
                    ),

                    // Styles Selection
                    _buildExpansionTile(
                      title: 'Select Styles',
                      hasActiveFilter: hasStyleFilter,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: selectedStyles.isNotEmpty
                                ? Border.all(color: Colors.transparent, width: 1)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: DropdownSearch<Style>.multiSelection(
                              items: styles,
                              selectedItems: selectedStyles,
                              onChanged: (selectedItems) {
                                setState(() {
                                  selectedStyles = selectedItems ?? [];
                                });
                              },
                              popupProps: PopupPropsMultiSelection.menu(
                                showSearchBox: true,
                                searchDelay: Duration(milliseconds: 300),
                                menuProps: MenuProps(
                                  backgroundColor: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  elevation: 4,
                                ),
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Search styles...',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade600,
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
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
                                      fontSize: 13,
                                    ),
                                  );
                                }
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedItems
                                              .map((e) => e.styleCode)
                                              .join(', '),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (selectedItems.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${selectedItems.length}',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  hintText: 'Select styles',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey.shade600,
                                    size: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Shades Selection
                    _buildExpansionTile(
                      title: 'Select Shades',
                      initiallyExpanded: isShadeExpanded,
                      hasActiveFilter: hasShadeFilter,
                      onExpansionChanged:
                          (expanded) =>
                              setState(() => isShadeExpanded = expanded),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: selectedShades.isNotEmpty
                                ? Border.all(color: Colors.transparent, width: 1)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                selectedShades.length ==
                                                        shades.length
                                                    ? []
                                                    : List.from(shades);
                                          }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
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
                        ),
                      ],
                    ),

                    // Sizes Selection
                    _buildExpansionTile(
                      title: 'Select Sizes',
                      initiallyExpanded: isSizeExpanded,
                      hasActiveFilter: hasSizeFilter,
                      onExpansionChanged:
                          (expanded) =>
                              setState(() => isSizeExpanded = expanded),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: selectedSizes.isNotEmpty
                                ? Border.all(color: Colors.transparent, width: 1)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                selectedSizes.length ==
                                                        sizes.length
                                                    ? []
                                                    : List.from(sizes);
                                          }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Brands Selection
                    _buildExpansionTile(
                      title: 'Select Brands',
                      initiallyExpanded: isBrandExpanded,
                      hasActiveFilter: hasBrandFilter,
                      onExpansionChanged:
                          (expanded) =>
                              setState(() => isBrandExpanded = expanded),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: selectedBrands.isNotEmpty
                                ? Border.all(color: Colors.transparent, width: 1)
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                                selectedBrands.length ==
                                                        brands.length
                                                    ? []
                                                    : List.from(brands);
                                          }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Buttons
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: Offset(0, -3),
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
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                              'fromDate': fromDateController.text,
                              'toDate': toDateController.text,
                              'WSPfrom': wspFromController.text,
                              'WSPto': wspToController.text,
                              'sortBy': sortBy,
                              'stockFilter': stockFilter,
                              'imageFilter': imageFilter,
                            };
                            Navigator.pop(context, selectedFilters);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Apply Filters',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (activeFilterCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$activeFilterCount',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedStyles.clear();
                              selectedShades.clear();
                              selectedSizes.clear();
                              selectedBrands.clear();
                              fromMRPController.clear();
                              toMRPController.clear();
                              fromDateController.clear();
                              toDateController.clear();
                              wspFromController.clear();
                              wspToController.clear();
                              sortBy = null;
                              stockFilter = '';
                              imageFilter = 'All';
                            });
                          },
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
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
        borderRadius: BorderRadius.circular(6),
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.primaryColor,
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.primaryColor,
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        selectedCount == totalCount ? 'Deselect All' : 'Select All',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
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
          borderRadius: BorderRadius.circular(10),
          elevation: 4,
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
      itemAsString: itemAsString,
      compareFn: compareFn,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: 'Select ${hintText.split(' ').last}',
          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      dropdownBuilder: (context, selectedItems) {
        if (selectedItems?.isEmpty ?? true) {
          return Text(
            'Select ${hintText.split(' ').last}',
            style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600, fontSize: 13),
          );
        }
        return Container(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedItems!.map(itemAsString).join(', '),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedItems.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selectedItems.length}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(child: _buildNumberInput(fromController, fromLabel)),
          SizedBox(width: 8),
          Expanded(child: _buildNumberInput(toController, toLabel)),
        ],
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller, String label) {
    bool hasValue = controller.text.isNotEmpty;
    
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: hasValue ? AppColors.primaryColor : Colors.grey.shade600,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.primaryColor,
          fontSize: 13,
        ),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: hasValue
            ? Icon(Icons.check_circle, color: AppColors.primaryColor, size: 14)
            : null,
      ),
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
    );
  }

  Widget _buildDateInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: _buildDateInput(fromDateController, 'From Date', fromDate),
          ),
          SizedBox(width: 8),
          Expanded(child: _buildDateInput(toDateController, 'To Date', toDate)),
        ],
      ),
    );
  }

  Widget _buildDateInput(
    TextEditingController controller,
    String label,
    DateTime? date,
  ) {
    bool hasValue = controller.text.isNotEmpty;
    
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: hasValue ? AppColors.primaryColor : Colors.grey.shade600,
          fontSize: 13,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.primaryColor,
          fontSize: 13,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.calendar_today,
            color: hasValue ? AppColors.primaryColor : AppColors.primaryColor,
            size: 14,
          ),
          onPressed: () => _selectDate(context, controller, date),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          iconSize: 14,
        ),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
    );
  }
}