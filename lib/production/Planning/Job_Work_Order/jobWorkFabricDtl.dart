import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/Widgets/custom_searchable_dropdown.dart';
import 'package:vrs_erp/production/Widgets/custom_text_field.dart';
import 'package:vrs_erp/services/production_services.dart';

class FabricDetailsScreenForJobWork extends StatefulWidget {
  final Map<String, dynamic>? fabricDetail;
  final int? totalPcsFromFinish;
  final Function(Map<String, dynamic>)? onFabricChanged; // Callback when fabric data changes
  
  const FabricDetailsScreenForJobWork({
    super.key, 
    this.fabricDetail, 
    this.totalPcsFromFinish,
    this.onFabricChanged,
  });

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
  final TextEditingController _wasteAmtCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  
  // ────────────────────── Selected Values ──────────────────────
  Map<String, dynamic>? _selectedType;
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedDesign;
  Map<String, dynamic>? _selectedShade;
  Map<String, dynamic>? _selectedBrand;
  
  // ────────────────────── Dropdown Lists ──────────────────────
  List<Map<String, dynamic>> _typeList = [];
  List<Map<String, dynamic>> _productList = [];
  List<Map<String, dynamic>> _designList = [];
  List<Map<String, dynamic>> _shadeList = [];
  List<Map<String, dynamic>> _brandList = [];
  
  // ────────────────────── Loading States ──────────────────────
  bool _isLoadingTypes = true;
  bool _isLoadingProducts = false;
  bool _isLoadingDesigns = false;
  bool _isLoadingShades = true;
  bool _isLoadingBrands = true;
  
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
  
  double _qtyVar = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Add listeners for calculations
    _ratioCtrl.addListener(_calculateFromRatio);
    _wastCtrl.addListener(_calculateActualQty);
    _reqQtyCtrl.addListener(_calculateFromReqQty);
    
    _loadInitialData();
    
    if (widget.fabricDetail != null) {
      _populateFormWithExistingData();
    }
    
