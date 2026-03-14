// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:provider/provider.dart';

// import 'package:vrs_erp/OrderBooking/orderbooking_drawer.dart';
// import 'package:vrs_erp/constants/app_constants.dart';
// import 'package:vrs_erp/constants/constants.dart';
// import 'package:vrs_erp/dashboard/orderStatus.dart';
// import 'package:vrs_erp/models/CartModel.dart';
// import 'package:vrs_erp/models/PartyWithSpclMarkDwn.dart';
// import 'package:vrs_erp/models/category.dart';
// import 'package:vrs_erp/models/item.dart';
// import 'package:vrs_erp/models/keyName.dart';
// import 'package:vrs_erp/register/register.dart';
// import 'package:vrs_erp/screens/drawer_screen.dart';
// import 'package:vrs_erp/services/app_services.dart';
// import 'package:vrs_erp/OrderBooking/barcode/barcodewidget.dart';
// import 'package:vrs_erp/widget/bottom_navbar.dart';
// import 'package:vrs_erp/widget/filterdailogwidget.dart';

// class OrderBookingScreen extends StatefulWidget {
//   final bool startWithBarcode;

//   const OrderBookingScreen({Key? key, this.startWithBarcode = false})
//     : super(key: key);

//   @override
//   _OrderBookingScreenState createState() => _OrderBookingScreenState();
// }

// class _OrderBookingScreenState extends State<OrderBookingScreen>
//     with SingleTickerProviderStateMixin {
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
//   bool showBarcodeWidget = false;
//   bool _isLoadingCategories = true;
//   bool _isLoadingItems = false;
//   bool hasFiltered = false;
//   List<PartyWithSpclMarkDwn> partyList = [];
//   PartyWithSpclMarkDwn? selectedParty;
//   // int _cartItemCount = 0;

//   // ✅ MULTI SELECT VARIABLES (ADDED ONLY THESE)
//   bool _isMultiSelectMode = false;
//   Set<String> _selectedCategoryKeys = {};
//   Set<String> _selectedItemKeys = {};

//   late AnimationController _arrowController;

//   Set<String> _activeFilters = {'mrp', 'wsp', 'shades', 'stylecode'};

//   void _updateFilters(Set<String> newFilters) {
//     setState(() {
//       _activeFilters = newFilters;
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     showBarcodeWidget = widget.startWithBarcode;
//     _fetchCategories();
//     fetchAllItems();

//     if (coBr != null && fcYrId != null) {
//       _fetchCartCount();
//     }
//     fetchPartyList();

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

//   fetchPartyList() async {
//     final fetchedResponse = await ApiService.fetchPartyWithSpclMarkDwn(
//       ledCat: 'w',
//       coBrId: UserSession.coBrId ?? '',
//     );

//     setState(() {
//       partyList = List<PartyWithSpclMarkDwn>.from(
//         fetchedResponse['result'] ?? [],
//       );
//     });
//   }

//   // Replace the existing _fetchCartCount method
//   Future<void> _fetchCartCount() async {
//     try {
//       final data = await ApiService.getSalesOrderData(
//         coBrId: UserSession.coBrId ?? '',
//         userId: UserSession.userName ?? '',
//         fcYrId: UserSession.userFcYr ?? '',
//         barcode: showBarcodeWidget ? 'true' : 'false',
//       );

//       final cartModel = Provider.of<CartModel>(context, listen: false);
//       cartModel.updateCount(data['cartItemCount'] ?? 0);
//     } catch (e) {
//       print('Error fetching cart count: $e');
//     }
//   }

//   Future<void> _fetchCategories() async {
//     try {
//       final items = await ApiService.fetchAllItems();
//       setState(() {
//         _items = items;
//         _allItems = items;
//       });
//     } catch (e) {
//       print('Error fetching categories: $e');
//     }
//   }

