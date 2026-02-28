import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:vrs_erp/OrderBooking/orderbooking_drawer.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/constants/constants.dart';
import 'package:vrs_erp/dashboard/orderStatus.dart';
import 'package:vrs_erp/models/CartModel.dart';
import 'package:vrs_erp/models/PartyWithSpclMarkDwn.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/register/register.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/OrderBooking/barcode/barcodewidget.dart';
import 'package:vrs_erp/widget/bottom_navbar.dart';
import 'package:vrs_erp/widget/filterdailogwidget.dart';

class OrderBookingScreen extends StatefulWidget {
  @override
  _OrderBookingScreenState createState() => _OrderBookingScreenState();
}

class _OrderBookingScreenState extends State<OrderBookingScreen>
    with SingleTickerProviderStateMixin {
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
  bool showBarcodeWidget = false;
  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;
  bool hasFiltered = false;
  List<PartyWithSpclMarkDwn> partyList = [];
  PartyWithSpclMarkDwn? selectedParty;
  // int _cartItemCount = 0;

  // ✅ MULTI SELECT VARIABLES (ADDED ONLY THESE)
  bool _isMultiSelectMode = false;
  Set<String> _selectedCategoryKeys = {};
  Set<String> _selectedItemKeys = {};

  late AnimationController _arrowController;

  Set<String> _activeFilters = {'mrp', 'wsp', 'shades', 'stylecode'};

  void _updateFilters(Set<String> newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    fetchAllItems();

    if (coBr != null && fcYrId != null) {
      _fetchCartCount();
    }
    fetchPartyList();

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

  fetchPartyList() async {
    final fetchedResponse = await ApiService.fetchPartyWithSpclMarkDwn(
      ledCat: 'w',
      coBrId: UserSession.coBrId ?? '',
    );

    setState(() {
      partyList = List<PartyWithSpclMarkDwn>.from(fetchedResponse['result'] ?? []);
    });
  }

  // Replace the existing _fetchCartCount method
  Future<void> _fetchCartCount() async {
    try {
      final data = await ApiService.getSalesOrderData(
        coBrId: UserSession.coBrId ?? '',
        userId: UserSession.userName ?? '',
        fcYrId: UserSession.userFcYr ?? '',
        barcode: showBarcodeWidget ? 'true' : 'false',
      );

      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.updateCount(data['cartItemCount'] ?? 0);
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final items = await ApiService.fetchAllItems();
      setState(() {
        _items = items;
        _allItems = items;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> fetchAllItems() async {
    try {
      final categories = await ApiService.fetchCategories();
      setState(() {
        _categories = [
          //  Category(itemSubGrpKey: '-1', itemSubGrpName: "ALL"),
          ...categories,
        ];
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
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
    final cartModel = Provider.of<CartModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Text(
          showBarcodeWidget ? 'Barcode' : 'Order Booking',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading:
            showBarcodeWidget
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        showBarcodeWidget = false;
                      });
                    },
                  )
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
        automaticallyImplyLeading: false,
        actions: [
          // Cart Icon for both modes (Order Booking and Barcode)
          IconButton(
            icon: Stack(
              children: [
                const Icon(CupertinoIcons.cart_badge_plus, color: Colors.white),
                if (cartModel.count >= 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${cartModel.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (showBarcodeWidget) {
                Navigator.pushNamed(
                  context,
                  '/viewOrderBarcode',
                  arguments: {Constants.barcode: showBarcodeWidget},
                ).then((_) => _fetchCartCount());
              } else {
                Navigator.pushNamed(
                  context,
                  '/viewOrder',
                  arguments: {Constants.barcode: showBarcodeWidget},
                ).then((_) => _fetchCartCount());
              }
            },
          ),

          // Orders icon
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
          ),
        ],
      ),

      // ✅ FLOATING ACTION BUTTON - ONLY APPEARS WHEN ITEMS SELECTED
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
                    '/orderpage',
                    arguments: {
                      'itemKey': itemKeys,
                      'itemSubGrpKey': categoryKeys,
                      'itemName': null,
                      'coBr': coBr,
                      'fcYrId': fcYrId,
                      'selectedParty': selectedParty,
                      'type': Constants.SALE_BILL,
                      'isMultiSelect': true,
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
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced padding
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Button width: total width minus 16 (padding) minus 8 (gap), divided by 2, increased by 20%
            double buttonWidth = ((constraints.maxWidth - 16 - 8) / 2) * 1;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: DropdownSearch<PartyWithSpclMarkDwn>(
                      //         items: partyList,
                      //         selectedItem: selectedParty,
                      //         itemAsString: (PartyWithSpclMarkDwn? u) => u?.ledName ?? '',
                      //         onChanged:
                      //             (value) =>
                      //                 setState(() => selectedParty = value),
                      //         popupProps: PopupProps.menu(
                      //           showSearchBox: true,
                      //           containerBuilder:
                      //               (context, popupWidget) => Container(
                      //                 decoration: BoxDecoration(
                      //                   color: Colors.white,
                      //                   borderRadius: BorderRadius.circular(8),
                      //                   boxShadow: [
                      //                     BoxShadow(
                      //                       color: Colors.grey.withOpacity(0.5),
                      //                       spreadRadius: 2,
                      //                       blurRadius: 5,
                      //                       offset: Offset(0, 3),
                      //                     ),
                      //                   ],
                      //                 ),
                      //                 child: popupWidget,
                      //               ),
                      //         ),
                      //         // dropdownDecoratorProps: DropDownDecoratorProps(
                      //         //   dropdownSearchDecoration: InputDecoration(
                      //         //     labelText: 'Select Party',
                      //         //     filled: true,
                      //         //     fillColor: Colors.white,
                      //         //     border: OutlineInputBorder(
                      //         //       borderRadius: BorderRadius.circular(8),
                      //         //     ),
                      //         //   ),
                      //         // ),
                      //       // ),
                      //     ),
                      //   ],
                      // ),

                      // Row(
                      //   children: [
                      // DropdownSearch<KeyName>(
                      //   items: ledgerList,
                      //   selectedItem: selectedLedger,
                      //   itemAsString: (KeyName? u) => u?.name ?? '',
                      //   onChanged:
                      //       (value) =>
                      //           setState(() => selectedLedger = value),
                      //   popupProps: PopupProps.menu(
                      //     showSearchBox: true,
                      //     containerBuilder:
                      //         (context, popupWidget) => Container(
                      //           decoration: BoxDecoration(
                      //             color: Colors.white, // Menu background
                      //             borderRadius: BorderRadius.circular(8),
                      //             boxShadow: [
                      //               BoxShadow(
                      //                 color: Colors.grey.withOpacity(0.5),
                      //                 spreadRadius: 2,
                      //                 blurRadius: 5,
                      //                 offset: Offset(0, 3),
                      //               ),
                      //             ],
                      //           ),
                      //           child: popupWidget,
                      //         ),
                      //   ),
                      //   dropdownDecoratorProps: DropDownDecoratorProps(
                      //     dropdownSearchDecoration: InputDecoration(
                      //       labelText: 'Select Party',
                      //       filled: true,
                      //       fillColor: Colors.white,
                      //       border: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      //   ],
                      // ),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Checkbox(
                              value: showBarcodeWidget,
                              onChanged: (value) {
                                setState(() {
                                  showBarcodeWidget = value ?? false;
                                  _fetchCartCount();
                                });
                              },
                            ),
                            const Text(
                              "Order Booking Barcode Wise",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (showBarcodeWidget)
                        SizedBox(
                          width: double.infinity,
                          child: BarcodeWiseWidget(
                            onFilterPressed: (barcode) {
                              print("Barcode: $barcode");
                              setState(() {
                                hasFiltered = true;
                              });
                            },
                            // activeFilters: _activeFilters,
                          ),
                        ),
                      if (!showBarcodeWidget) ...[
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: const Text(
                            "Categories",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _isLoadingCategories
                            ? Center(
                                child: LoadingAnimationWidget.waveDots(
                                  color: AppColors.primaryColor,
                                  size: 30,
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Wrap(
                                  spacing: 8, // Reduced gap between buttons
                                  runSpacing: 10,
                                  alignment: WrapAlignment.start,
                                  children: _categories.map((category) {
                                    bool isSelected = _selectedCategoryKeys
                                        .contains(category.itemSubGrpKey);

                                    return SizedBox(
                                      width: buttonWidth, // Increased width
                                      child: OutlinedButton(
                                        // ✅ TAP BEHAVIOR - Changes based on mode
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
                                              '/orderpage',
                                              arguments: {
                                                'itemKey': null,
                                                'itemSubGrpKey':
                                                    category.itemSubGrpKey,
                                                'itemName':
                                                    category.itemSubGrpName
                                                        .trim(),
                                                'coBr': coBr,
                                                'fcYrId': fcYrId,
                                                'selectedParty': selectedParty,
                                                'type': Constants.SALE_BILL,
                                              },
                                            ).then((_) => _fetchCartCount());
                                          }
                                        },
                                        // ✅ LONG PRESS FOR MULTI-SELECT
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
                                              WidgetStateProperty.all(
                                                isSelected
                                                    ? AppColors.primaryColor
                                                    : Colors.white,
                                              ),
                                          side: WidgetStateProperty.all(
                                            BorderSide(
                                              color: AppColors.primaryColor,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          shape: WidgetStateProperty.all(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          category.itemSubGrpName,
                                          textAlign: TextAlign.center, // Center text
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primaryColor,
                                            fontSize: 14, // Consistent font size
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                        const SizedBox(height: 20),
                        if (_selectedCategoryKey != null)
                          _buildCategoryItems(buttonWidth),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(currentScreen: '/orderbooking'),
    );
  }

  Widget _buildCategoryItems(double buttonWidth) {
    double buttonHeight = 43;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "Items",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),
        _isLoadingItems
            ? Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primaryColor,
                  size: 30,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 8, // Reduced gap between buttons
                  runSpacing: 10,
                  alignment: WrapAlignment.start,
                  children: _items.map((item) {
                    bool isSelected = _selectedItemKeys.contains(item.itemKey);

                    return SizedBox(
                      width: buttonWidth, // Increased width
                      height: buttonHeight,
                      child: OutlinedButton(
                        // ✅ TAP BEHAVIOR - Changes based on mode
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
                              '/orderpage',
                              arguments: {
                                'itemKey': item.itemKey,
                                'itemName': item.itemName.trim(),
                                'itemSubGrpKey': item.itemSubGrpKey,
                                'coBr': coBr,
                                'fcYrId': fcYrId,
                                'selectedParty': selectedParty,
                                'type': Constants.SALE_BILL,
                              },
                            ).then((_) => _fetchCartCount());
                          }
                        },
                        // ✅ LONG PRESS FOR MULTI-SELECT
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
                        child: Text(
                          item.itemName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}