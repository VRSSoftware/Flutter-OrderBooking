// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/models/category.dart';
// import 'package:vrs_erp/models/item.dart';
// import 'package:vrs_erp/screens/drawer_screen.dart';
// import 'package:vrs_erp/services/app_services.dart';
// import 'package:vrs_erp/widget/bottom_navbar.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';

// class CatalogScreen extends StatefulWidget {
//   @override
//   _CatalogScreenState createState() => _CatalogScreenState();
// }

// class _CatalogScreenState extends State<CatalogScreen>
//     with SingleTickerProviderStateMixin {
//   final List<String> garmentImages = [
//     'assets/images/cloths/img3.jpg',
//     'assets/images/cloths/img3.jpg',
//     'assets/images/cloths/img3.jpg',
//     'assets/images/cloths/img3.jpg',
//     'assets/images/cloths/img3.jpg',
//   ];

//   int _currentIndex = 0;
//   final CarouselSliderController _carouselController =
//       CarouselSliderController();

//   String? _selectedCategoryKey = '-1';
//   String? _selectedCategoryName = 'All';
//   String? coBr = UserSession.coBrId ?? '';
//   String? fcYrId = UserSession.userFcYr ?? '';

//   List<Category> _categories = [];
//   List<Item> _items = [];
//   List<Item> _allItems = [];

//   bool _isLoadingCategories = true;
//   bool _isLoadingItems = false;
//   String? _categoryError;
//   String? _itemsError;

//   // MULTI SELECT VARIABLES
//   bool _isMultiSelectMode = false;
//   Set<String> _selectedCategoryKeys = {};
//   Set<String> _selectedItemKeys = {};

//   late AnimationController _arrowController;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCategories();
//     _fetchAllItems();

//     _arrowController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 700),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _arrowController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchCategories() async {
//     try {
//       setState(() {
//         _isLoadingCategories = true;
//         _categoryError = null;
//       });
//       final categories = await ApiService.fetchCategories();
//       setState(() {
//         _categories = [...categories];
//         _isLoadingCategories = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoadingCategories = false;
//         _categoryError = 'Failed to load categories: $e';
//       });
//       print('Error fetching categories: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
//     }
//   }

//   Future<void> _fetchAllItems() async {
//     try {
//       setState(() {
//         _isLoadingItems = true;
//         _itemsError = null;
//       });
//       final items = await ApiService.fetchAllItems();
//       setState(() {
//         _items = items;
//         _allItems = items;
//         _isLoadingItems = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoadingItems = false;
//         _itemsError = 'Failed to load items: $e';
//       });
//       print('Error fetching items: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
//     }
//   }

//   void _filterItems() {
//     if (_selectedCategoryKeys.isEmpty) {
//       _items = _allItems;
//     } else {
//       _items =
//           _allItems
//               .where(
//                 (item) => _selectedCategoryKeys.contains(item.itemSubGrpKey),
//               )
//               .toList();
//     }
//   }

//   void _exitMultiSelectMode() {
//     if (_selectedCategoryKeys.isEmpty && _selectedItemKeys.isEmpty) {
//       setState(() {
//         _isMultiSelectMode = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       drawer: DrawerScreen(),
//       appBar: AppBar(
//         title: Text('Catalog', style: TextStyle(color: AppColors.white)),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 1,
//         leading: Builder(
//           builder:
//               (context) => IconButton(
//                 icon: Icon(Icons.menu, color: AppColors.white),
//                 onPressed: () => Scaffold.of(context).openDrawer(),
//               ),
//         ),
//       ),

//       // FLOATING ACTION BUTTON - ONLY APPEARS WHEN ITEMS SELECTED
//       floatingActionButton:
//           (_selectedCategoryKeys.isNotEmpty || _selectedItemKeys.isNotEmpty)
//               ? ScaleTransition(
//                 scale: Tween(begin: 0.9, end: 1.1).animate(_arrowController),
//                 child: FloatingActionButton(
//                   backgroundColor: AppColors.primaryColor,
//                   child: Icon(Icons.arrow_forward, color: Colors.white),
//                   onPressed: () {
//                     String? categoryKeys;
//                     String? itemKeys;

//                     if (_selectedCategoryKeys.isNotEmpty) {
//                       categoryKeys = _selectedCategoryKeys.join(',');
//                     }