//   Future<void> fetchAllItems() async {
//     try {
//       final categories = await ApiService.fetchCategories();
//       setState(() {
//         _categories = [
//           //  Category(itemSubGrpKey: '-1', itemSubGrpName: "ALL"),
//           ...categories,
//         ];
//         _isLoadingCategories = false;
//       });
//     } catch (e) {
//       print('Error fetching categories: $e');
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
//     final cartModel = Provider.of<CartModel>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       drawer: DrawerScreen(),
//       appBar: AppBar(
//         title: Text(
//           showBarcodeWidget ? 'Barcode' : 'Order Booking',
//           style: const TextStyle(color: Colors.white),
//         ),
//         backgroundColor: AppColors.primaryColor,
//         elevation: 1,
//         leading:
//             showBarcodeWidget
//                 ? IconButton(
//                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                   onPressed: () {
//                     setState(() {
//                       showBarcodeWidget = false;
//                     });
//                   },
//                 )
//                 : Builder(
//                   builder:
//                       (context) => IconButton(
//                         icon: const Icon(Icons.menu, color: Colors.white),
//                         onPressed: () => Scaffold.of(context).openDrawer(),
//                       ),
//                 ),
//         automaticallyImplyLeading: false,
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Stack(
//               clipBehavior:
//                   Clip.none, // Important to allow badge to show outside
//               children: [
//                 // Cart Icon for both modes (Order Booking and Barcode)
//                 IconButton(
//                   icon: const Icon(
//                     CupertinoIcons.cart_badge_plus,
//                     color: Colors.white,
//                     size: 22,
//                   ),
//                   onPressed: () {
//                     String route;

//                     if (showBarcodeWidget) {
//                       // Barcode routes
//                       if (AppConstants.bookingType == "1") {
//                         route = '/viewOrderBarcode';
//                       } else if (AppConstants.bookingType == "2") {
//                         route = '/viewOrderBarcode2';
//                       } else {
//                         route = '/viewOrderBarcode'; // fallback
//                       }
//                     } else {
//                       // Normal routes
//                       if (AppConstants.bookingType == "1") {
//                         route = '/viewOrder';
//                       } else if (AppConstants.bookingType == "2") {
//                         route = '/viewOrder2';
//                       } else {
//                         route = '/viewOrder'; // fallback
//                       }
//                     }

//                     Navigator.pushNamed(
//                       context,
//                       route,
//                       arguments: {Constants.barcode: showBarcodeWidget},
//                     ).then((_) => _fetchCartCount());
//                   },
//                 ),

//                 if (cartModel.count > 0)
//                   Positioned(
//                     right: 6, // Adjusted position
//                     top: 7, // Adjusted position
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                       constraints: const BoxConstraints(
//                         minWidth: 18,
//                         minHeight: 18,
//                       ),
//                       child: Center(
//                         child: Text(
//                           '${cartModel.count}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),

//             // Orders icon (commented out as in your code)
//             // IconButton(
//             //   icon: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
//             //   tooltip: 'My Orders',
//             //   onPressed: () {
//             //     Navigator.push(
//             //       context,
//             //       MaterialPageRoute(builder: (context) => RegisterPage()),
//             //     );
//             //   },
//             // ),
//           ),
//         ],
//       ),

//       // ✅ FLOATING ACTION BUTTON - ONLY APPEARS WHEN ITEMS SELECTED
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
//                       '/orderpage',
//                       arguments: {
//                         'itemKey': itemKeys,
//                         'itemSubGrpKey': categoryKeys,
//                         'itemName': null,
//                         'coBr': coBr,
//                         'fcYrId': fcYrId,
//                         'selectedParty': selectedParty,
//                         'type': Constants.SALE_BILL,
//                         'isMultiSelect': true,
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
//         padding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced padding
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             // Button width: total width minus 16 (padding) minus 8 (gap), divided by 2, increased by 20%
//             double buttonWidth = ((constraints.maxWidth - 16 - 8) / 2) * 1;
//             return SingleChildScrollView(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SizedBox(height: 10),
//                       // Row(
//                       //   children: [
//                       //     Expanded(
//                       //       child: DropdownSearch<PartyWithSpclMarkDwn>(
//                       //         items: partyList,
//                       //         selectedItem: selectedParty,
//                       //         itemAsString: (PartyWithSpclMarkDwn? u) => u?.ledName ?? '',
//                       //         onChanged:
//                       //             (value) =>
//                       //                 setState(() => selectedParty = value),
//                       //         popupProps: PopupProps.menu(
//                       //           showSearchBox: true,
//                       //           containerBuilder:
//                       //               (context, popupWidget) => Container(
//                       //                 decoration: BoxDecoration(
//                       //                   color: Colors.white,
//                       //                   borderRadius: BorderRadius.circular(8),
//                       //                   boxShadow: [
//                       //                     BoxShadow(
//                       //                       color: Colors.grey.withOpacity(0.5),
//                       //                       spreadRadius: 2,
//                       //                       blurRadius: 5,
//                       //                       offset: Offset(0, 3),
//                       //                     ),
//                       //                   ],
//                       //                 ),
//                       //                 child: popupWidget,
//                       //               ),
//                       //         ),
//                       //         // dropdownDecoratorProps: DropDownDecoratorProps(
//                       //         //   dropdownSearchDecoration: InputDecoration(
//                       //         //     labelText: 'Select Party',
//                       //         //     filled: true,
//                       //         //     fillColor: Colors.white,
//                       //         //     border: OutlineInputBorder(
//                       //         //       borderRadius: BorderRadius.circular(8),
//                       //         //     ),
//                       //         //   ),
//                       //         // ),
//                       //       // ),
//                       //     ),
//                       //   ],
//                       // ),

//                       // Row(
//                       //   children: [
//                       // DropdownSearch<KeyName>(
//                       //   items: ledgerList,
//                       //   selectedItem: selectedLedger,
//                       //   itemAsString: (KeyName? u) => u?.name ?? '',
//                       //   onChanged:
//                       //       (value) =>
//                       //           setState(() => selectedLedger = value),
//                       //   popupProps: PopupProps.menu(
//                       //     showSearchBox: true,
//                       //     containerBuilder:
//                       //         (context, popupWidget) => Container(
//                       //           decoration: BoxDecoration(
//                       //             color: Colors.white, // Menu background
//                       //             borderRadius: BorderRadius.circular(8),
//                       //             boxShadow: [
//                       //               BoxShadow(
//                       //                 color: Colors.grey.withOpacity(0.5),
//                       //                 spreadRadius: 2,
//                       //                 blurRadius: 5,
//                       //                 offset: Offset(0, 3),
//                       //               ),
//                       //             ],
//                       //           ),
//                       //           child: popupWidget,
//                       //         ),
//                       //   ),
//                       //   dropdownDecoratorProps: DropDownDecoratorProps(
//                       //     dropdownSearchDecoration: InputDecoration(
//                       //       labelText: 'Select Party',
//                       //       filled: true,
//                       //       fillColor: Colors.white,
//                       //       border: OutlineInputBorder(
//                       //         borderRadius: BorderRadius.circular(8),
//                       //       ),
//                       //     ),
//                       //   ),
//                       // ),
//                       //   ],
//                       // ),
//                       SizedBox(
//                         width: double.infinity,
//                         child: Row(
//                           children: [
//                             Checkbox(
//                               value: showBarcodeWidget,
//                               onChanged: (value) {
//                                 setState(() {
//                                   showBarcodeWidget = value ?? false;
//                                   _fetchCartCount();
//                                 });
//                               },
//                             ),
//                             const Text(
//                               "Order Booking Barcode Wise",
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (showBarcodeWidget)
//                         SizedBox(
//                           width: double.infinity,
//                           child: BarcodeWiseWidget(
//                             onFilterPressed: (barcode) {
//                               print("Barcode: $barcode");
//                               setState(() {
//                                 hasFiltered = true;
//                               });
//                             },
//                             // activeFilters: _activeFilters,
//                           ),
//                         ),
//                       if (!showBarcodeWidget) ...[
//                         const SizedBox(height: 15),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                           child: const Text(
//                             "Categories",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         _isLoadingCategories
//                             ? Center(
//                               child: LoadingAnimationWidget.waveDots(
//                                 color: AppColors.primaryColor,
//                                 size: 30,
//                               ),
//                             )
//                             : Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8.0,
//                               ),
//                               child: Wrap(
//                                 spacing: 8, // Reduced gap between buttons
//                                 runSpacing: 10,
//                                 alignment: WrapAlignment.start,
//                                 children:
//                                     _categories.map((category) {
//                                       bool isSelected = _selectedCategoryKeys
//                                           .contains(category.itemSubGrpKey);

//                                       return SizedBox(
//                                         width: buttonWidth, // Increased width
//                                         child: OutlinedButton(
//                                           // ✅ TAP BEHAVIOR - Changes based on mode
//                                           onPressed: () {
//                                             setState(() {
//                                               _isMultiSelectMode = true;

//                                               if (isSelected) {
//                                                 _selectedCategoryKeys.remove(
//                                                   category.itemSubGrpKey,
//                                                 );
//                                               } else {
//                                                 _selectedCategoryKeys.add(
//                                                   category.itemSubGrpKey,
//                                                 );
//                                               }

//                                               _filterItems();
//                                               _exitMultiSelectMode();
//                                             });
//                                           }, // ✅ LONG PRESS FOR MULTI-SELECT
//                                           // onLongPress: () {
//                                           //   setState(() {
//                                           //     _isMultiSelectMode = true;
//                                           //     if (isSelected) {
//                                           //       _selectedCategoryKeys.remove(
//                                           //         category.itemSubGrpKey,
//                                           //       );
//                                           //     } else {
//                                           //       _selectedCategoryKeys.add(
//                                           //         category.itemSubGrpKey,
//                                           //       );
//                                           //     }
//                                           //     _filterItems();
//                                           //   });
//                                           // },
//                                           style: ButtonStyle(
//                                             backgroundColor:
//                                                 WidgetStateProperty.all(
//                                                   isSelected
//                                                       ? AppColors.primaryColor
//                                                       : Colors.white,
//                                                 ),
//                                             side: WidgetStateProperty.all(
//                                               BorderSide(
//                                                 color: AppColors.primaryColor,
//                                                 width: isSelected ? 2 : 1,
//                                               ),
//                                             ),
//                                             shape: WidgetStateProperty.all(
//                                               RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(8),
//                                               ),
//                                             ),
//                                           ),
//                                           child: Text(
//                                             category.itemSubGrpName,
//                                             textAlign:
//                                                 TextAlign.center, // Center text
//                                             style: TextStyle(
//                                               color:
//                                                   isSelected
//                                                       ? Colors.white
//                                                       : AppColors.primaryColor,
//                                               fontSize:
//                                                   14, // Consistent font size
//                                               fontWeight:
//                                                   isSelected
//                                                       ? FontWeight.bold
//                                                       : FontWeight.normal,
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     }).toList(),
//                               ),
//                             ),
//                         const SizedBox(height: 20),
//                         if (_selectedCategoryKey != null)
//                           _buildCategoryItems(buttonWidth),
//                       ],
//                       const Spacer(),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationWidget(
//         currentScreen: '/orderbooking',
//       ),
//     );
//   }

