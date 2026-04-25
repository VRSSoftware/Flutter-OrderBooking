import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';

class AddItemPage extends StatefulWidget {
  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  // Dropdown selections
  KeyName? selectedProduct;
  KeyName? selectedDesign;
  KeyName? selectedType;
  KeyName? selectedShade;
  KeyName? selectedBrand;

  // Text controllers
  final TextEditingController rateController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController avgRtController = TextEditingController();
  final TextEditingController itemAmtController = TextEditingController();
  final TextEditingController discController = TextEditingController();
  final TextEditingController discPercentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Lists for dropdowns (using KeyName for consistency)
  final List<KeyName> productList = [
    KeyName(key: 'P001', name: 'Product 1'),
    KeyName(key: 'P002', name: 'Product 2'),
    KeyName(key: 'P003', name: 'Product 3'),
    KeyName(key: 'P004', name: 'Product 4'),
  ];
  final List<KeyName> designList = [
    KeyName(key: 'D001', name: 'Design A'),
    KeyName(key: 'D002', name: 'Design B'),
    KeyName(key: 'D003', name: 'Design C'),
  ];
  final List<KeyName> typeList = [
    KeyName(key: 'T001', name: 'Type X'),
    KeyName(key: 'T002', name: 'Type Y'),
    KeyName(key: 'T003', name: 'Type Z'),
  ];
  final List<KeyName> shadeList = [
    KeyName(key: 'S001', name: 'Shade 1'),
    KeyName(key: 'S002', name: 'Shade 2'),
    KeyName(key: 'S003', name: 'Shade 3'),
    KeyName(key: 'S004', name: 'Shade 4'),
  ];
  final List<KeyName> brandList = [
    KeyName(key: 'B001', name: 'Brand P'),
    KeyName(key: 'B002', name: 'Brand Q'),
    KeyName(key: 'B003', name: 'Brand R'),
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners to auto-calculate
    rateController.addListener(_calculateAmount);
    qtyController.addListener(_calculateAmount);
    discPercentController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    rateController.dispose();
    mrpController.dispose();
    qtyController.dispose();
    avgRtController.dispose();
    itemAmtController.dispose();
    discController.dispose();
    discPercentController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    double rate = double.tryParse(rateController.text) ?? 0.0;
    double qty = double.tryParse(qtyController.text) ?? 0.0;
    double discPercent = double.tryParse(discPercentController.text) ?? 0.0;

    double itemAmt = rate * qty;
    double disc = itemAmt * discPercent / 100;
    double amount = itemAmt - disc;

    itemAmtController.text = itemAmt.toStringAsFixed(2);
    discController.text = disc.toStringAsFixed(2);
    amountController.text = amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Details Section
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDropdownField('Product', productList, selectedProduct, (value) {
                    setState(() => selectedProduct = value);
                  }, isRequired: true),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField('Design', designList, selectedDesign, (value) {
                          setState(() => selectedDesign = value);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField('Type', typeList, selectedType, (value) {
                          setState(() => selectedType = value);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField('Shade', shadeList, selectedShade, (value) {
                          setState(() => selectedShade = value);
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField('Brand', brandList, selectedBrand, (value) {
                          setState(() => selectedBrand = value);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('Rate', rateController, keyboardType: TextInputType.number, isRequired: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField('MRP', mrpController, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('Qty', qtyController, keyboardType: TextInputType.number, isRequired: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField('Avg Rt', avgRtController, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Amount Section
                  const Text(
                    'Amount Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildReadOnlyField('Item Amt', itemAmtController),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyField('Disc', discController),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField('Disc (%)', discPercentController, keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildReadOnlyField('Amount', amountController),
                  const SizedBox(height: 12),
                  
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Description Section
                  const Text(
                    'Additional Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField('Description', descriptionController, maxLines: 3),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Bottom Buttons
          _buildBottomButtons(),
        ],
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
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
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
                  onPressed: () {
                    // Validate required fields
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select Product'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (qtyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter Qty'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (rateController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter Rate'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Create item data
                    Map<String, dynamic> itemData = {
                      'Product': selectedProduct?.name ?? '',
                      'ProductKey': selectedProduct?.key ?? '',
                      'Design': selectedDesign?.name ?? '',
                      'DesignKey': selectedDesign?.key ?? '',
                      'Type': selectedType?.name ?? '',
                      'TypeKey': selectedType?.key ?? '',
                      'Shade': selectedShade?.name ?? '',
                      'ShadeKey': selectedShade?.key ?? '',
                      'Brand': selectedBrand?.name ?? '',
                      'BrandKey': selectedBrand?.key ?? '',
                      'Rate': double.tryParse(rateController.text) ?? 0.0,
                      'MRP': double.tryParse(mrpController.text) ?? 0.0,
                      'Qty': double.tryParse(qtyController.text) ?? 0.0,
                      'Avg Rt': double.tryParse(avgRtController.text) ?? 0.0,
                      'Item Amt': double.tryParse(itemAmtController.text) ?? 0.0,
                      'Disc': double.tryParse(discController.text) ?? 0.0,
                      'Disc (%)': double.tryParse(discPercentController.text) ?? 0.0,
                      'Amount': double.tryParse(amountController.text) ?? 0.0,
                      'Description': descriptionController.text,
                    };
                    Navigator.pop(context, itemData);
                  },
                  icon: const Icon(Icons.check, size: 20, color: Colors.white),
                  label: const Text(
                    "Confirm",
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

  Widget _buildTextField(String label, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<KeyName> items,
    KeyName? selectedValue,
    Function(KeyName?) onChanged, {
    bool isRequired = false,
  }) {
    return DropdownSearch<KeyName>(
      validator: (value) =>
          isRequired && value == null ? "$label is required" : null,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search $label",
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
        ),
      ),
      items: items,
      itemAsString: (KeyName? keyName) => keyName?.name ?? '',
      selectedItem: selectedValue,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      dropdownBuilder: (context, selectedItem) => Text(
        selectedItem?.name ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      onChanged: onChanged,
    );
  }
}