//                     if (_selectedItemKeys.isNotEmpty) {
//                       itemKeys = _selectedItemKeys.join(',');
//                     }

//                     Navigator.pushNamed(
//                       context,
//                       '/catalogpage',
//                       arguments: {
//                         'itemKey': itemKeys,
//                         'itemSubGrpKey': categoryKeys,
//                         'itemName': null,
//                         'coBr': coBr,
//                         'fcYrId': fcYrId,
//                       },
//                     ).then((_) {
//                       // Clear selection after returning
//                       setState(() {
//                         _selectedCategoryKeys.clear();
//                         _selectedItemKeys.clear();
//                         _isMultiSelectMode = false;
//                         _filterItems();
//                       });
//                     });
//                   },
//                 ),
//               )
//               : null,

//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: 5),

//                       Text(
//                         "Categories",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       SizedBox(height: 10),

//                       // Categories Section
//                       _isLoadingCategories
//                           ? Center(
//                             child: LoadingAnimationWidget.waveDots(
//                               color: AppColors.primaryColor,
//                               size: 30,
//                             ),
//                           )
//                           : _categoryError != null
//                           ? Center(
//                             child: Column(
//                               children: [
//                                 Text(
//                                   _categoryError!,
//                                   style: TextStyle(color: Colors.red),
//                                 ),
//                                 SizedBox(height: 10),
//                                 ElevatedButton(
//                                   onPressed: _fetchCategories,
//                                   child: Text('Retry'),
//                                 ),
//                               ],
//                             ),
//                           )
//                           : Wrap(
//                             spacing: 16,
//                             runSpacing: 10,
//                             alignment: WrapAlignment.start,
//                             children:
//                                 _categories.map((category) {
//                                   bool isSelected = _selectedCategoryKeys
//                                       .contains(category.itemSubGrpKey);

//                                   return SizedBox(
//                                     width:
//                                         (MediaQuery.of(context).size.width -
//                                             48) /
//                                         2,
//                                     child: OutlinedButton(
//                                       // TAP BEHAVIOR - Changes based on mode
//                                       onPressed: () {
//                                         setState(() {
//                                           _isMultiSelectMode = true;

//                                           if (isSelected) {
//                                             _selectedCategoryKeys.remove(
//                                               category.itemSubGrpKey,
//                                             );

//                                             // remove items of this category
//                                             _selectedItemKeys.removeWhere((
//                                               itemKey,
//                                             ) {
//                                               final selectedItem = _allItems
//                                                   .firstWhere(
//                                                     (i) => i.itemKey == itemKey,
//                                                   );
//                                               return selectedItem
//                                                       .itemSubGrpKey ==
//                                                   category.itemSubGrpKey;
//                                             });
//                                           } else {
//                                             _selectedCategoryKeys.add(
//                                               category.itemSubGrpKey,
//                                             );
//                                           }

//                                           _filterItems();
//                                           _exitMultiSelectMode();
//                                         });
//                                       }, // LONG PRESS - Always enables multi-select and toggles selection
//                                       // onLongPress: () {
//                                       //   setState(() {
//                                       //     _isMultiSelectMode = true;
//                                       //     if (isSelected) {
//                                       //       _selectedCategoryKeys.remove(
//                                       //           category.itemSubGrpKey);
//                                       //     } else {
//                                       //       _selectedCategoryKeys
//                                       //           .add(category.itemSubGrpKey);
//                                       //     }
//                                       //     _filterItems();
//                                       //   });
//                                       // },
//                                       style: ButtonStyle(
//                                         backgroundColor:
//                                             MaterialStateProperty.all(
//                                               isSelected
//                                                   ? AppColors.primaryColor
//                                                   : Colors.white,
//                                             ),
//                                         side: MaterialStateProperty.all(
//                                           BorderSide(
//                                             color: AppColors.primaryColor,
//                                             width: isSelected ? 2 : 1,
//                                           ),
//                                         ),
//                                         shape: MaterialStateProperty.all(
//                                           RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       child: Text(
//                                         category.itemSubGrpName,
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color:
//                                               isSelected
//                                                   ? Colors.white
//                                                   : AppColors.primaryColor,
//                                         ),
//                                       ),
//                                     ),
//                                   );
//                                 }).toList(),
//                           ),
//                       SizedBox(height: 20),