    // If totalPcsFromFinish is provided, calculate initial req qty
    if (widget.totalPcsFromFinish != null && widget.totalPcsFromFinish! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateFromRatio();
      });
    }
  }
  
  void _calculateFromRatio() {
    double ratio = double.tryParse(_ratioCtrl.text) ?? 0;
    if (ratio > 0 && widget.totalPcsFromFinish != null && widget.totalPcsFromFinish! > 0) {
      double reqQty = widget.totalPcsFromFinish! * ratio;
      _reqQtyCtrl.text = reqQty.toStringAsFixed(3);
      _calculateActualQty();
      _notifyFabricChanged();
    } else if (ratio == 0) {
      _reqQtyCtrl.text = '0';
      _calculateActualQty();
      _notifyFabricChanged();
    }
  }
  
  void _calculateFromReqQty() {
    double reqQty = double.tryParse(_reqQtyCtrl.text) ?? 0;
    if (reqQty > 0 && widget.totalPcsFromFinish != null && widget.totalPcsFromFinish! > 0) {
      double ratio = reqQty / widget.totalPcsFromFinish!;
      _ratioCtrl.text = ratio.toStringAsFixed(5);
      _calculateActualQty();
      _notifyFabricChanged();
    }
  }
  
  void _calculateActualQty() {
    double reqQty = double.tryParse(_reqQtyCtrl.text) ?? 0;
    double wast = double.tryParse(_wastCtrl.text) ?? 0;
    
    // Calculate waste amount: (reqQty * wast) / 100
    double wasteAmount = (reqQty * wast) / 100;
    double actualQty = reqQty + wasteAmount;
    
    _wasteAmtCtrl.text = wasteAmount.toStringAsFixed(3);
    _actualQtyCtrl.text = actualQty.toStringAsFixed(3);
  }
  
  void _notifyFabricChanged() {
    if (widget.onFabricChanged != null) {
      final fabricData = {
        'ratio': double.tryParse(_ratioCtrl.text) ?? 0,
        'reqQty': double.tryParse(_reqQtyCtrl.text) ?? 0,
        'actualQty': double.tryParse(_actualQtyCtrl.text) ?? 0,
        'wast': double.tryParse(_wastCtrl.text) ?? 0,
      };
      widget.onFabricChanged!(fabricData);
    }
  }
  
  bool _validateReqQty() {
    double reqQty = double.tryParse(_reqQtyCtrl.text) ?? 0;
    if (reqQty <= 0) {
      _showErrorDialog('Invalid Quantity Specified! Please enter a valid Req Qty greater than 0.');
      return false;
    }
    return true;
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Validation Error',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadFabricTypes(),
      _loadShades(),
      _loadBrands(),
    ]);
  }
  
  Future<void> _loadFabricTypes() async {
    setState(() => _isLoadingTypes = true);
    final types = await ProductionService.getFabricTypes();
    setState(() {
      _typeList = types;
      _isLoadingTypes = false;
    });
  }
  
  Future<void> _loadFabricProducts(String itemGrpKey) async {
    setState(() => _isLoadingProducts = true);
    final products = await ProductionService.getFabricProducts(itemGrpKey);
    setState(() {
      _productList = products;
      _isLoadingProducts = false;
    });
  }
  
  Future<void> _loadDesigns(String itemKey) async {
    setState(() => _isLoadingDesigns = true);
    final designs = await ProductionService.getDesignsByItemKey(itemKey);
    setState(() {
      _designList = designs;
      _isLoadingDesigns = false;
    });
  }
  
  Future<void> _loadShades() async {
    setState(() => _isLoadingShades = true);
    final shades = await ProductionService.getShades();
    setState(() {
      _shadeList = shades;
      _isLoadingShades = false;
    });
  }
  
  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    final brands = await ProductionService.getBrands();
    setState(() {
      _brandList = brands;
      _isLoadingBrands = false;
    });
  }
  
  void _populateFormWithExistingData() {
    final data = widget.fabricDetail!;
    
    if (data['type'] != null) {
      _selectedType = {
        'key': data['typeKey'] ?? '',
        'name': data['type'],
        'type': data['typeCode'] ?? ''
      };
      _typeCtrl.text = data['type'];
    }
    
    if (data['product'] != null) {
      _selectedProduct = {
        'key': data['productKey'] ?? '',
        'name': data['product'],
      };
      _productCtrl.text = data['product'];
    }
    
    if (data['design'] != null) {
      _selectedDesign = {
        'key': data['designKey'] ?? '',
        'name': data['design'],
      };
      _designCtrl.text = data['design'];
    }
    
    if (data['shade'] != null) {
      _selectedShade = {
        'key': data['shadeKey'] ?? '',
        'name': data['shade'],
      };
      _shadeCtrl.text = data['shade'];
    }
    
    if (data['brand'] != null) {
      _selectedBrand = {
        'key': data['brandKey'] ?? '',
        'name': data['brand'],
      };
      _brandCtrl.text = data['brand'];
    }
    
    _widthCtrl.text = data['width']?.toString() ?? '';
    _ratioCtrl.text = data['ratio']?.toString() ?? '';
    _reqQtyCtrl.text = data['reqQty']?.toString() ?? '';
    _wastCtrl.text = data['wast']?.toString() ?? '';
    _actualQtyCtrl.text = data['actualQty']?.toString() ?? '';
    _descriptionCtrl.text = data['description'] ?? '';
    _remarkCtrl.text = data['remark'] ?? '';
    _qtyVar = data['qtyVar'] ?? 0;
    
    // Calculate waste amount for existing data
    _calculateActualQty();
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
    _wasteAmtCtrl.dispose();
    _descriptionCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
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
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
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
                      CustomSearchableDropdown(
                        label: 'Type',
                        controller: _typeCtrl,
                        items: _typeList,
                        selected: _selectedType,
                        onChanged: (v) async {
                          setState(() {
                            _selectedType = v;
                            _selectedProduct = null;
                            _productCtrl.clear();
                            _selectedDesign = null;
                            _designCtrl.clear();
                          });
                          if (v != null) {
                            await _loadFabricProducts(v['key']);
                          }
                        },
                        focusNode: _typeFocus,
                        isRequired: true,
                        isLoading: _isLoadingTypes,
                        showClearButton: true,
                      ),
                      CustomSearchableDropdown(
                        label: 'Product',
                        controller: _productCtrl,
                        items: _productList,
                        selected: _selectedProduct,
                        onChanged: (v) async {
                          setState(() {
                            _selectedProduct = v;
                            _selectedDesign = null;
                            _designCtrl.clear();
                          });
                          if (v != null) {
                            await _loadDesigns(v['key']);
                          }
                        },
                        focusNode: _productFocus,
                        isRequired: true,
                        isLoading: _isLoadingProducts,
                        showClearButton: true,
                      ),
                      CustomSearchableDropdown(
                        label: 'Design',
                        controller: _designCtrl,
                        items: _designList,
                        selected: _selectedDesign,
                        onChanged: (v) => setState(() => _selectedDesign = v),
                        focusNode: _designFocus,
                        isRequired: true,
                        isLoading: _isLoadingDesigns,
                        showClearButton: true,
                      ),
                      CustomSearchableDropdown(
                        label: 'Shade',
                        controller: _shadeCtrl,
                        items: _shadeList,
                        selected: _selectedShade,
                        onChanged: (v) => setState(() => _selectedShade = v),
                        focusNode: _shadeFocus,
                        isLoading: _isLoadingShades,
                        showClearButton: true,
                      ),
                      CustomSearchableDropdown(
                        label: 'Brand',
                        controller: _brandCtrl,
                        items: _brandList,
                        selected: _selectedBrand,
                        onChanged: (v) => setState(() => _selectedBrand = v),
                        focusNode: _brandFocus,
                        isLoading: _isLoadingBrands,
                        showClearButton: true,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Width',
                              controller: _widthCtrl,
                              focusNode: _widthFocus,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
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
                            child: CustomTextField(
                              label: 'Req Qty',
                              controller: _reqQtyCtrl,
                              focusNode: _reqQtyFocus,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Wast (%)',
                              controller: _wastCtrl,
                              focusNode: _wastFocus,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      // Waste Amount Field (Read-only)
                      CustomTextField(
                        label: 'Waste Amt',
                        controller: _wasteAmtCtrl,
                        focusNode: FocusNode(),
                        readOnly: true,
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
                      CustomTextField(
                        label: 'Actual Qty',
                        controller: _actualQtyCtrl,
                        focusNode: _actualQtyFocus,
                        readOnly: true,
                      ),
                      CustomTextField(
                        label: 'Description',
                        controller: _descriptionCtrl,
                        focusNode: _descriptionFocus,
                        maxLines: 3,
                      ),
                      CustomTextField(
                        label: 'Remark',
                        controller: _remarkCtrl,
                        focusNode: _remarkFocus,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Fixed Bottom Buttons with SafeArea
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate Req Qty before saving
                        if (!_validateReqQty()) {
                          return;
                        }
                        
                        final fabricData = {
                          'type': _selectedType?['name'],
                          'typeKey': _selectedType?['key'],
                          'typeCode': _selectedType?['type'],
                          'product': _selectedProduct?['name'],
                          'productKey': _selectedProduct?['key'],
                          'design': _selectedDesign?['name'],
                          'designKey': _selectedDesign?['key'],
                          'shade': _selectedShade?['name'],
                          'shadeKey': _selectedShade?['key'],
                          'brand': _selectedBrand?['name'],
                          'brandKey': _selectedBrand?['key'],
                          'width': double.tryParse(_widthCtrl.text) ?? 0,
                          'ratio': double.tryParse(_ratioCtrl.text) ?? 0,
                          'reqQty': double.tryParse(_reqQtyCtrl.text) ?? 0,
                          'wast': double.tryParse(_wastCtrl.text) ?? 0,
                          'wasteAmt': double.tryParse(_wasteAmtCtrl.text) ?? 0,
                          'actualQty': double.tryParse(_actualQtyCtrl.text) ?? 0,
                          'qtyVar': _qtyVar,
                          'description': _descriptionCtrl.text,
                          'remark': _remarkCtrl.text,
                        };
                        Navigator.pop(context, fabricData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}