//   Widget _buildCategoryItems(double buttonWidth) {
//     double buttonHeight = 43;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//           child: Text(
//             "Items",
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//           ),
//         ),
//         const SizedBox(height: 10),
//         _isLoadingItems
//             ? Center(
//               child: LoadingAnimationWidget.waveDots(
//                 color: AppColors.primaryColor,
//                 size: 30,
//               ),
//             )
//             : Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//               child: Wrap(
//                 spacing: 8, // Reduced gap between buttons
//                 runSpacing: 10,
//                 alignment: WrapAlignment.start,
//                 children:
//                     _items.map((item) {
//                       bool isSelected = _selectedItemKeys.contains(
//                         item.itemKey,
//                       );

//                       return SizedBox(
//                         width: buttonWidth, // Increased width
//                         height: buttonHeight,
//                         child: OutlinedButton(
//                           // ✅ TAP BEHAVIOR - Changes based on mode
//                           onPressed: () {
//                             setState(() {
//                               _isMultiSelectMode = true;

//                               setState(() {
//                                 _isMultiSelectMode = true;

//                                 if (isSelected) {
//                                   _selectedItemKeys.remove(item.itemKey);

//                                   // check if any other selected item belongs to this category
//                                   bool hasOtherItemsInCategory =
//                                       _selectedItemKeys.any((itemKey) {
//                                         final selectedItem = _allItems
//                                             .firstWhere(
//                                               (i) => i.itemKey == itemKey,
//                                             );
//                                         return selectedItem.itemSubGrpKey ==
//                                             item.itemSubGrpKey;
//                                       });

