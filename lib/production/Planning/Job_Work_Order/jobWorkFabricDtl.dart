import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class FabricDetailsScreenForJobWork extends StatefulWidget {
  final Map<String, dynamic>? fabricDetail;
  
  const FabricDetailsScreenForJobWork({super.key, this.fabricDetail});

  @override
  State<FabricDetailsScreenForJobWork> createState() => _FabricDetailsScreenForJobWorkState();
}

class _FabricDetailsScreenForJobWorkState extends State<FabricDetailsScreenForJobWork> {
  // ────────────────────── Controllers ──────────────────────
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _productCtrl = TextEditingController();
  final TextEditingController _designCtrl = TextEditingController();
  final TextEditingController _shadeCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _ratioCtrl = TextEditingController();
  final TextEditingController _reqQtyCtrl = TextEditingController();
  final TextEditingController _wastCtrl = TextEditingController();
  final TextEditingController _actualQtyCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  
  // ────────────────────── Selected Values ──────────────────────
  String? _selectedType;
  String? _selectedProduct;
  String? _selectedDesign;
  String? _selectedShade;
  String? _selectedBrand;
  
  // ────────────────────── Dropdown Lists ──────────────────────
  final List<String> _typeList = ['Cotton', 'Polyester', 'Denim', 'Linen', 'Silk'];
  final List<String> _productList = ['Product A', 'Product B', 'Product C', 'Product D'];
  final List<String> _designList = ['DES001', 'DES002', 'DES003', 'DES004', 'DES005'];
  final List<String> _shadeList = ['White', 'Black', 'Blue', 'Red', 'Green', 'Yellow'];
  final List<String> _brandList = ['Brand A', 'Brand B', 'Brand C', 'Brand D'];
  
  // ────────────────────── Focus Nodes ──────────────────────
  final FocusNode _typeFocus = FocusNode();
  final FocusNode _productFocus = FocusNode();
  final FocusNode _designFocus = FocusNode();
  final FocusNode _shadeFocus = FocusNode();
  final FocusNode _brandFocus = FocusNode();
  final FocusNode _widthFocus = FocusNode();
  final FocusNode _ratioFocus = FocusNode();
  final FocusNode _reqQtyFocus = FocusNode();
  final FocusNode _wastFocus = FocusNode();
  final FocusNode _actualQtyFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _remarkFocus = FocusNode();
  
  // ────────────────────── Search Controllers ──────────────────────
  final TextEditingController _typeSearchCtrl = TextEditingController();
  final TextEditingController _productSearchCtrl = TextEditingController();
  final TextEditingController _designSearchCtrl = TextEditingController();
  final TextEditingController _shadeSearchCtrl = TextEditingController();
  final TextEditingController _brandSearchCtrl = TextEditingController();
  
  double _qtyVar = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Add listener for wast% to calculate actual qty
    _wastCtrl.addListener(_calculateActualQty);
    _reqQtyCtrl.addListener(_calculateActualQty);
    
