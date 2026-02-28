import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CatalogScreen extends StatefulWidget {
  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  final List<String> garmentImages = [
    'assets/images/cloths/img3.jpg',
    'assets/images/cloths/img3.jpg',
    'assets/images/cloths/img3.jpg',
    'assets/images/cloths/img3.jpg',
    'assets/images/cloths/img3.jpg',
  ];

  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  String? _selectedCategoryKey = '-1';
  String? _selectedCategoryName = 'All';
  String? coBr = UserSession.coBrId ?? '';
  String? fcYrId = UserSession.userFcYr ?? '';

  List<Category> _categories = [];
  List<Item> _items = [];
  List<Item> _allItems = [];

  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;
  String? _categoryError;
  String? _itemsError;

  // MULTI SELECT VARIABLES
  bool _isMultiSelectMode = false;
  Set<String> _selectedCategoryKeys = {};
  Set<String> _selectedItemKeys = {};

  late AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchAllItems();

    _arrowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        _isLoadingCategories = true;
        _categoryError = null;
      });
      final categories = await ApiService.fetchCategories();
      setState(() {
        _categories = [
          ...categories,
        ];
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = 'Failed to load categories: $e';
      });
      print('Error fetching categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  Future<void> _fetchAllItems() async {
    try {
      setState(() {
        _isLoadingItems = true;
        _itemsError = null;
      });
      final items = await ApiService.fetchAllItems();
      setState(() {
        _items = items;
        _allItems = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
        _itemsError = 'Failed to load items: $e';
      });
      print('Error fetching items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')));
    }
  }

  void _filterItems() {
    if (_selectedCategoryKeys.isEmpty) {
      _items = _allItems;
    } else {
      _items = _allItems
          .where((item) => _selectedCategoryKeys.contains(item.itemSubGrpKey))
          .toList();
    }
  }

  void _exitMultiSelectMode() {
    if (_selectedCategoryKeys.isEmpty && _selectedItemKeys.isEmpty) {
      setState(() {
        _isMultiSelectMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Catalog', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      
      // FLOATING ACTION BUTTON - ONLY APPEARS WHEN ITEMS SELECTED
      floatingActionButton: (_selectedCategoryKeys.isNotEmpty ||
              _selectedItemKeys.isNotEmpty)
          ? ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.1).animate(_arrowController),
              child: FloatingActionButton(
                backgroundColor: AppColors.primaryColor,
                child: Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () {
                  String? categoryKeys;
                  String? itemKeys;

                  if (_selectedCategoryKeys.isNotEmpty) {
                    categoryKeys = _selectedCategoryKeys.join(',');
                  }

                  if (_selectedItemKeys.isNotEmpty) {
                    itemKeys = _selectedItemKeys.join(',');
                  }

                  Navigator.pushNamed(
                    context,
                    '/catalogpage',
                    arguments: {
                      'itemKey': itemKeys,
                      'itemSubGrpKey': categoryKeys,
                      'itemName': null,
                      'coBr': coBr,
                      'fcYrId': fcYrId,
                    },
                  ).then((_) {
                    // Clear selection after returning
                    setState(() {
                      _selectedCategoryKeys.clear();
                      _selectedItemKeys.clear();
                      _isMultiSelectMode = false;
                      _filterItems();
                    });
                  });
                },
              ),
            )
          : null,

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      
                      Text(
                        "Categories",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      
                      // Categories Section
                      _isLoadingCategories
                          ? Center(
                              child: LoadingAnimationWidget.waveDots(
                                color: AppColors.primaryColor,
                                size: 30,
                              ),
                            )
                          : _categoryError != null
                              ? Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        _categoryError!,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: _fetchCategories,
                                        child: Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : Wrap(
                                  spacing: 16,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.start,
                                  children: _categories.map((category) {
                                    bool isSelected = _selectedCategoryKeys
                                        .contains(category.itemSubGrpKey);
                                        
                                    return SizedBox(
                                      width: (MediaQuery.of(context).size.width -
                                              48) /
                                          2,
                                      child: OutlinedButton(
                                        // TAP BEHAVIOR - Changes based on mode
                                        onPressed: () {
                                          if (_isMultiSelectMode) {
                                            // In multi-select mode: toggle selection
                                            setState(() {
                                              if (isSelected) {
                                                _selectedCategoryKeys.remove(
                                                    category.itemSubGrpKey);
                                              } else {
                                                _selectedCategoryKeys
                                                    .add(category.itemSubGrpKey);
                                              }
                                              _filterItems();
                                              _exitMultiSelectMode();
                                            });
                                          } else {
                                            // Normal mode: navigate
                                            Navigator.pushNamed(
                                              context,
                                              '/catalogpage',
                                              arguments: {
                                                'itemKey': null,
                                                'itemSubGrpKey':
                                                    category.itemSubGrpKey,
                                                'itemName':
                                                    category.itemSubGrpName.trim(),
                                                'coBr': coBr,
                                                'fcYrId': fcYrId,
                                              },
                                            );
                                          }
                                        },
                                        // LONG PRESS - Always enables multi-select and toggles selection
                                        onLongPress: () {
                                          setState(() {
                                            _isMultiSelectMode = true;
                                            if (isSelected) {
                                              _selectedCategoryKeys.remove(
                                                  category.itemSubGrpKey);
                                            } else {
                                              _selectedCategoryKeys
                                                  .add(category.itemSubGrpKey);
                                            }
                                            _filterItems();
                                          });
                                        },
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                            isSelected
                                                ? AppColors.primaryColor
                                                : Colors.white,
                                          ),
                                          side: MaterialStateProperty.all(
                                            BorderSide(
                                              color: AppColors.primaryColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          shape: MaterialStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          category.itemSubGrpName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                      SizedBox(height: 20),
                      
                      // Items Section
                      _buildCategoryItems(),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen: '/catalog'),
    );
  }

  Widget _buildCategoryItems() {
    double buttonWidth = (MediaQuery.of(context).size.width - 48) / 2;
    double buttonHeight = 43;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Items",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 10),
        _isLoadingItems
            ? Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primaryColor,
                  size: 30,
                ),
              )
            : _itemsError != null
                ? Center(
                    child: Column(
                      children: [
                        Text(_itemsError!,
                            style: TextStyle(color: Colors.red)),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchAllItems,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        alignment: WrapAlignment.start,
                        children: _items.map((item) {
                          bool isSelected =
                              _selectedItemKeys.contains(item.itemKey);
                              
                          return SizedBox(
                            width: buttonWidth,
                            height: buttonHeight,
                            child: OutlinedButton(
                              // TAP BEHAVIOR - Changes based on mode
                              onPressed: () {
                                if (_isMultiSelectMode) {
                                  // In multi-select mode: toggle selection
                                  setState(() {
                                    if (isSelected) {
                                      _selectedItemKeys.remove(item.itemKey);
                                    } else {
                                      _selectedItemKeys.add(item.itemKey);
                                    }
                                    _exitMultiSelectMode();
                                  });
                                } else {
                                  // Normal mode: navigate
                                  Navigator.pushNamed(
                                    context,
                                    '/catalogpage',
                                    arguments: {
                                      'itemKey': item.itemKey,
                                      'itemSubGrpKey': item.itemSubGrpKey,
                                      'itemName': item.itemName.trim(),
                                      'coBr': coBr,
                                      'fcYrId': fcYrId,
                                    },
                                  );
                                }
                              },
                              // LONG PRESS - Always enables multi-select and toggles selection
                              onLongPress: () {
                                setState(() {
                                  _isMultiSelectMode = true;
                                  if (isSelected) {
                                    _selectedItemKeys.remove(item.itemKey);
                                  } else {
                                    _selectedItemKeys.add(item.itemKey);
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1),
                                backgroundColor: isSelected
                                    ? AppColors.primaryColor
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  item.itemName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
      ],
    );
  }
}