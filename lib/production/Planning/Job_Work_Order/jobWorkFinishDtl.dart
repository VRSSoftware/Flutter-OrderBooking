import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/Widgets/custom_searchable_dropdown.dart';
import 'package:vrs_erp/production/Widgets/custom_text_field.dart';
import 'package:vrs_erp/services/production_services.dart';
import 'package:vrs_erp/production/Planning/Job_Work_Order/jobWorkFabricDtl.dart';

class FinishDetailScreenForJobWork extends StatefulWidget {
  final Map<String, dynamic>? finishDetail;

  const FinishDetailScreenForJobWork({super.key, this.finishDetail});

  @override
  State<FinishDetailScreenForJobWork> createState() =>
      _FinishDetailScreenForJobWorkState();
}

class _FinishDetailScreenForJobWorkState
    extends State<FinishDetailScreenForJobWork>
    with SingleTickerProviderStateMixin {
  // ────────────────────── Controllers ──────────────────────
  final TextEditingController _productCtrl = TextEditingController();
  final TextEditingController _designNoCtrl = TextEditingController();
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _shadeCtrl = TextEditingController();
  final TextEditingController _totalPcsCtrl = TextEditingController();
  final TextEditingController _avgRatioCtrl = TextEditingController();
  final TextEditingController _cutMtrCtrl = TextEditingController();
  final TextEditingController _orderNoCtrl = TextEditingController();
  final TextEditingController _merchandiserCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _jobRateCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController(text: '0.00');
  final TextEditingController _qtyValPercCtrl = TextEditingController();

  // ────────────────────── Selected Values ──────────────────────
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedDesign;
  Map<String, dynamic>? _selectedShade;
  Map<String, dynamic>? _selectedOrderNo;
  Map<String, dynamic>? _selectedMerchandiser;

  // ────────────────────── Dynamic Lists ──────────────────────
  List<Map<String, dynamic>> _productList = [];
  List<Map<String, dynamic>> _designNoList = [];
  List<Map<String, dynamic>> _shadeList = [];
  List<Map<String, dynamic>> _orderNoList = [];
  List<Map<String, dynamic>> _merchandiserList = [];
  List<Map<String, dynamic>> _sizeList = [];

  // ────────────────────── Loading States ──────────────────────
  bool _isLoadingProducts = false;
  bool _isLoadingDesigns = false;
  bool _isLoadingShades = false;
  bool _isLoadingOrders = false;
  bool _isLoadingMerchandisers = false;
  bool _isLoadingSizes = false;

  // ────────────────────── Size Details ──────────────────────
  final Map<String, Map<String, dynamic>> _sizeDetails = {};
  int _totalPcs = 0;
  bool _sizeAdded = false;

  // ────────────────────── Fabrics List ──────────────────────
  List<Map<String, dynamic>> _fabricsList = [];

  // ────────────────────── Focus Nodes ──────────────────────
  final FocusNode _productFocus = FocusNode();
  final FocusNode _designNoFocus = FocusNode();
  final FocusNode _typeFocus = FocusNode();
  final FocusNode _shadeFocus = FocusNode();
  final FocusNode _totalPcsFocus = FocusNode();
  final FocusNode _avgRatioFocus = FocusNode();
  final FocusNode _cutMtrFocus = FocusNode();
  final FocusNode _orderNoFocus = FocusNode();
  final FocusNode _merchandiserFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _jobRateFocus = FocusNode();
  final FocusNode _qtyValPercFocus = FocusNode();

  // ────────────────────── Animation ──────────────────────
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _animCtrl.forward();

    // Add listeners for calculations
    _jobRateCtrl.addListener(_calculateAmount);
    _totalPcsCtrl.addListener(_calculateAmount);
    _qtyValPercCtrl.addListener(_calculateAmount);

    // Load all dropdown data
    _loadProducts();
    _loadOrders();
    _loadMerchandisers();

    // If editing, populate data
    if (widget.finishDetail != null) {
      _populateFormWithExistingData();
    }
  }

  // ────────────────────── API Methods ──────────────────────
  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    _productList = await ProductionService.getProducts();
    setState(() => _isLoadingProducts = false);
  }

  Future<void> _loadDesigns(String itemKey) async {
    setState(() => _isLoadingDesigns = true);
    _designNoList = await ProductionService.getDesignsByItemKey(itemKey);
    setState(() => _isLoadingDesigns = false);
  }

  Future<void> _loadShades(String styleKey) async {
    setState(() => _isLoadingShades = true);
    _shadeList = await ProductionService.getStyleShades(styleKey);
    setState(() => _isLoadingShades = false);
  }

  Future<void> _loadSizes(String styleKey) async {
    setState(() => _isLoadingSizes = true);
    _sizeList = await ProductionService.getStyleSizes(styleKey);
    setState(() => _isLoadingSizes = false);
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    _orderNoList = await ProductionService.getOrderNos();
    setState(() => _isLoadingOrders = false);
  }

  Future<void> _loadMerchandisers() async {
    setState(() => _isLoadingMerchandisers = true);
    _merchandiserList = await ProductionService.getMerchandisers();
    setState(() => _isLoadingMerchandisers = false);
  }

  void _populateFormWithExistingData() {
    final data = widget.finishDetail!;

    if (data['product'] != null) {
      _selectedProduct = {
        'key': data['productKey'] ?? '',
        'name': data['product'],
      };
      _productCtrl.text = data['product'];
    }

    if (data['designNo'] != null) {
      _selectedDesign = {
        'key': data['designKey'] ?? '',
        'name': data['designNo'],
        'typeName': data['type'] ?? '',
      };
      _designNoCtrl.text = data['designNo'];
    }

    _selectedShade =
        data['shade'] != null ? {'key': '', 'name': data['shade']} : null;
    _shadeCtrl.text = data['shade'] ?? '';

    _selectedOrderNo =
        data['orderNo'] != null ? {'key': '', 'name': data['orderNo']} : null;
    _orderNoCtrl.text = data['orderNo'] ?? '';

    _selectedMerchandiser =
        data['merchandiser'] != null
            ? {'key': '', 'name': data['merchandiser']}
            : null;
    _merchandiserCtrl.text = data['merchandiser'] ?? '';

    _typeCtrl.text = data['type'] ?? '';
    _descriptionCtrl.text = data['description'] ?? '';
    _jobRateCtrl.text = data['jobRate']?.toString() ?? '';
    _qtyValPercCtrl.text = data['qtyValPerc']?.toString() ?? '';

    // Load fabrics if exist
    if (data['fabrics'] != null) {
      _fabricsList = List<Map<String, dynamic>>.from(data['fabrics']);
    }

    // Load size details
    if (data['sizeDetails'] != null) {
      final sizeMap = data['sizeDetails'] as Map<String, dynamic>;
      sizeMap.forEach((key, value) {
        _sizeDetails[key] = Map<String, dynamic>.from(value);
      });
      _totalPcs = _calculateTotalFromSize();
      _sizeAdded = _totalPcs > 0;
      _totalPcsCtrl.text = _totalPcs.toString();

      // Calculate totals from fabrics if they exist
      if (_fabricsList.isNotEmpty) {
        _updateFinishTotals();
      }
    } else if (data['totalPcs'] != null && data['totalPcs'] > 0) {
      // For backward compatibility
      _totalPcs = data['totalPcs'];
      _sizeAdded = true;
      _totalPcsCtrl.text = _totalPcs.toString();
      if (_fabricsList.isNotEmpty) {
        _updateFinishTotals();
      }
    }

    _calculateAmount();
  }

  void _updateFinishTotals() {
    double totalRatio = 0;
    double totalReqQty = 0;

    for (var fabric in _fabricsList) {
      totalRatio += fabric['ratio'] as double? ?? 0;
      totalReqQty += fabric['reqQty'] as double? ?? 0;
    }

    _avgRatioCtrl.text = totalRatio.toStringAsFixed(5);
    _cutMtrCtrl.text = totalReqQty.toStringAsFixed(3);
  }

  void _calculateAmount() {
    double jobRate = double.tryParse(_jobRateCtrl.text) ?? 0;
    int totalPcs = int.tryParse(_totalPcsCtrl.text) ?? 0;
    double qtyValPerc = double.tryParse(_qtyValPercCtrl.text) ?? 0;

    double amount = jobRate * totalPcs;
    if (qtyValPerc > 0) {
      amount = amount * (qtyValPerc / 100);
    }

    _amountCtrl.text = amount.toStringAsFixed(2);
  }

  int _calculateTotalFromSize() {
    int total = 0;
    for (var size in _sizeDetails.values) {
      total += size['aQty'] as int? ?? 0;
    }
    return total;
  }

  // ────────────────────── Fabric Methods ──────────────────────
  void _addFabric() async {
    // Check if quantity is added first
    if (!_sizeAdded || _totalPcs <= 0) {
      _showErrorDialog('Please add quantity first before adding fabrics');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                FabricDetailsScreenForJobWork(totalPcsFromFinish: _totalPcs),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _fabricsList.add(result);
        _updateFinishTotals();
      });
    }
  }

  void _editFabric(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FabricDetailsScreenForJobWork(
              fabricDetail: _fabricsList[index],
              totalPcsFromFinish: _totalPcs,
            ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _fabricsList[index] = result;
        _updateFinishTotals();
      });
    }
  }

  void _deleteFabric(int index) {
    setState(() {
      _fabricsList.removeAt(index);
      _updateFinishTotals();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.red)),
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

  // ────────────────────── Validation Methods ──────────────────────
  bool _validateShadeBeforeAddQty() {
    if (_selectedShade == null || _shadeCtrl.text.isEmpty) {
      _showErrorDialog('Invalid Shade Specified!');
      return false;
    }
    return true;
  }

  // ────────────────────── Size Bottom Sheet ──────────────────────
  void _showSizeBottomSheet() async {
    // Validate shade before adding quantity
    if (!_validateShadeBeforeAddQty()) {
      return;
    }

    // If sizes are not loaded yet, load them first
    if (_sizeList.isEmpty && _selectedDesign != null) {
      await _loadSizes(_selectedDesign!['key']);
    }

    // Initialize size details from API if empty
    if (_sizeDetails.isEmpty && _sizeList.isNotEmpty) {
      for (var size in _sizeList) {
        final sizeName = size['name'];
        if (!_sizeDetails.containsKey(sizeName)) {
          _sizeDetails[sizeName] = {'aQty': 0, 'oQty': 0};
        }
      }
    }

    final Map<String, TextEditingController> controllers = {};

    for (var size in _sizeDetails.keys) {
      controllers['$size-aQty'] = TextEditingController(
        text: _sizeDetails[size]!['aQty'].toString(),
      );
      controllers['$size-oQty'] = TextEditingController(
        text: _sizeDetails[size]!['oQty'].toString(),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              int currentTotal = _sizeDetails.values
                  .map((e) => e['aQty'] as int)
                  .fold(0, (a, b) => a + b);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add Quantity by Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child:
                              _isLoadingSizes
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : _sizeList.isEmpty
                                  ? const Center(
                                    child: Text(
                                      'No sizes available for this design',
                                    ),
                                  )
                                  : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Table(
                                        border: TableBorder.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                        columnWidths: const {
                                          0: FixedColumnWidth(80),
                                          1: FixedColumnWidth(120),
                                          2: FixedColumnWidth(120),
                                        },
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.1),
                                            ),
                                            children: [
                                              _headerCell('Size'),
                                              _headerCell('A.Qty'),
                                              _headerCell('O.Qty'),
                                            ],
                                          ),
                                          ..._sizeDetails.keys.map((size) {
                                            return TableRow(
                                              children: [
                                                _cell(size),
                                                _editableCellInSheet(
                                                  controller:
                                                      controllers['$size-aQty']!,
                                                  onChanged: (value) {
                                                    _sizeDetails[size]!['aQty'] =
                                                        int.tryParse(value) ??
                                                        0;
                                                    currentTotal = _sizeDetails
                                                        .values
                                                        .map(
                                                          (e) =>
                                                              e['aQty'] as int,
                                                        )
                                                        .fold(
                                                          0,
                                                          (a, b) => a + b,
                                                        );
                                                    setSheetState(() {});
                                                  },
                                                ),
                                                _editableCellInSheet(
                                                  controller:
                                                      controllers['$size-oQty']!,
                                                  onChanged: (value) {
                                                    _sizeDetails[size]!['oQty'] =
                                                        int.tryParse(value) ??
                                                        0;
                                                    setSheetState(() {});
                                                  },
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          border: Border.all(color: AppColors.primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pcs:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Text(
                              '$currentTotal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _totalPcs = currentTotal;
                              _sizeAdded = _totalPcs > 0;
                              _totalPcsCtrl.text = _totalPcs.toString();
                              _calculateAmount();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _headerCell(String txt) => Container(
    padding: const EdgeInsets.all(10),
    child: Text(
      txt,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: AppColors.primaryColor,
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _cell(String txt) => Container(
    padding: const EdgeInsets.all(10),
    child: Text(
      txt,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
      ),
      textAlign: TextAlign.center,
    ),
  );

  Widget _editableCellInSheet({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 6,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 1.5,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  void _showQtyValDialog() {
    final TextEditingController qtyValController = TextEditingController(
      text: _qtyValPercCtrl.text,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Qty Var (%)'),
            content: TextField(
              controller: qtyValController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Qty Var (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                    _qtyValPercCtrl.text = qtyValController.text;
                    _calculateAmount();
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            widget.finishDetail != null
                ? 'Edit Finish Detail'
                : 'Add Finish Detail',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomSearchableDropdown(
                          label: 'Product',
                          controller: _productCtrl,
                          items: _productList,
                          selected: _selectedProduct,
                          onChanged: (v) async {
                            setState(() {
                              _selectedProduct = v;
                              _selectedDesign = null;
                              _designNoCtrl.clear();
                            });
                            if (v != null) {
                              await _loadDesigns(v['key']);
                            }
                          },
                          focusNode: _productFocus,
                          isRequired: true,
                          isLoading: _isLoadingProducts,
                          showClearButton: true,
                          allowClear: true,
                        ),
                        CustomSearchableDropdown(
                          label: 'Design No',
                          controller: _designNoCtrl,
                          items: _designNoList,
                          selected: _selectedDesign,
                          onChanged: (v) {
                            setState(() {
                              _selectedDesign = v;
                              if (v != null) {
                                _typeCtrl.text = v['typeName'] ?? '';
                                _loadShades(v['key']);
                                _loadSizes(v['key']);
                              }
                            });
                          },
                          focusNode: _designNoFocus,
                          isRequired: true,
                          isLoading: _isLoadingDesigns,
                          showClearButton: true,
                          allowClear: true,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Type',
                                controller: _typeCtrl,
                                focusNode: _typeFocus,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomSearchableDropdown(
                                label: 'Shade',
                                controller: _shadeCtrl,
                                items: _shadeList,
                                selected: _selectedShade,
                                onChanged:
                                    (v) => setState(() => _selectedShade = v),
                                focusNode: _shadeFocus,
                                isLoading: _isLoadingShades,
                                showClearButton: true,
                                allowClear: true,
                              ),
                            ),
                          ],
                        ),
                        // Quantity Section - Must be added first
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUANTITY DETAILS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      label: 'Total PCS',
                                      controller: _totalPcsCtrl,
                                      focusNode: _totalPcsFocus,
                                      keyboardType: TextInputType.number,
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _showSizeBottomSheet,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _sizeAdded
                                                ? Colors.green.shade50
                                                : AppColors.primaryColor,
                                        foregroundColor:
                                            _sizeAdded
                                                ? Colors.green
                                                : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side:
                                              _sizeAdded
                                                  ? BorderSide(
                                                    color: Colors.green,
                                                  )
                                                  : BorderSide.none,
                                        ),
                                      ),
                                      child: Text(
                                        _sizeAdded ? 'Qty Added ✓' : 'Add Qty',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!_sizeAdded)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 12,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Please select shade first, then add quantity',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Avg Ratio and Cut Mtr (only shown after fabrics are added)
                        if (_fabricsList.isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Avg Ratio',
                                  controller: _avgRatioCtrl,
                                  focusNode: _avgRatioFocus,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Cut Mtr',
                                  controller: _cutMtrCtrl,
                                  focusNode: _cutMtrFocus,
                                  keyboardType: TextInputType.number,
                                  readOnly: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        CustomSearchableDropdown(
                          label: 'Order No',
                          controller: _orderNoCtrl,
                          items: _orderNoList,
                          selected: _selectedOrderNo,
                          onChanged:
                              (v) => setState(() => _selectedOrderNo = v),
                          focusNode: _orderNoFocus,
                          isLoading: _isLoadingOrders,
                          showClearButton: true,
                          allowClear: true,
                        ),
                        CustomSearchableDropdown(
                          label: 'Merchandiser',
                          controller: _merchandiserCtrl,
                          items: _merchandiserList,
                          selected: _selectedMerchandiser,
                          onChanged:
                              (v) => setState(() => _selectedMerchandiser = v),
                          focusNode: _merchandiserFocus,
                          isLoading: _isLoadingMerchandisers,
                          showClearButton: true,
                          allowClear: true,
                        ),
                        CustomTextField(
                          label: 'Description',
                          controller: _descriptionCtrl,
                          focusNode: _descriptionFocus,
                          maxLines: 3,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Job Rate',
                                controller: _jobRateCtrl,
                                focusNode: _jobRateFocus,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Amount',
                                controller: _amountCtrl,
                                focusNode: FocusNode(),
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Qty Val (%)',
                                controller: _qtyValPercCtrl,
                                focusNode: _qtyValPercFocus,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showQtyValDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: AppColors.primaryColor,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: AppColors.primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Change Var(%)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Fabrics Section - Only enabled after quantity is added
                        Container(
                          decoration: BoxDecoration(
                            color:
                                _sizeAdded
                                    ? Colors.grey.shade50
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _sizeAdded
                                      ? Colors.grey.shade200
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'FABRICS',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                        if (_fabricsList.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${_fabricsList.length}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (_sizeAdded)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: AppColors.primaryColor,
                                        ),
                                        onPressed: _addFabric,
                                      ),
                                  ],
                                ),
                              ),
                              if (!_sizeAdded)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Add quantity first to add fabrics',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (_fabricsList.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.inbox,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No fabrics added',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap + to add fabric',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _fabricsList.length,
                                  itemBuilder: (context, index) {
                                    final fabric = _fabricsList[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  fabric['product'] ??
                                                      'Product',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    _buildFabricChip(
                                                      'Ratio',
                                                      (fabric['ratio'] ?? 0)
                                                          .toStringAsFixed(5),
                                                      Colors.orange,
                                                    ),
                                                    _buildFabricChip(
                                                      'Req',
                                                      (fabric['reqQty'] ?? 0)
                                                          .toStringAsFixed(3),
                                                      Colors.blue,
                                                    ),
                                                    _buildFabricChip(
                                                      'Actual',
                                                      (fabric['actualQty'] ?? 0)
                                                          .toStringAsFixed(3),
                                                      Colors.green,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                onPressed:
                                                    () => _editFabric(index),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    () => _deleteFabric(index),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFabricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
            ),
            onPressed:
                _sizeAdded
                    ? () {
                      final finishData = {
                        'product': _selectedProduct?['name'],
                        'productKey': _selectedProduct?['key'],
                        'designNo': _selectedDesign?['name'],
                        'designKey': _selectedDesign?['key'],
                        'type': _typeCtrl.text,
                        'shade': _selectedShade?['name'],
                        'shadeKey': _selectedShade?['key'],
                        'totalPcs': int.tryParse(_totalPcsCtrl.text) ?? 0,
                        'avgRatio': double.tryParse(_avgRatioCtrl.text) ?? 0,
                        'cutMtr': double.tryParse(_cutMtrCtrl.text) ?? 0,
                        'orderNo': _selectedOrderNo?['name'],
                        'orderNoKey': _selectedOrderNo?['key'],
                        'merchandiser': _selectedMerchandiser?['name'],
                        'merchandiserKey': _selectedMerchandiser?['key'],
                        'description': _descriptionCtrl.text,
                        'jobRate': double.tryParse(_jobRateCtrl.text) ?? 0,
                        'amount': double.tryParse(_amountCtrl.text) ?? 0,
                        'qtyValPerc':
                            double.tryParse(_qtyValPercCtrl.text) ?? 0,
                        'sizeDetails': _sizeDetails,
                        'fabrics': _fabricsList,
                      };
                      Navigator.pop(context, finishData);
                    }
                    : null,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