//                                   if (!hasOtherItemsInCategory &&
//                                       item.itemSubGrpKey != null) {
//                                     _selectedCategoryKeys.remove(
//                                       item.itemSubGrpKey,
//                                     );
//                                   }
//                                 } else {
//                                   _selectedItemKeys.add(item.itemKey);

//                                   if (item.itemSubGrpKey != null) {
//                                     _selectedCategoryKeys.add(
//                                       item.itemSubGrpKey!,
//                                     );
//                                   }
//                                 }

//                                 _exitMultiSelectMode();
//                               });

//                               _exitMultiSelectMode();
//                             });
//                           }, // ✅ LONG PRESS FOR MULTI-SELECT
//                           // onLongPress: () {
//                           //   setState(() {
//                           //     _isMultiSelectMode = true;
//                           //     if (isSelected) {
//                           //       _selectedItemKeys.remove(item.itemKey);
//                           //     } else {
//                           //       _selectedItemKeys.add(item.itemKey);
//                           //        if (item.itemSubGrpKey != null) {
//                           //         _selectedCategoryKeys.add(item.itemSubGrpKey!);
//                           //       }
//                           //     }
//                           //   });
//                           // },
//                           style: OutlinedButton.styleFrom(
//                             side: BorderSide(
//                               color:
//                                   isSelected
//                                       ? AppColors.primaryColor
//                                       : Colors.grey.shade300,
//                               width: isSelected ? 2 : 1,
//                             ),
//                             backgroundColor:
//                                 isSelected
//                                     ? AppColors.primaryColor
//                                     : Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: Text(
//                             item.itemName,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: isSelected ? Colors.white : Colors.black87,
//                               fontSize: 14,
//                               fontWeight:
//                                   isSelected
//                                       ? FontWeight.bold
//                                       : FontWeight.normal,
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//               ),
//             ),
//       ],
//     );
//   }
// }



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
  final bool startWithBarcode;

  const OrderBookingScreen({Key? key, this.startWithBarcode = false})
    : super(key: key);

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
  String? _categoryError;
  String? _itemsError; // ✅ ADDED: Missing error variable
  bool hasFiltered = false;
  List<PartyWithSpclMarkDwn> partyList = [];
  PartyWithSpclMarkDwn? selectedParty;
  // int _cartItemCount = 0;
  bool _isFetchingCart = false;

  // ✅ MULTI SELECT VARIABLES (ADDED ONLY THESE)
  bool _isMultiSelectMode = false;
  Set<String> _selectedCategoryKeys = {};
  Set<String> _selectedItemKeys = {};

  late AnimationController _arrowController;

  Set<String> _activeFilters = {'mrp', 'wsp', 'shades', 'stylecode'};

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    showBarcodeWidget = widget.startWithBarcode;
    _fetchCategories();
    _fetchAllItems(); // ✅ FIXED: Changed from fetchAllItems to _fetchAllItems

    if (coBr != null && fcYrId != null) {
      _fetchCartCount();
    }
    fetchPartyList();

    _arrowController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _searchController.addListener(_onSearchChanged);

    // Add listener to CartModel for real-time updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartModel = Provider.of<CartModel>(context, listen: false);
      cartModel.addListener(_onCartChanged);
    });
  }

  void _onCartChanged() {
    setState(() {
      // Just trigger a rebuild to show updated count
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
   
  }

  // Add this method to refresh cart count from barcode
  void _refreshCartCount() {
    _fetchCartCount();
  }

  @override
  void dispose() {
      final cartModel = Provider.of<CartModel>(context, listen: false);
    cartModel.removeListener(_onCartChanged);
    _searchController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  fetchPartyList() async {
    final fetchedResponse = await ApiService.fetchPartyWithSpclMarkDwn(
      ledCat: 'w',
      coBrId: UserSession.coBrId ?? '',
    );

    setState(() {
      partyList = List<PartyWithSpclMarkDwn>.from(
        fetchedResponse['result'] ?? [],
      );
    });
  }

void _showMessageDialog(String title, String message) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                title.contains('Error') ? Icons.error_outline : Icons.info_outline,
                size: 50,
                color: title.contains('Error') ? Colors.red : AppColors.primaryColor,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  minimumSize: const Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(fontSize: 16),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}
  // Replace the existing _fetchCartCount method
 Future<void> _fetchCartCount() async {
  if (_isFetchingCart) return;

  _isFetchingCart = true;

  try {
    final data = await ApiService.getSalesOrderData(
      coBrId: UserSession.coBrId ?? '',
      userId: UserSession.userName ?? '',
      fcYrId: UserSession.userFcYr ?? '',
      barcode: showBarcodeWidget ? 'true' : 'false',
    );

    final cartModel = Provider.of<CartModel>(context, listen: false);

    if (mounted) {
      cartModel.updateCount(data['cartItemCount'] ?? 0);
    }
  } catch (e) {
    print('Error fetching cart count: $e');
  } finally {
    _isFetchingCart = false;
  }
}

 Future<void> _fetchCategories() async {
  try {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    final categories = await ApiService.fetchCategories();

    if (categories.isEmpty) {
      _showMessageDialog("No Data", "No categories found.");
    }

    setState(() {
      _categories = [...categories];
      _isLoadingCategories = false;
    });

  } catch (e) {
    setState(() {
      _isLoadingCategories = false;
    });

    _showMessageDialog("Error", "Failed to load categories");
  }
}
 Future<void> _fetchAllItems() async {
  try {
    setState(() {
      _isLoadingItems = true;
      _itemsError = null;
    });

    final items = await ApiService.fetchAllItems();

    if (items.isEmpty) {
      _showMessageDialog("No Data", "No items found.");
    }

    setState(() {
      _items = items;
      _allItems = items;
      _isLoadingItems = false;
    });

  } catch (e) {
    setState(() {
      _isLoadingItems = false;
    });

    _showMessageDialog("Error", "Failed to load items");
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

  List<Item> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }
    return _items.where((item) {
      return item.itemName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _exitMultiSelectMode() {
    if (_selectedCategoryKeys.isEmpty && _selectedItemKeys.isEmpty) {
      setState(() {
        _isMultiSelectMode = false;
      });
    }
  }

  int get _totalSelectedItems {
    return _selectedCategoryKeys.length + _selectedItemKeys.length;
  }

  void _clearAllSelections() {
    setState(() {
      _selectedCategoryKeys.clear();
      _selectedItemKeys.clear();
      _isMultiSelectMode = false;
      _filterItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartModel = Provider.of<CartModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              showBarcodeWidget ? 'Barcode' : 'Order Booking',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
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
                  builder:
                      (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                ),
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.cart_badge_plus,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    String route;

                    if (showBarcodeWidget) {
                      if (AppConstants.bookingType == "1") {
                        route = '/viewOrderBarcode';
                      } else if (AppConstants.bookingType == "2") {
                        route = '/viewOrderBarcode2';
                      } else {
                        route = '/viewOrderBarcode';
                      }
                    } else {
                      if (AppConstants.bookingType == "1") {
                        route = '/viewOrder';
                      } else if (AppConstants.bookingType == "2") {
                        route = '/viewOrder2';
                      } else {
                        route = '/viewOrder';
                      }
                    }

                    Navigator.pushNamed(
                      context,
                      route,
                      arguments: {Constants.barcode: showBarcodeWidget},
                    ).then((_) => _fetchCartCount());
                  },
                ),
                if (cartModel.count > 0)
                  Positioned(
                    right: 6,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '${cartModel.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withOpacity(0.2), height: 1),
        ),
      ),

      // ✅ FLOATING ACTION BUTTON - ONLY APPEARS WHEN ITEMS SELECTED
   floatingActionButton:
    (_selectedCategoryKeys.isNotEmpty || _selectedItemKeys.isNotEmpty) &&
            !showBarcodeWidget
        ? ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.1).animate(_arrowController),
          child: SizedBox(
            height: 56,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primaryColor,
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'View',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
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
                  setState(() {
                    _selectedCategoryKeys.clear();
                    _selectedItemKeys.clear();
                    _isMultiSelectMode = false;
                    _filterItems();
                  });
                });
              },
            ),
          ),
        )
        : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double buttonWidth = ((constraints.maxWidth - 16 - 8) / 2) * 1;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Party Dropdown (commented out as in original)
                      // ... (keep your commented code as is)

                      // Barcode Checkbox with improved styling
                      // Barcode Checkbox with improved styling