//                       // Items Section
//                       _buildCategoryItems(),
//                       Spacer(),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationWidget(currentScreen: '/catalog'),
//     );
//   }

//   Widget _buildCategoryItems() {
//     double buttonWidth = (MediaQuery.of(context).size.width - 48) / 2;
//     double buttonHeight = 43;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Items",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         SizedBox(height: 10),
//         _isLoadingItems
//             ? Center(
//               child: LoadingAnimationWidget.waveDots(
//                 color: AppColors.primaryColor,
//                 size: 30,
//               ),
//             )
//             : _itemsError != null
//             ? Center(
//               child: Column(
//                 children: [
//                   Text(_itemsError!, style: TextStyle(color: Colors.red)),
//                   SizedBox(height: 10),
//                   ElevatedButton(
//                     onPressed: _fetchAllItems,
//                     child: Text('Retry'),
//                   ),
//                 ],
//               ),
//             )
//             : _items.isEmpty
//             ? Center(
//               child: Text(
//                 'No items found',
//                 style: TextStyle(color: Colors.grey),
//               ),
//             )
//             : Wrap(
//               spacing: 16,
//               runSpacing: 10,
//               alignment: WrapAlignment.start,
//               children:
//                   _items.map((item) {
//                     bool isSelected = _selectedItemKeys.contains(item.itemKey);

//                     return SizedBox(
//                       width: buttonWidth,
//                       height: buttonHeight,
//                       child: OutlinedButton(
//                         // TAP BEHAVIOR - Changes based on mode
//                         onPressed: () {
//                           setState(() {
//                             _isMultiSelectMode = true;

//                             if (isSelected) {
//                               _selectedItemKeys.remove(item.itemKey);

//                               // check if category still has selected items
//                               bool hasOtherItems = _selectedItemKeys.any((key) {
//                                 final selectedItem = _allItems.firstWhere(
//                                   (i) => i.itemKey == key,
//                                 );
//                                 return selectedItem.itemSubGrpKey ==
//                                     item.itemSubGrpKey;
//                               });

//                               if (!hasOtherItems) {
//                                 _selectedCategoryKeys.remove(
//                                   item.itemSubGrpKey,
//                                 );
//                               }
//                             } else {
//                               _selectedItemKeys.add(item.itemKey);

//                               if (item.itemSubGrpKey != null) {
//                                 _selectedCategoryKeys.add(item.itemSubGrpKey!);
//                               }
//                             }

