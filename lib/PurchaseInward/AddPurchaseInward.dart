import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/style.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AddPurchaseInwardItem extends StatefulWidget {
  final String? supplierKey;

  const AddPurchaseInwardItem({Key? key, this.supplierKey}) : super(key: key);

  @override
  _AddPurchaseInwardItemState createState() => _AddPurchaseInwardItemState();
}

class _AddPurchaseInwardItemState extends State<AddPurchaseInwardItem> {
  Set<Category> _selectedCategories = {};
  Set<Item> _selectedItems = {};
  List<Style> _selectedStyles = [];

  List<Category> _categories = [];
  List<Item> _items = [];
  List<Item> _allItems = [];
  List<Style> _styles = [];

  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;
  bool _isLoadingStyles = false;
  String? _categoryError;
  String? _itemsError;
  String? _stylesError;

  bool _isStylesExpanded = true;
  bool _isCheckboxModeStyle = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAllItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    try {
      final categories = await ApiService.fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = 'Failed to load categories';
      });
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  Future<void> _fetchAllItems() async {
    setState(() {
      _isLoadingItems = true;
      _itemsError = null;
    });
    try {
      final allItems = await ApiService.fetchAllItems();
      setState(() {
        _allItems = allItems;
        _items = allItems;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
        _itemsError = 'Failed to load items';
      });
      _showErrorSnackBar('Failed to load items: $e');
    }
  }

  Future<void> _fetchStyles() async {
    if (_selectedCategories.isEmpty && _selectedItems.isEmpty) {
      setState(() {
        _styles = [];
        _selectedStyles = [];
      });
      return;
    }

    setState(() {
      _isLoadingStyles = true;
      _stylesError = null;
    });

    try {
      List<Style> fetchedStyles = [];

      // IMPORTANT: If products are selected, ONLY get styles for those products
      // Don't get styles from categories when products are selected
      if (_selectedItems.isNotEmpty) {
        // Get styles for each selected product individually
        for (var item in _selectedItems) {
          final styles = await ApiService.fetchStylesByItemKey(item.itemKey);
          fetchedStyles.addAll(styles);
        }
      }
      // Only get styles from categories if NO products are selected
      else if (_selectedCategories.isNotEmpty) {
        final categoryKeys = _selectedCategories
            .map((cat) => cat.itemSubGrpKey)
            .join(',');
        fetchedStyles.addAll(
          await ApiService.fetchStylesByItemGrpKey(categoryKeys),
        );
      }

      // Remove duplicates based on styleKey
      final uniqueStyles = <String, Style>{};
      for (var style in fetchedStyles) {
        uniqueStyles[style.styleKey] = style;
      }

      setState(() {
        _styles = uniqueStyles.values.toList();
        _selectedStyles = List.from(_styles); // Auto select all styles
        _isLoadingStyles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStyles = false;
        _stylesError = 'Failed to load styles';
      });
      _showErrorSnackBar('Failed to load styles: $e');
    }
  }

  void _filterItems() {
    setState(() {
      if (_selectedCategories.isEmpty) {
        _items = _allItems;
      } else {
        _items =
            _allItems
                .where(
                  (item) => _selectedCategories.any(
                    (cat) => cat.itemSubGrpKey == item.itemSubGrpKey,
                  ),
                )
                .toList();
      }
    });
  }

  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }
    return _items.where((item) {
      return item.itemName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _onCategorySelected(Category category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        _selectedItems.removeWhere(
          (item) => item.itemSubGrpKey == category.itemSubGrpKey,
        );
      } else {
        _selectedCategories.add(category);
      }
      _filterItems();
    });
    _fetchStyles();
  }

  void _onItemSelected(Item item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);

        bool hasOtherItemsInCategory = _selectedItems.any((selectedItem) {
          return selectedItem.itemSubGrpKey == item.itemSubGrpKey;
        });

        if (!hasOtherItemsInCategory && item.itemSubGrpKey != null) {
          final category = _categories.firstWhere(
            (c) => c.itemSubGrpKey == item.itemSubGrpKey,
            orElse: () => Category(itemSubGrpKey: '', itemSubGrpName: ''),
          );
          _selectedCategories.remove(category);
        }
      } else {
        _selectedItems.add(item);

        if (item.itemSubGrpKey != null) {
          final category = _categories.firstWhere(
            (c) => c.itemSubGrpKey == item.itemSubGrpKey,
            orElse: () => Category(itemSubGrpKey: '', itemSubGrpName: ''),
          );
          if (category.itemSubGrpKey.isNotEmpty) {
            _selectedCategories.add(category);
          }
        }
      }
      _filterItems();
    });
    _fetchStyles();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _addItems() {
    if (_selectedCategories.isEmpty && _selectedItems.isEmpty) {
      _showErrorSnackBar('Please select at least one category or item');
      return;
    }

    if (_selectedStyles.isEmpty) {
      _showErrorSnackBar('Please select at least one style');
      return;
    }

    List<Map<String, dynamic>> itemsData = [];

    for (var item in _selectedItems) {
      final category = _categories.firstWhere(
        (c) => c.itemSubGrpKey == item.itemSubGrpKey,
        orElse: () => Category(itemSubGrpKey: '', itemSubGrpName: ''),
      );

      itemsData.add({
        'categoryKey': category.itemSubGrpKey,
        'categoryName': category.itemSubGrpName,
        'itemKey': item.itemKey,
        'itemName': item.itemName,
        // Pass styleKey from the selected style objects, not styleCode
        'styles': _selectedStyles.map((s) => s.styleKey).toList(),
      });
    }

    Navigator.pop(context, itemsData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add Purchase Inward Item',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categories Header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Categories",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Categories Chips
                    _isLoadingCategories
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: LoadingAnimationWidget.waveDots(
                              color: AppColors.primaryColor,
                              size: 30,
                            ),
                          ),
                        )
                        : _categoryError != null
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _categoryError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _fetchCategories,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                        : _categories.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No categories found',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            alignment: WrapAlignment.start,
                            children:
                                _categories.map((category) {
                                  bool isSelected = _selectedCategories
                                      .contains(category);
                                  return _buildCategoryChip(
                                    category,
                                    isSelected,
                                  );
                                }).toList(),
                          ),
                        ),

                    const SizedBox(height: 24),

                    // Items Header
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Products",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 18,
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Items Section
                    _isLoadingItems
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: LoadingAnimationWidget.waveDots(
                              color: AppColors.primaryColor,
                              size: 30,
                            ),
                          ),
                        )
                        : _itemsError != null
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _itemsError!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _fetchAllItems,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                        : _filteredItems.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.inbox
                                      : Icons.search_off,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No products found'
                                      : 'No matching products',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  TextButton(
                                    onPressed: () => _searchController.clear(),
                                    child: Text(
                                      'Clear search',
                                      style: TextStyle(
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            alignment: WrapAlignment.start,
                            children:
                                _filteredItems.map((item) {
                                  bool isSelected = _selectedItems.contains(
                                    item,
                                  );
                                  return _buildItemChip(item, isSelected);
                                }).toList(),
                          ),
                        ),

                    const SizedBox(height: 24),

                    // Styles Section (shown below products)
                    if (_styles.isNotEmpty || _isLoadingStyles)
                      _buildStylesSection(),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStylesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _selectedStyles.isNotEmpty
                  ? AppColors.primaryColor
                  : Colors.grey.shade200,
          width: _selectedStyles.isNotEmpty ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
          title: Row(
            children: [
              Text(
                "Select Styles",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (_selectedStyles.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedStyles.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          initiallyExpanded: _isStylesExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isStylesExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          childrenPadding: const EdgeInsets.only(
            bottom: 16,
            left: 16,
            right: 16,
          ),
          trailing: Icon(
            _isStylesExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 20,
            color: AppColors.primaryColor,
          ),
          children: [
            if (_isLoadingStyles)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_stylesError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        _stylesError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else if (_styles.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No styles available for selected items'),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildModeSelector(
                        isCheckboxMode: _isCheckboxModeStyle,
                        onChanged: (isCheckbox) {
                          setState(() {
                            _isCheckboxModeStyle = isCheckbox;
                          });
                        },
                      ),
                      _buildSelectAllButton(
                        selectedCount: _selectedStyles.length,
                        totalCount: _styles.length,
                        onPressed: () {
                          setState(() {
                            if (_selectedStyles.length == _styles.length) {
                              _selectedStyles.clear();
                            } else {
                              _selectedStyles = List.from(_styles);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isCheckboxModeStyle
                      ? _buildCheckboxSection()
                      : _buildDropdownSection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxSection() {
    List<Widget> rows = [];
    for (int i = 0; i < _styles.length; i += 3) {
      List<Style> rowItems = _styles.sublist(
        i,
        i + 3 > _styles.length ? _styles.length : i + 3,
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children:
                rowItems.map((style) {
                  bool isSelected = _selectedStyles.any(
                    (s) => s.styleKey == style.styleKey,
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
                                  if (!_selectedStyles.any(
                                    (s) => s.styleKey == style.styleKey,
                                  )) {
                                    _selectedStyles.add(style);
                                  }
                                } else {
                                  _selectedStyles.removeWhere(
                                    (s) => s.styleKey == style.styleKey,
                                  );
                                }
                              });
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            style.styleCode,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _buildDropdownSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DropdownSearch<Style>.multiSelection(
        items: _styles,
        selectedItems: _selectedStyles,
        onChanged: (items) {
          setState(() {
            _selectedStyles = items ?? [];
          });
        },
        itemAsString: (s) => s.styleCode,
        compareFn: (a, b) => a.styleKey == b.styleKey,
        popupProps: PopupPropsMultiSelection.menu(
          showSearchBox: true,
          searchDelay: const Duration(milliseconds: 300),
          menuProps: const MenuProps(
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: 'Search styles...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            hintText: 'Select styles',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector({
    required bool isCheckboxMode,
    required void Function(bool) onChanged,
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
            onTap: () => onChanged(true),
          ),
          _buildModeButton(
            icon: Icons.list,
            label: 'Combo',
            isSelected: !isCheckboxMode,
            onTap: () => onChanged(false),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.primaryColor,
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        selectedCount == totalCount ? 'Deselect All' : 'Select All',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selectedCount == totalCount ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel, size: 20, color: Colors.white),
                  label: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addItems,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Add",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Category category, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColors.primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                category.itemSubGrpName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemChip(Item item, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemSelected(item),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? AppColors.primaryColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                item.itemName,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