Container(
  margin: const EdgeInsets.symmetric(horizontal: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey[300]!),
  ),
  child: Row(
    children: [
      Checkbox(
        value: showBarcodeWidget,
        activeColor: AppColors.primaryColor,
        onChanged: (value) {
          setState(() {
            showBarcodeWidget = value ?? false;
            // Refresh cart count when toggling barcode mode
            Future.delayed(const Duration(milliseconds: 100), () {
              _fetchCartCount();
            });
          });
        },
      ),
      const Text(
        "Order Booking Barcode Wise",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ],
  ),
),

                      const SizedBox(height: 12),

                      // In OrderBookingScreen build method, update the BarcodeWiseWidget section
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
      onOrderConfirmed: () {
        // Refresh cart count when order is confirmed from barcode
        _fetchCartCount();
      },
      edit: false, // or appropriate value
    ),
  ),

                      if (!showBarcodeWidget) ...[
                        const SizedBox(height: 20),

                        // Categories Header with Vertical Line
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
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
                              const Spacer(),
                              // if (_categories.isNotEmpty &&
                              //     !_isLoadingCategories)
                              //   Text(
                              //     '${_categories.length} total',
                              //     style: TextStyle(
                              //       fontSize: 12,
                              //       color: Colors.grey[600],
                              //     ),
                              //   ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        _isLoadingCategories
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: LoadingAnimationWidget.waveDots(
                                  color: AppColors.primaryColor,
                                  size: 30,
                                ),
                              ),
                            )
                            : _categoryError != null
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
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
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: _fetchCategories,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Wrap(
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
                            ),

                        const SizedBox(height: 24),

                        // Items Header with Vertical Line and Search
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  const Spacer(),
                                  //if (!_isLoadingItems && _items.isNotEmpty)
                                    // Text(
                                    //   '${_filteredItems.length} of ${_items.length}',
                                    //   style: TextStyle(
                                    //     fontSize: 12,
                                    //     color: Colors.grey[600],
                                    //   ),
                                    // ),
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
                                    hintText: 'Search items...',
                                    hintStyle: TextStyle(
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
                                              onPressed:
                                                  () =>
                                                      _searchController.clear(),
                                            )
                                            : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Items Section
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
      bottomNavigationBar: BottomNavigationWidget(
        currentScreen: '/orderbooking',
      ),
    );
  }

  Widget _buildCategoryChip(
    Category category,
    bool isSelected,
    double buttonWidth,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMultiSelectMode = true;

          if (isSelected) {
            _selectedCategoryKeys.remove(category.itemSubGrpKey);
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
      //       _selectedCategoryKeys.remove(
      //         category.itemSubGrpKey,
      //       );
      //     } else {
      //       _selectedCategoryKeys.add(
      //         category.itemSubGrpKey,
      //       );
      //     }
      //     _filterItems();
      //   });
      // },
      child: Container(
        width: buttonWidth,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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

    return _isLoadingItems
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      _fetchAllItems, // ✅ FIXED: Changed from _fetchAllItems to _fetchAllItems
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
        : _filteredItems.isEmpty
    ? Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.inbox : Icons.search_off,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty ? 'No items found' : 'No matching items',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () => _searchController.clear(),
                child: Text(
                  'Clear search',
                  style: TextStyle(color: AppColors.primaryColor),
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
                  bool isSelected = _selectedItemKeys.contains(item.itemKey);

                  return _buildItemChip(
                    item,
                    isSelected,
                    buttonWidth,
                    buttonHeight,
                  );
                }).toList(),
          ),
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

            bool hasOtherItemsInCategory = _selectedItemKeys.any((itemKey) {
              final selectedItem = _allItems.firstWhere(
                (i) => i.itemKey == itemKey,
              );
              return selectedItem.itemSubGrpKey == item.itemSubGrpKey;
            });

            if (!hasOtherItemsInCategory && item.itemSubGrpKey != null) {
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
