import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

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
  String? _selectedProduct;
  String? _selectedDesignNo;
  String? _selectedType;
  String? _selectedShade;
  String? _selectedOrderNo;
  String? _selectedMerchandiser;

  // ────────────────────── Dropdown Lists ──────────────────────
  final List<String> _productList = [
    'Product A',
    'Product B',
    'Product C',
    'Product D',
  ];
  final List<String> _designNoList = ['DES001', 'DES002', 'DES003', 'DES004'];
  final List<String> _typeList = ['Cotton', 'Polyester', 'Denim', 'Linen'];
  final List<String> _shadeList = ['White', 'Black', 'Blue', 'Red', 'Green'];
  final List<String> _orderNoList = ['ORD001', 'ORD002', 'ORD003', 'ORD004'];
  final List<String> _merchandiserList = ['Merch A', 'Merch B', 'Merch C'];

  // ────────────────────── Size Details ──────────────────────
  final Map<String, Map<String, dynamic>> _sizeDetails = {
    'S': {'aQty': 0, 'oQty': 0},
    'M': {'aQty': 0, 'oQty': 0},
    'L': {'aQty': 0, 'oQty': 0},
    'XL': {'aQty': 0, 'oQty': 0},
    '2XL': {'aQty': 0, 'oQty': 0},
    '3XL': {'aQty': 0, 'oQty': 0},
    '4XL': {'aQty': 0, 'oQty': 0},
    '5XL': {'aQty': 0, 'oQty': 0},
  };

  int _totalPcs = 0;
  bool _sizeAdded = false;

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

  // ────────────────────── Search Controllers ──────────────────────
  final TextEditingController _productSearchCtrl = TextEditingController();
  final TextEditingController _designNoSearchCtrl = TextEditingController();
  final TextEditingController _typeSearchCtrl = TextEditingController();
  final TextEditingController _shadeSearchCtrl = TextEditingController();
  final TextEditingController _orderNoSearchCtrl = TextEditingController();
  final TextEditingController _merchandiserSearchCtrl = TextEditingController();

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

    // If editing, populate data
    if (widget.finishDetail != null) {
      _populateFormWithExistingData();
    }
  }

  void _populateFormWithExistingData() {
    final data = widget.finishDetail!;
    _selectedProduct = data['product'];
    _productCtrl.text = _selectedProduct ?? '';
    _selectedDesignNo = data['designNo'];
    _designNoCtrl.text = _selectedDesignNo ?? '';
    _selectedType = data['type'];
    _typeCtrl.text = _selectedType ?? '';
    _selectedShade = data['shade'];
    _shadeCtrl.text = _selectedShade ?? '';
    _totalPcsCtrl.text = data['totalPcs']?.toString() ?? '';
    _avgRatioCtrl.text = data['avgRatio']?.toString() ?? '';
    _cutMtrCtrl.text = data['cutMtr']?.toString() ?? '';
    _selectedOrderNo = data['orderNo'];
    _orderNoCtrl.text = _selectedOrderNo ?? '';
    _selectedMerchandiser = data['merchandiser'];
    _merchandiserCtrl.text = _selectedMerchandiser ?? '';
    _descriptionCtrl.text = data['description'] ?? '';
    _jobRateCtrl.text = data['jobRate']?.toString() ?? '';
    _qtyValPercCtrl.text = data['qtyValPerc']?.toString() ?? '';

    if (data['sizeDetails'] != null) {
      final sizeMap = data['sizeDetails'] as Map<String, dynamic>;
      sizeMap.forEach((key, value) {
        if (_sizeDetails.containsKey(key)) {
          _sizeDetails[key] = Map<String, dynamic>.from(value);
        }
      });
      _totalPcs = _calculateTotalFromSize();
      _sizeAdded = _totalPcs > 0;
      _totalPcsCtrl.text = _totalPcs.toString();
    }

    _calculateAmount();
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

  @override
  void dispose() {
    _animCtrl.dispose();
    _productCtrl.dispose();
    _designNoCtrl.dispose();
    _typeCtrl.dispose();
    _shadeCtrl.dispose();
    _totalPcsCtrl.dispose();
    _avgRatioCtrl.dispose();
    _cutMtrCtrl.dispose();
    _orderNoCtrl.dispose();
    _merchandiserCtrl.dispose();
    _descriptionCtrl.dispose();
    _jobRateCtrl.dispose();
    _amountCtrl.dispose();
    _qtyValPercCtrl.dispose();
    _productSearchCtrl.dispose();
    _designNoSearchCtrl.dispose();
    _typeSearchCtrl.dispose();
    _shadeSearchCtrl.dispose();
    _orderNoSearchCtrl.dispose();
    _merchandiserSearchCtrl.dispose();
    super.dispose();
  }

  // ────────────────────── Reusable TextField ──────────────────────
  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    FocusNode focusNode, {
    TextInputType? keyboard,
    VoidCallback? onTap,
    bool isDate = false,
    bool readOnly = false,
    bool isRequired = false,
  }) {
    final bool isInteractive = onTap != null || readOnly;

    return SizedBox(
      height: 56,
      child: GestureDetector(
        onTap:
            isInteractive
                ? () {
                  focusNode.requestFocus();
                  onTap?.call();
                }
                : () => focusNode.requestFocus(),
        child: AbsorbPointer(
          absorbing: isInteractive,
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            keyboardType: keyboard,
            readOnly: isInteractive,
            enabled: true,
            maxLines: isDate ? 1 : null,
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 221, 220, 220),
                  width: 1,
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              suffixIcon:
                  onTap != null
                      ? Icon(
                        isDate ? Icons.calendar_today : Icons.arrow_drop_down,
                        size: 20,
                        color: Colors.grey,
                      )
                      : null,
            ),
            style: const TextStyle(
              fontSize: 18,
              color: Color.fromARGB(255, 94, 93, 93),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────── Reusable Dropdown ──────────────────────
  Widget _buildDropdown({
    required String label,
    required TextEditingController ctrl,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onChanged,
    required FocusNode focusNode,
    bool allowAdd = true,
    bool isRequired = false,
  }) {
    OverlayEntry? _overlay;

    void _removeOverlay() {
      _overlay?.remove();
      _overlay = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildTextField(
          label,
          ctrl,
          focusNode,
          onTap: () {
            focusNode.requestFocus();
            _removeOverlay();
            final box = context.findRenderObject() as RenderBox;
            final offset = box.localToGlobal(Offset.zero);
            final width = box.size.width;

            final filtered = List<String>.from(items);
            final searchCtrl = TextEditingController();

            _overlay = OverlayEntry(
              builder:
                  (_) => Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _removeOverlay,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      Positioned(
                        left: offset.dx,
                        top: offset.dy + box.size.height,
                        width: width,
                        child: Material(
                          elevation: 4,
                          color: Colors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: searchCtrl,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Search…',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onChanged: (q) {
                                    filtered.clear();
                                    if (q.isEmpty) {
                                      filtered.addAll(items);
                                    } else {
                                      filtered.addAll(
                                        items.where(
                                          (e) => e.toLowerCase().contains(
                                            q.toLowerCase(),
                                          ),
                                        ),
                                      );
                                    }
                                    _overlay?.markNeedsBuild();
                                  },
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount:
                                      filtered.length + (allowAdd ? 1 : 0),
                                  itemBuilder: (c, i) {
                                    if (allowAdd && i == filtered.length) {
                                      return ListTile(
                                        leading: const Icon(
                                          Icons.add,
                                          color: AppColors.primaryColor,
                                        ),
                                        title: const Text(
                                          'Add New…',
                                          style: TextStyle(
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                        onTap: () {
                                          _removeOverlay();
                                          _showAddDialog(label, items, (
                                            newItem,
                                          ) {
                                            setState(() {
                                              items.add(newItem);
                                              onChanged(newItem);
                                              ctrl.text = newItem;
                                            });
                                          });
                                        },
                                      );
                                    }
                                    final item = filtered[i];
                                    return ListTile(
                                      title: Text(item),
                                      selected: selected == item,
                                      selectedTileColor: AppColors.primaryColor
                                          .withOpacity(0.1),
                                      onTap: () {
                                        _removeOverlay();
                                        setState(() {
                                          onChanged(item);
                                          ctrl.text = item;
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
                    ],
                  ),
            );
            Overlay.of(context).insert(_overlay!);
          },
        );
      },
    );
  }

  void _showAddDialog(String field, List<String> list, Function(String) onAdd) {
    final addCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Add New $field'),
            content: TextField(
              controller: addCtrl,
              decoration: InputDecoration(hintText: 'Enter $field'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final v = addCtrl.text.trim();
                  if (v.isNotEmpty && !list.contains(v)) onAdd(v);
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  // ────────────────────── Size Bottom Sheet ──────────────────────
  void _showSizeBottomSheet() {
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 400),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Table(
                                border: TableBorder.all(
                                  color: Colors.grey.shade300,
                                ),
                                columnWidths: const {
                                  0: FixedColumnWidth(60),
                                  1: FixedColumnWidth(100),
                                  2: FixedColumnWidth(100),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
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
                                                int.tryParse(value) ?? 0;
                                            currentTotal = _sizeDetails.values
                                                .map((e) => e['aQty'] as int)
                                                .fold(0, (a, b) => a + b);
                                            setSheetState(() {});
                                          },
                                        ),
                                        _editableCellInSheet(
                                          controller:
                                              controllers['$size-oQty']!,
                                          onChanged: (value) {
                                            _sizeDetails[size]!['oQty'] =
                                                int.tryParse(value) ?? 0;
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
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pcs:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // In the Size Bottom Sheet, update the Done button onPressed:
                          onPressed: () {
                            setState(() {
                              _totalPcs = currentTotal;
                              _sizeAdded = _totalPcs > 0;
                              _totalPcsCtrl.text = _totalPcs.toString();
                              _calculateAmount();
                            });

                            // Create the finish data to return
                            final finishData = {
                              'product': _selectedProduct,
                              'designNo': _selectedDesignNo,
                              'type': _selectedType,
                              'shade': _selectedShade,
                              'totalPcs': int.tryParse(_totalPcsCtrl.text) ?? 0,
                              'avgRatio': _avgRatioCtrl.text,
                              'cutMtr': _cutMtrCtrl.text,
                              'orderNo': _selectedOrderNo,
                              'merchandiser': _selectedMerchandiser,
                              'description': _descriptionCtrl.text,
                              'jobRate':
                                  double.tryParse(_jobRateCtrl.text) ?? 0,
                              'amount': double.tryParse(_amountCtrl.text) ?? 0,
                              'qtyValPerc':
                                  double.tryParse(_qtyValPercCtrl.text) ?? 0,
                              'sizeDetails': _sizeDetails,
                            };

                            Navigator.pop(context, finishData);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(fontSize: 16),
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

  Widget _headerCell(String txt) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      txt,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );

  Widget _cell(String txt) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      txt,
      style: const TextStyle(fontSize: 12),
      textAlign: TextAlign.center,
    ),
  );

  Widget _editableCellInSheet({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
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
                    _qtyValPercCtrl.text = qtyValController.text;
                    _calculateAmount();
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
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    behavior: HitTestBehavior.translucent,
    child: Scaffold(
      backgroundColor: Colors.white,
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
              // ─── Scrollable Form Content ───
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Main Form ───
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildDropdown(
                              label: 'Product',
                              ctrl: _productCtrl,
                              items: _productList,
                              selected: _selectedProduct,
                              onChanged: (v) => _selectedProduct = v,
                              focusNode: _productFocus,
                              isRequired: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              label: 'Design No',
                              ctrl: _designNoCtrl,
                              items: _designNoList,
                              selected: _selectedDesignNo,
                              onChanged: (v) => _selectedDesignNo = v,
                              focusNode: _designNoFocus,
                              isRequired: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              label: 'Type',
                              ctrl: _typeCtrl,
                              items: _typeList,
                              selected: _selectedType,
                              onChanged: (v) => _selectedType = v,
                              focusNode: _typeFocus,
                            ),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              label: 'Shade',
                              ctrl: _shadeCtrl,
                              items: _shadeList,
                              selected: _selectedShade,
                              onChanged: (v) => _selectedShade = v,
                              focusNode: _shadeFocus,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              'Total PCS',
                              _totalPcsCtrl,
                              _totalPcsFocus,
                              keyboard: TextInputType.number,
                              readOnly: _sizeAdded,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Avg Ratio',
                                    _avgRatioCtrl,
                                    _avgRatioFocus,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                    'Cut Mtr',
                                    _cutMtrCtrl,
                                    _cutMtrFocus,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              label: 'Order No',
                              ctrl: _orderNoCtrl,
                              items: _orderNoList,
                              selected: _selectedOrderNo,
                              onChanged: (v) => _selectedOrderNo = v,
                              focusNode: _orderNoFocus,
                            ),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              label: 'Merchandiser',
                              ctrl: _merchandiserCtrl,
                              items: _merchandiserList,
                              selected: _selectedMerchandiser,
                              onChanged: (v) => _selectedMerchandiser = v,
                              focusNode: _merchandiserFocus,
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              'Description',
                              _descriptionCtrl,
                              _descriptionFocus,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Job Rate',
                                    _jobRateCtrl,
                                    _jobRateFocus,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                    'Amount',
                                    _amountCtrl,
                                    FocusNode(),
                                    readOnly: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Qty Val (%)',
                                    _qtyValPercCtrl,
                                    _qtyValPercFocus,
                                    keyboard: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ElevatedButton(
                                      onPressed: _showQtyValDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade50,
                                        foregroundColor: AppColors.primaryColor,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(
                                            color: AppColors.primaryColor,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Change Var(%)'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              // ─── Fixed Bottom Buttons ───
              _buildBottomButtons(),
            ],
          ),
        ),
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
            foregroundColor: Colors.black,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
          ),
          onPressed: () {
            if (_sizeAdded) {
              // Save logic when size is already added
              final finishData = {
                'product': _selectedProduct,
                'designNo': _selectedDesignNo,
                'type': _selectedType,
                'shade': _selectedShade,
                'totalPcs': int.tryParse(_totalPcsCtrl.text) ?? 0,
                'avgRatio': _avgRatioCtrl.text,
                'cutMtr': _cutMtrCtrl.text,
                'orderNo': _selectedOrderNo,
                'merchandiser': _selectedMerchandiser,
                'description': _descriptionCtrl.text,
                'jobRate': double.tryParse(_jobRateCtrl.text) ?? 0,
                'amount': double.tryParse(_amountCtrl.text) ?? 0,
                'qtyValPerc': double.tryParse(_qtyValPercCtrl.text) ?? 0,
                'sizeDetails': _sizeDetails,
              };
              Navigator.pop(context, finishData);
            } else {
              // Show size bottom sheet to add quantity first
              _showSizeBottomSheet();
            }
          },
          child: Text(
            _sizeAdded ? 'Save' : 'Add Qty',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    ],
  );
}
}