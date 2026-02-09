import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/category.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AddMoreItemsForEdit extends StatefulWidget {
  const AddMoreItemsForEdit({super.key});

  @override
  State<AddMoreItemsForEdit> createState() => _AddMoreItemsForEditState();
}

class _AddMoreItemsForEditState extends State<AddMoreItemsForEdit> {
  String? _selectedCategoryKey = '-1';
  String? _selectedCategoryName = 'All';
  List<Category> _categories = [];
  List<Item> _items = [];
  List<Item> _allItems = [];
  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    fetchAllItems();
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
        _categories = [...categories];
        _isLoadingCategories = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add More Items',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                      const SizedBox(height: 15),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 10,
                                alignment: WrapAlignment.start,
                                children: _categories.map((category) {
                                  return SizedBox(
                                    width: buttonWidth,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/orderpage',
                                          arguments: {
                                            'itemKey': null,
                                            'itemSubGrpKey':
                                                category.itemSubGrpKey,
                                            'itemName':
                                                category.itemSubGrpName.trim(),
                                            'edit':true
                                            // 'coBr': UserSession.coBrId,
                                            // 'fcYrId': UserSession.coBrId,
                                            
                                          },
                                        );
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          _selectedCategoryKey ==
                                                  category.itemSubGrpKey
                                              ? AppColors.primaryColor
                                              : Colors.white,
                                        ),
                                        side: MaterialStateProperty.all(
                                          BorderSide(
                                            color: AppColors.primaryColor,
                                            width: 1,
                                          ),
                                        ),
                                        shape: MaterialStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(0),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        category.itemSubGrpName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _selectedCategoryKey ==
                                                  category.itemSubGrpKey
                                              ? Colors.white
                                              : AppColors.primaryColor,
                                          fontSize: 14,
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
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
            "Items in $_selectedCategoryName",
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
                  spacing: 8,
                  runSpacing: 10,
                  alignment: WrapAlignment.start,
                  children: _items.map((item) {
                    return SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/orderpage',
                            arguments: {
                              'itemKey': item.itemKey,
                              'itemName': item.itemName.trim(),
                              'itemSubGrpKey': item.itemSubGrpKey,
                              // 'coBr': UserSession.coBrId,
                              // 'fcYrId': UserSession.userFcYr,
                              'edit' : true
                            },
                          );
                        },
                        child: Text(
                          item.itemName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
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
