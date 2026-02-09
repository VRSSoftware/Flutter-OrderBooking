import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/brand.dart';
import 'package:vrs_erp/models/shade.dart';
import 'package:vrs_erp/models/size.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
  //List<String> selectedStyleCodes = [];
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
  String? sortType;
  DateTime? fromDate;
  DateTime? toDate;

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
      wspFromController.text = args['WSPfrom'] is String ? args['WSPfrom'] : "";
      wspToController.text = args['WSPto'] is String ? args['WSPto'] : "";
      print("sortttttttttt");
      print(args['sortyBy']);
      sortBy = args['sortBy'] is String ? args['sortBy'] : "";
      // fromDate =
      //     args['fromDate'] is String && args['fromDate'].isNotEmpty
      //         ? DateTime.tryParse(args['fromDate'])
      //         : null;
      // toDate =
      //     args['toDate'] is String && args['toDate'].isNotEmpty
      //         ? DateTime.tryParse(args['toDate'])
      //         : null;
      brands = args['brands'] is List<Brand> ? args['brands'] : [];
    
      selectedBrands =
          args['selectedBrands'] is List<Brand> ? args['selectedBrands'] : [];
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

  // Common ExpansionTile Widget
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
        title: Text(' Filter', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:Container(
  color: Colors.white, // Set background color
  child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              children: [
                _buildExpansionTile(
                  title: 'Sort By',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          _buildRadioOption(
                            'Latest Design',
                            isSelected: sortBy == 'design desc',
                            onTap:
                                () => setState(() {
                                  sortBy =
                                      'design desc'; // maps to ORDER BY created_dt DESC
                                }),
                          ),
                          _buildRadioOption(
                            'Price: Low to High',
                            isSelected: sortBy == 'MRP asc',
                            onTap:
                                () => setState(() {
                                  sortBy =
                                      'MRP asc'; // maps to ORDER BY MRP ASC
                                }),
                          ),
                          _buildRadioOption(
                            'Price: High to Low',
                            isSelected: sortBy == 'MRP desc',
                            onTap:
                                () => setState(() {
                                  sortBy =
                                      'MRP desc'; // maps to ORDER BY MRP DESC
                                }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
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
                           menuProps: MenuProps(
      backgroundColor: Colors.white,
    ),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search and select styles',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
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

                // WSP Range Section
                _buildExpansionTile(
                  title: 'WSP Range',
                  children: [
                    _buildRangeInputs(
                      wspFromController,
                      wspToController,
                      'WSP from',
                      'WSP to',
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Date Range Section
                _buildExpansionTile(
                  title: 'Date',
                  children: [_buildDateInputs()],
                ),
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
   
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
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
              };
              Navigator.pop(context, selectedFilters);
            },
            child: Text(
              'Apply Filters',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
         SizedBox(width: 12),
             Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[400],
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            onPressed: () {
              // Clear all filters
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

              setState(() {}); // Refresh UI if needed
            },
            child: Text(
              'Clear',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
       
      ],
    ),
  ),
),

        ],
     ) ),
  
    );
  }

  // Common Widgets
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
      borderRadius: BorderRadius.circular(0),
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
                                  menuProps: MenuProps(
      backgroundColor: Colors.white,
    ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(0)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
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
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColors.secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDateInputs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildDateInput(fromDateController, 'From Date', fromDate),
          ),
          SizedBox(width: 10),
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
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF87898A)),
        floatingLabelStyle: TextStyle(color: AppColors.primaryColor),
        hintStyle: TextStyle(color: const Color(0xFF87898A)),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today, color: AppColors.primaryColor),
          onPressed: () => _selectDate(context, controller, date),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColors.secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildRadioOption(
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isSelected ? AppColors.primaryColor : Colors.black87,
        ),
      ),
      leading: Radio<bool>(
        value: isSelected,
        groupValue: true,
        activeColor: AppColors.primaryColor,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
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
      collapsedBackgroundColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: const Color.fromARGB(255, 202, 201, 201), width: 0.5), // Expanded border
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: const Color.fromARGB(255, 202, 201, 201), width: 0.5), // Collapsed border
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