//                             _exitMultiSelectMode();
//                           });
//                         }, // LONG PRESS - Always enables multi-select and toggles selection
//                         // onLongPress: () {
//                         //   setState(() {
//                         //     _isMultiSelectMode = true;
//                         //     if (isSelected) {
//                         //       _selectedItemKeys.remove(item.itemKey);
//                         //     } else {
//                         //       _selectedItemKeys.add(item.itemKey);
//                         //     }
//                         //   });
//                         // },
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(
//                             color:
//                                 isSelected
//                                     ? AppColors.primaryColor
//                                     : Colors.grey.shade300,
//                             width: isSelected ? 2 : 1,
//                           ),
//                           backgroundColor:
//                               isSelected
//                                   ? AppColors.primaryColor
//                                   : Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: SingleChildScrollView(
//                           scrollDirection: Axis.horizontal,
//                           child: Text(
//                             item.itemName,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: isSelected ? Colors.white : Colors.black87,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//             ),
//       ],
//     );
//   }
// }

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
        _categories = [...categories];
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        _categoryError = 'Failed to load categories: $e';
      });
      print('Error fetching categories: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
    }
  }

  void _filterItems() {
    if (_selectedCategoryKeys.isEmpty) {
      _items = _allItems;
    } else {
      _items =
          _allItems
              .where(
                (item) => _selectedCategoryKeys.contains(item.itemSubGrpKey),
              )
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
      backgroundColor: Colors.grey[50], // Changed to grey background
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text('Catalog', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0, // Changed to 0 for flat design
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: AppColors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),

      // FLOATING ACTION BUTTON - ONLY APPEARS WHEN ITEMS SELECTED
      floatingActionButton:
          (_selectedCategoryKeys.isNotEmpty || _selectedItemKeys.isNotEmpty)
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
            // Calculate button width for 2 columns
            double buttonWidth = (constraints.maxWidth - 24) / 2; // 16px padding + 8px gap
            
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),

                      // Categories Title with Vertical Line
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
                          Text(
                            "Categories",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      // Categories Section
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
                                  Icon(Icons.error_outline, color: Colors.red, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    _categoryError!,
                                    style: TextStyle(color: Colors.red, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _fetchCategories,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            alignment: WrapAlignment.start,
                            children:
                                _categories.map((category) {
                                  bool isSelected = _selectedCategoryKeys
                                      .contains(category.itemSubGrpKey);

                                  return _buildCategoryChip(
                                    category,
                                    isSelected,
                                    buttonWidth,
                                  );
                                }).toList(),
                          ),
                      SizedBox(height: 20),

                      // Items Title with Vertical Line
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
                          Text(
                            "Items",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      // Items Section
                      _buildCategoryItems(buttonWidth),
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

  Widget _buildCategoryChip(Category category, bool isSelected, double buttonWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMultiSelectMode = true;

          if (isSelected) {
            _selectedCategoryKeys.remove(category.itemSubGrpKey);

            // remove items of this category
            _selectedItemKeys.removeWhere((itemKey) {
              final selectedItem = _allItems.firstWhere(
                (i) => i.itemKey == itemKey,
              );
              return selectedItem.itemSubGrpKey == category.itemSubGrpKey;
            });
          } else {
            _selectedCategoryKeys.add(category.itemSubGrpKey);
          }

          _filterItems();
          _exitMultiSelectMode();
        });
      },
      // onLongPress: () {
      //   setState(() {
      //     _isMultiSelectMode = true;
      //     if (isSelected) {
      //       _selectedCategoryKeys.remove(category.itemSubGrpKey);
      //     } else {
      //       _selectedCategoryKeys.add(category.itemSubGrpKey);
      //     }
      //     _filterItems();
      //   });
      // },
      child: Container(
        width: buttonWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20), // Rounded chips
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
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
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                category.itemSubGrpName,
                textAlign: TextAlign.center,
                style: TextStyle(
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

  Widget _buildCategoryItems(double buttonWidth) {
    double buttonHeight = 43;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _itemsError!,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchAllItems,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
            : _items.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No items found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
            : Wrap(
              spacing: 8,
              runSpacing: 10,
              alignment: WrapAlignment.start,
              children:
                  _items.map((item) {
                    bool isSelected = _selectedItemKeys.contains(item.itemKey);

                    return _buildItemChip(
                      item,
                      isSelected,
                      buttonWidth,
                      buttonHeight,
                    );
                  }).toList(),
            ),
      ],
    );
  }

  Widget _buildItemChip(
    Item item,
    bool isSelected,
    double buttonWidth,
    double buttonHeight,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMultiSelectMode = true;

          if (isSelected) {
            _selectedItemKeys.remove(item.itemKey);

            // check if category still has selected items
            bool hasOtherItems = _selectedItemKeys.any((key) {
              final selectedItem = _allItems.firstWhere(
                (i) => i.itemKey == key,
              );
              return selectedItem.itemSubGrpKey == item.itemSubGrpKey;
            });

            if (!hasOtherItems) {
              _selectedCategoryKeys.remove(item.itemSubGrpKey);
            }
          } else {
            _selectedItemKeys.add(item.itemKey);

            if (item.itemSubGrpKey != null) {
              _selectedCategoryKeys.add(item.itemSubGrpKey!);
            }
          }

          _exitMultiSelectMode();
        });
      },
      // onLongPress: () {
      //   setState(() {
      //     _isMultiSelectMode = true;
      //     if (isSelected) {
      //       _selectedItemKeys.remove(item.itemKey);
      //     } else {
      //       _selectedItemKeys.add(item.itemKey);
      //       if (item.itemSubGrpKey != null) {
      //         _selectedCategoryKeys.add(item.itemSubGrpKey!);
      //       }
      //     }
      //   });
      // },
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20), // Rounded chips
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
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
              const SizedBox(width: 4),
            ],
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  item.itemName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}