    if (widget.fabricDetail != null) {
      _populateFormWithExistingData();
    }
  }
  
  void _populateFormWithExistingData() {
    final data = widget.fabricDetail!;
    _selectedType = data['type'];
    _typeCtrl.text = _selectedType ?? '';
    _selectedProduct = data['product'];
    _productCtrl.text = _selectedProduct ?? '';
    _selectedDesign = data['design'];
    _designCtrl.text = _selectedDesign ?? '';
    _selectedShade = data['shade'];
    _shadeCtrl.text = _selectedShade ?? '';
    _selectedBrand = data['brand'];
    _brandCtrl.text = _selectedBrand ?? '';
    _widthCtrl.text = data['width']?.toString() ?? '';
    _ratioCtrl.text = data['ratio']?.toString() ?? '';
    _reqQtyCtrl.text = data['reqQty']?.toString() ?? '';
    _wastCtrl.text = data['wast']?.toString() ?? '';
    _actualQtyCtrl.text = data['actualQty']?.toString() ?? '';
    _descriptionCtrl.text = data['description'] ?? '';
    _remarkCtrl.text = data['remark'] ?? '';
    _qtyVar = data['qtyVar'] ?? 0;
  }
  
  void _calculateActualQty() {
    double reqQty = double.tryParse(_reqQtyCtrl.text) ?? 0;
    double wast = double.tryParse(_wastCtrl.text) ?? 0;
    
    double actualQty = reqQty + (reqQty * wast / 100);
    _actualQtyCtrl.text = actualQty.toStringAsFixed(2);
  }
  
  void _showQtyVarDialog() {
    final TextEditingController qtyVarController = TextEditingController(
      text: _qtyVar.toString()
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Qty Var (%)'),
        content: TextField(
          controller: qtyVarController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Qty Var (%)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _qtyVar = double.tryParse(qtyVarController.text) ?? 0;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _typeCtrl.dispose();
    _productCtrl.dispose();
    _designCtrl.dispose();
    _shadeCtrl.dispose();
    _brandCtrl.dispose();
    _widthCtrl.dispose();
    _ratioCtrl.dispose();
    _reqQtyCtrl.dispose();
    _wastCtrl.dispose();
    _actualQtyCtrl.dispose();
    _descriptionCtrl.dispose();
    _remarkCtrl.dispose();
    _typeSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    _designSearchCtrl.dispose();
    _shadeSearchCtrl.dispose();
    _brandSearchCtrl.dispose();
    super.dispose();
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool readOnly = false,
    bool isRequired = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focusNode.hasFocus ? AppColors.primaryColor : Colors.grey.shade300,
                width: focusNode.hasFocus ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: InputBorder.none,
                hintText: label,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                suffixIcon: onTap != null
                    ? Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchableDropdown({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onChanged,
    required FocusNode focusNode,
    required TextEditingController searchController,
    bool isRequired = false,
  }) {
    OverlayEntry? _overlay;
    
    void _removeOverlay() {
      _overlay?.remove();
      _overlay = null;
      searchController.clear();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              focusNode.requestFocus();
              _removeOverlay();
              final box = context.findRenderObject() as RenderBox;
              final offset = box.localToGlobal(Offset.zero);
              final width = box.size.width;
              
              List<String> filteredItems = List.from(items);
              
              _overlay = OverlayEntry(
                builder: (_) => Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _removeOverlay,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    Positioned(
                      left: offset.dx,
                      top: offset.dy + 56,
                      width: width,
                      child: Material(
                        elevation: 8,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Search $label...',
                                    prefixIcon: const Icon(Icons.search, size: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (query) {
                                    filteredItems = items
                                        .where((e) => e.toLowerCase().contains(query.toLowerCase()))
                                        .toList();
                                    _overlay?.markNeedsBuild();
                                  },
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredItems.length,
                                  itemBuilder: (c, i) {
                                    final item = filteredItems[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        item,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      selected: selected == item,
                                      selectedTileColor: AppColors.primaryColor.withOpacity(0.1),
                                      onTap: () {
                                        _removeOverlay();
                                        setState(() {
                                          onChanged(item);
                                          controller.text = item;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
              Overlay.of(context).insert(_overlay!);
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: focusNode.hasFocus ? AppColors.primaryColor : Colors.grey.shade300,
                  width: focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Select $label' : controller.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: controller.text.isEmpty ? Colors.grey.shade400 : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.fabricDetail == null ? 'Add Fabric Detail' : 'Edit Fabric Detail',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchableDropdown(
                  label: 'Type',
                  controller: _typeCtrl,
                  items: _typeList,
                  selected: _selectedType,
                  onChanged: (v) => _selectedType = v,
                  focusNode: _typeFocus,
                  searchController: _typeSearchCtrl,
                  isRequired: true,
                ),
                _buildSearchableDropdown(
                  label: 'Product',
                  controller: _productCtrl,
                  items: _productList,
                  selected: _selectedProduct,
                  onChanged: (v) => _selectedProduct = v,
                  focusNode: _productFocus,
                  searchController: _productSearchCtrl,
                  isRequired: true,
                ),
                _buildSearchableDropdown(
                  label: 'Design',
                  controller: _designCtrl,
                  items: _designList,
                  selected: _selectedDesign,
                  onChanged: (v) => _selectedDesign = v,
                  focusNode: _designFocus,
                  searchController: _designSearchCtrl,
                  isRequired: true,
                ),
                _buildSearchableDropdown(
                  label: 'Shade',
                  controller: _shadeCtrl,
                  items: _shadeList,
                  selected: _selectedShade,
                  onChanged: (v) => _selectedShade = v,
                  focusNode: _shadeFocus,
                  searchController: _shadeSearchCtrl,
                ),
                _buildSearchableDropdown(
                  label: 'Brand',
                  controller: _brandCtrl,
                  items: _brandList,
                  selected: _selectedBrand,
                  onChanged: (v) => _selectedBrand = v,
                  focusNode: _brandFocus,
                  searchController: _brandSearchCtrl,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Width',
                        controller: _widthCtrl,
                        focusNode: _widthFocus,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Ratio',
                        controller: _ratioCtrl,
                        focusNode: _ratioFocus,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Req Qty',
                        controller: _reqQtyCtrl,
                        focusNode: _reqQtyFocus,
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'Wast (%)',
                        controller: _wastCtrl,
                        focusNode: _wastFocus,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: _showQtyVarDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: AppColors.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: AppColors.primaryColor),
                            ),
                          ),
                          child: Text('Change Var(%): ${_qtyVar.toStringAsFixed(2)}%'),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildTextField(
                  label: 'Actual Qty',
                  controller: _actualQtyCtrl,
                  focusNode: _actualQtyFocus,
                  readOnly: true,
                ),
                _buildTextField(
                  label: 'Description',
                  controller: _descriptionCtrl,
                  focusNode: _descriptionFocus,
                ),
                _buildTextField(
                  label: 'Remark',
                  controller: _remarkCtrl,
                  focusNode: _remarkFocus,
                ),
                
                const SizedBox(height: 20),
                
                // Bottom Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final fabricData = {
                            'type': _selectedType,
                            'product': _selectedProduct,
                            'design': _selectedDesign,
                            'shade': _selectedShade,
                            'brand': _selectedBrand,
                            'width': double.tryParse(_widthCtrl.text) ?? 0,
                            'ratio': double.tryParse(_ratioCtrl.text) ?? 0,
                            'reqQty': double.tryParse(_reqQtyCtrl.text) ?? 0,
                            'wast': double.tryParse(_wastCtrl.text) ?? 0,
                            'actualQty': double.tryParse(_actualQtyCtrl.text) ?? 0,
                            'qtyVar': _qtyVar,
                            'description': _descriptionCtrl.text,
                            'remark': _remarkCtrl.text,
                          };
                          Navigator.pop(context, fabricData);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Confirm', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}