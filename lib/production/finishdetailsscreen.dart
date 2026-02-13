import 'package:flutter/material.dart';

class FinishDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? finishDetail;

  const FinishDetailsScreen({super.key, this.finishDetail});

  @override
  State<FinishDetailsScreen> createState() => _FinishDetailsScreenState();
}

class _FinishDetailsScreenState extends State<FinishDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ──────────────────────  Controllers  ──────────────────────
  final _productCtrl = TextEditingController();
  final _avgRatioCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _cutMtrCtrl = TextEditingController();
  final _jobChargeCtrl = TextEditingController();
  final _jobAmtCtrl = TextEditingController();
  final _pcsCtrl = TextEditingController();
  final _designNoCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _shadeCtrl = TextEditingController();
  final _orderNoCtrl = TextEditingController();
  final _ppNoCtrl = TextEditingController();

  // ──────────────────────  Selected values  ──────────────────────
  String? _selectedOrderNo;
  String? _selectedPPNo;
  String? _selectedDesignNo;
  String? _selectedType;
  String? _selectedShade;

  // ──────────────────────  Dropdown lists  ──────────────────────
  final List<String> _orderNoList = ['ORD001', 'ORD002', 'ORD003'];
  final List<String> _ppNoList = ['PP01', 'PP02', 'PP03'];
  final List<String> _designNoList = ['DES001', 'DES002', 'DES003'];
  final List<String> _typeList = ['Type A', 'Type B', 'Type C'];
  final List<String> _shadeList = ['Shade 1', 'Shade 2', 'Shade 3'];

  // ──────────────────────  Size details  ──────────────────────
  final Map<String, Map<String, dynamic>> _sizeDetails = {
    'S': {'Recd Qty': 0, 'Isu Qty': 0, 'Short Qty': 0, 'Defect': 0, 'Allow Bal': 0},
    'M': {'Recd Qty': 0, 'Isu Qty': 0, 'Short Qty': 0, 'Defect': 0, 'Allow Bal': 0},
    'L': {'Recd Qty': 0, 'Isu Qty': 0, 'Short Qty': 0, 'Defect': 0, 'Allow Bal': 0},
    'XL': {'Recd Qty': 0, 'Isu Qty': 0, 'Short Qty': 0, 'Defect': 0, 'Allow Bal': 0},
    '2XL': {'Recd Qty': 0, 'Isu Qty': 0, 'Short Qty': 0, 'Defect': 0, 'Allow Bal': 0},
    '3XL': {'Recd Qty': 0, 'Isu Qty': 0, 'Short Qty': 0, 'Defect': 0, 'Allow Bal': 0},
  };

  int _totalPcs = 0;
  bool _sizeAdded = false;

  // ──────────────────────  Focus Nodes  ──────────────────────
  final _productFocus = FocusNode();
  final _avgRatioFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _cutMtrFocus = FocusNode();
  final _jobChargeFocus = FocusNode();
  final _jobAmtFocus = FocusNode();
  final _pcsFocus = FocusNode();
  final _designNoFocus = FocusNode();
  final _typeFocus = FocusNode();
  final _shadeFocus = FocusNode();
  final _orderNoFocus = FocusNode();
  final _ppNoFocus = FocusNode();

  // ──────────────────────  Animation  ──────────────────────
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _animCtrl.forward();

    if (widget.finishDetail != null) {
      final d = widget.finishDetail!;
      _orderNoCtrl.text = d['orderNo']?.toString() ?? '';
      _ppNoCtrl.text = d['ppNo']?.toString() ?? '';
      _designNoCtrl.text = d['designNo']?.toString() ?? '';
      _productCtrl.text = d['product']?.toString() ?? '';
      _typeCtrl.text = d['type']?.toString() ?? '';
      _shadeCtrl.text = d['shade']?.toString() ?? '';
      _pcsCtrl.text = (d['totalPcs'] ?? 0).toString();
      _avgRatioCtrl.text = d['avgRatio']?.toString() ?? '';
      _descriptionCtrl.text = d['description']?.toString() ?? '';
      _cutMtrCtrl.text = d['cutMtr']?.toString() ?? '';
      _jobChargeCtrl.text = d['jobCharge']?.toString() ?? '';
      _jobAmtCtrl.text = d['jobAmt']?.toString() ?? '';

      _selectedOrderNo = d['orderNo'];
      _selectedPPNo = d['ppNo'];
      _selectedDesignNo = d['designNo'];
      _selectedType = d['type'];
      _selectedShade = d['shade'];

      final Map<String, dynamic>? sizeMap = d['sizeDetails'];
      if (sizeMap != null) {
        sizeMap.forEach((key, value) {
          if (_sizeDetails.containsKey(key)) {
            _sizeDetails[key] = Map<String, dynamic>.from(value as Map);
          }
        });
      }

      _totalPcs = d['totalPcs'] ?? 0;
      _sizeAdded = _totalPcs > 0;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    // Controllers
    _productCtrl.dispose();
    _avgRatioCtrl.dispose();
    _descriptionCtrl.dispose();
    _cutMtrCtrl.dispose();
    _jobChargeCtrl.dispose();
    _jobAmtCtrl.dispose();
    _pcsCtrl.dispose();
    _designNoCtrl.dispose();
    _typeCtrl.dispose();
    _shadeCtrl.dispose();
    _orderNoCtrl.dispose();
    _ppNoCtrl.dispose();
    // Focus nodes
    _productFocus.dispose();
    _avgRatioFocus.dispose();
    _descriptionFocus.dispose();
    _cutMtrFocus.dispose();
    _jobChargeFocus.dispose();
    _jobAmtFocus.dispose();
    _pcsFocus.dispose();
    _designNoFocus.dispose();
    _typeFocus.dispose();
    _shadeFocus.dispose();
    _orderNoFocus.dispose();
    _ppNoFocus.dispose();

    super.dispose();
  }

  // ──────────────────────  Reusable TextField  ──────────────────────
  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    FocusNode focusNode, {
    TextInputType? keyboard,
    VoidCallback? onTap,
    bool isDate = false,
    bool readOnly = false,
  }) {
    final bool isInteractive = onTap != null || readOnly;

    return SizedBox(
      height: 56,
      child: GestureDetector(
        onTap: isInteractive
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
              labelStyle: const TextStyle( fontSize: 14,
              color: Color.fromARGB(255, 92, 91, 91),),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              enabledBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(255, 221, 220, 220), width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
              ),
              suffixIcon: onTap != null
                  ? Icon(
                      isDate ? Icons.event : Icons.expand_more,
                      size: 20,
                      color: Colors.grey,
                    )
                  : null,
            ),
            style: const TextStyle(
                fontSize: 18, color: Colors.black),
          ),
        ),
      ),
    );
  }

  // ──────────────────────  Reusable Dropdown  ──────────────────────
  Widget _buildDropdown({
    required String label,
    required TextEditingController ctrl,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onChanged,
    required FocusNode focusNode,
    bool allowAdd = true,
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
              builder: (_) => Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                        onTap: _removeOverlay,
                        child: Container(color: Colors.transparent)),
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
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (q) {
                                filtered.clear();
                                if (q.isEmpty) {
                                  filtered.addAll(items);
                                } else {
                                  filtered.addAll(items
                                      .where((e) => e.toLowerCase()
                                          .contains(q.toLowerCase())));
                                }
                                _overlay?.markNeedsBuild();
                              },
                            ),
                          ),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length + (allowAdd ? 1 : 0),
                              itemBuilder: (c, i) {
                                if (allowAdd && i == filtered.length) {
                                  return ListTile(
                                    leading:
                                        const Icon(Icons.add, color: Colors.blue),
                                    title: const Text('Add New…',
                                        style: TextStyle(color: Colors.blue)),
                                    onTap: () {
                                      _removeOverlay();
                                      _showAddDialog(label, items,
                                          (newItem) {
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
                                  selectedTileColor:
                                      Colors.blue.withOpacity(0.1),
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

  void _showAddDialog(
      String field, List<String> list, Function(String) onAdd) {
    final addCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add New $field'),
        content: TextField(
          controller: addCtrl,
          decoration: InputDecoration(hintText: 'Enter $field'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                final v = addCtrl.text.trim();
                if (v.isNotEmpty && !list.contains(v)) onAdd(v);
                Navigator.pop(context);
              },
              child: const Text('Add')),
        ],
      ),
    );
  }

  // ──────────────────────  Size Bottom Sheet  ──────────────────────
  void _showSizeBottomSheet() {
    final Map<String, TextEditingController> controllers = {};

    for (var size in _sizeDetails.keys) {
      for (var field in _sizeDetails[size]!.keys) {
        final key = '$size-$field';
        controllers[key] = TextEditingController(
            text: _sizeDetails[size]![field].toString());
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            int currentTotal = _sizeDetails.values
                .map((e) => e['Recd Qty'] as int)
                .fold(0, (a, b) => a + b);

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Add Quantity',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 450),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: const {
                                0: FixedColumnWidth(50),
                                1: FixedColumnWidth(70),
                                2: FixedColumnWidth(70),
                                3: FixedColumnWidth(70),
                                4: FixedColumnWidth(70),
                                5: FixedColumnWidth(70),
                              },
                              children: [
                                TableRow(
                                  decoration:
                                      BoxDecoration(color: Colors.grey.shade100),
                                  children: [
                                    _headerCell('Size'),
                                    _headerCell('Recd Qty'),
                                    _headerCell('Isu Qty'),
                                    _headerCell('Short Qty'),
                                    _headerCell('Defect'),
                                    _headerCell('Allow Bal'),
                                  ],
                                ),
                                ..._sizeDetails.entries.map((e) {
                                  final sizeKey = e.key;
                                  return TableRow(
                                    children: [
                                      _cell(sizeKey),
                                      _editableCellInSheet(
                                          sizeKey: sizeKey,
                                          fieldKey: 'Recd Qty',
                                          controllers: controllers,
                                          setSheetState: setSheetState),
                                      _editableCellInSheet(
                                          sizeKey: sizeKey,
                                          fieldKey: 'Isu Qty',
                                          controllers: controllers,
                                          setSheetState: setSheetState),
                                      _editableCellInSheet(
                                          sizeKey: sizeKey,
                                          fieldKey: 'Short Qty',
                                          controllers: controllers,
                                          setSheetState: setSheetState),
                                      _editableCellInSheet(
                                          sizeKey: sizeKey,
                                          fieldKey: 'Defect',
                                          controllers: controllers,
                                          setSheetState: setSheetState),
                                      _editableCellInSheet(
                                          sizeKey: sizeKey,
                                          fieldKey: 'Allow Bal',
                                          controllers: controllers,
                                          setSheetState: setSheetState),
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
                      margin: const EdgeInsets.only(top: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pcs:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$currentTotal',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          setState(() {
                            _totalPcs = currentTotal;
                            _sizeAdded = _totalPcs > 0;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Done',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _headerCell(String txt) => Padding(
        padding: const EdgeInsets.all(6.0),
        child: Text(txt,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center),
      );

  Widget _cell(String txt) => Padding(
        padding: const EdgeInsets.all(6.0),
        child: Text(txt,
            style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
      );

  Widget _editableCellInSheet({
    required String sizeKey,
    required String fieldKey,
    required Map<String, TextEditingController> controllers,
    required StateSetter setSheetState,
  }) {
    return _EditableCell(
      sizeKey: sizeKey,
      fieldKey: fieldKey,
      controllers: controllers,
      setSheetState: setSheetState,
      sizeDetails: _sizeDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    _pcsCtrl.text = _totalPcs.toString();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: Text(
            widget.finishDetail != null
                ? 'Edit Finish Details'
                : 'Finish Details',
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.search), onPressed: () {})
          ],
        ),
        body: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdown(
                          label: 'Design No',
                          ctrl: _designNoCtrl,
                          items: _designNoList,
                          selected: _selectedDesignNo,
                          onChanged: (v) => _selectedDesignNo = v,
                          focusNode: _designNoFocus,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField('Product', _productCtrl, _productFocus),
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
                          label: 'PP No',
                          ctrl: _ppNoCtrl,
                          items: _ppNoList,
                          selected: _selectedPPNo,
                          onChanged: (v) => _selectedPPNo = v,
                          focusNode: _ppNoFocus,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    'Pcs', _pcsCtrl, _pcsFocus,
                                    readOnly: true)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildTextField(
                                    'Avg Ratio',
                                    _avgRatioCtrl,
                                    _avgRatioFocus,
                                    keyboard: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField('Description', _descriptionCtrl,
                            _descriptionFocus),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    'Cut Mtr',
                                    _cutMtrCtrl,
                                    _cutMtrFocus,
                                    keyboard: TextInputType.number)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildTextField(
                                    'Job Charge',
                                    _jobChargeCtrl,
                                    _jobChargeFocus,
                                    keyboard: TextInputType.number)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField('Job Amt', _jobAmtCtrl, _jobAmtFocus,
                            keyboard: TextInputType.number),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_sizeAdded) {
                          Navigator.pop(context, {
                            'orderNo': _selectedOrderNo,
                            'ppNo': _selectedPPNo,
                            'designNo': _selectedDesignNo,
                            'product': _productCtrl.text,
                            'type': _selectedType,
                            'shade': _selectedShade,
                            'totalPcs': _totalPcs,
                            'avgRatio': _avgRatioCtrl.text,
                            'description': _descriptionCtrl.text,
                            'cutMtr': _cutMtrCtrl.text,
                            'jobCharge': _jobChargeCtrl.text,
                            'jobAmt': _jobAmtCtrl.text,
                            'sizeDetails': _sizeDetails,
                            'fabricDetails':
                                widget.finishDetail?['fabricDetails'] ??
                                    <Map<String, dynamic>>[],
                          });
                        } else {
                          _showSizeBottomSheet();
                        }
                      },
                      child: Text(
                        _sizeAdded
                            ? 'Confirm'
                            : (widget.finishDetail != null
                                ? 'Edit Qty'
                                : 'Add Qty'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────  Editable Cell (unchanged)  ──────────────────────
class _EditableCell extends StatefulWidget {
  final String sizeKey;
  final String fieldKey;
  final Map<String, TextEditingController> controllers;
  final StateSetter setSheetState;
  final Map<String, Map<String, dynamic>> sizeDetails;

  const _EditableCell({
    required this.sizeKey,
    required this.fieldKey,
    required this.controllers,
    required this.setSheetState,
    required this.sizeDetails,
  });

  @override
  State<_EditableCell> createState() => _EditableCellState();
}

class _EditableCellState extends State<_EditableCell> {
  late final FocusNode focusNode;
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    final key = '${widget.sizeKey}-${widget.fieldKey}';
    controller = widget.controllers[key]!;
    focusNode = FocusNode();
    focusNode.addListener(() => widget.setSheetState(() {}));
  }

  @override
  void dispose() {
    focusNode.removeListener(() => widget.setSheetState(() {}));
    focusNode.dispose();
    super.dispose();
  }

  Color _bgColor() {
    final hasValue = (int.tryParse(controller.text) ?? 0) > 0;
    return (hasValue || focusNode.hasFocus)
        ? const Color(0xFFFFFDE7)
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            filled: true,
            fillColor: _bgColor(),
            border: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 1.5)),
          ),
          onChanged: (v) {
            final value = int.tryParse(v) ?? 0;
            widget.sizeDetails[widget.sizeKey]![widget.fieldKey] = value;
            widget.setSheetState(() {});
          },
        ),
      ),
    );
  }
}