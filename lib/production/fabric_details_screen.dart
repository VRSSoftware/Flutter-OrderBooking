import 'package:flutter/material.dart';

class FabricDetailsScreen extends StatefulWidget {
  final String? initialReqQty;
  final Map<String, dynamic>? fabricDetail;

  const FabricDetailsScreen({super.key, this.initialReqQty, this.fabricDetail});

  @override
  State<FabricDetailsScreen> createState() => _FabricDetailsScreenState();
}

class _FabricDetailsScreenState extends State<FabricDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ──────────────────────  Controllers  ──────────────────────
  final _reqQtyCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _ratioCtrl = TextEditingController();
  final _wastCtrl = TextEditingController();
  final _cutQtyCtrl = TextEditingController();
  final _stkQtyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _shadeCtrl = TextEditingController();

  // ──────────────────────  Selected Values  ──────────────────────
  String? _selectedType;
  String? _selectedDesign;
  String? _selectedShade;

  // ──────────────────────  Dropdown Lists  ──────────────────────
  final List<String> _typeList = ['Type A', 'Type B', 'Type C'];
  final List<String> _designList = ['DES001', 'DES002', 'DES003'];
  final List<String> _shadeList = ['Shade 1', 'Shade 2', 'Shade 3'];

  // ──────────────────────  Focus Nodes  ──────────────────────
  final _reqQtyFocus = FocusNode();
  final _widthFocus = FocusNode();
  final _ratioFocus = FocusNode();
  final _wastFocus = FocusNode();
  final _cutQtyFocus = FocusNode();
  final _stkQtyFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _typeFocus = FocusNode();
  final _designFocus = FocusNode();
  final _shadeFocus = FocusNode();

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

    if (widget.fabricDetail != null) {
      final d = widget.fabricDetail!;
      _typeCtrl.text = d['type']?.toString() ?? '';
      _designCtrl.text = d['design']?.toString() ?? '';
      _shadeCtrl.text = d['shade']?.toString() ?? '';
      _reqQtyCtrl.text = d['reqQty']?.toString() ?? '';
      _widthCtrl.text = d['width']?.toString() ?? '';
      _ratioCtrl.text = d['ratio']?.toString() ?? '';
      _wastCtrl.text = d['wast']?.toString() ?? '';
      _cutQtyCtrl.text = d['cutQty']?.toString() ?? '';
      _stkQtyCtrl.text = d['stkQty']?.toString() ?? '';
      _descriptionCtrl.text = d['description']?.toString() ?? '';

      _selectedType = d['type'];
      _selectedDesign = d['design'];
      _selectedShade = d['shade'];
    } else if (widget.initialReqQty != null) {
      _reqQtyCtrl.text = widget.initialReqQty!;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();

    // Controllers
    _reqQtyCtrl.dispose();
    _widthCtrl.dispose();
    _ratioCtrl.dispose();
    _wastCtrl.dispose();
    _cutQtyCtrl.dispose();
    _stkQtyCtrl.dispose();
    _descriptionCtrl.dispose();
    _typeCtrl.dispose();
    _designCtrl.dispose();
    _shadeCtrl.dispose();

    // Focus Nodes
    _reqQtyFocus.dispose();
    _widthFocus.dispose();
    _ratioFocus.dispose();
    _wastFocus.dispose();
    _cutQtyFocus.dispose();
    _stkQtyFocus.dispose();
    _descriptionFocus.dispose();
    _typeFocus.dispose();
    _designFocus.dispose();
    _shadeFocus.dispose();

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
              labelStyle: const TextStyle(fontSize: 14, color: Colors.grey),
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
                      isDate ? Icons.calendar_today : Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey,
                    )
                  : null,
            ),
            style: const TextStyle(
                fontSize: 18, color: Color.fromARGB(255, 94, 93, 93)),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.fabricDetail != null ? 'Edit Fabric' : 'Add Fabric',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Fabric Selection ───
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
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
                              label: 'Design',
                              ctrl: _designCtrl,
                              items: _designList,
                              selected: _selectedDesign,
                              onChanged: (v) => _selectedDesign = v,
                              focusNode: _designFocus,
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
                          ],
                        ),
                      ),

                      // ─── In Stock Section ───
                      _sectionLabel('In Stock'),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    'Width', _widthCtrl, _widthFocus,
                                    keyboard: TextInputType.number),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                    'Ratio', _ratioCtrl, _ratioFocus,
                                    keyboard: TextInputType.number),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Quantity Section ───
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                      'Req Qty', _reqQtyCtrl, _reqQtyFocus,
                                      keyboard: TextInputType.number),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                      'Wast%', _wastCtrl, _wastFocus,
                                      keyboard: TextInputType.number),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTextField('Cut Qty', _cutQtyCtrl, _cutQtyFocus,
                                keyboard: TextInputType.number),
                          ],
                        ),
                      ),

                      // ─── Taka Section ───
                      _sectionLabel('Taka'),
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                    'Stk Qty', _stkQtyCtrl, _stkQtyFocus,
                                    keyboard: TextInputType.number),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                    'Description',
                                    _descriptionCtrl,
                                    _descriptionFocus),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ─── Action Buttons ───
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
                        Navigator.pop(context, {
                          'type': _selectedType,
                          'design': _selectedDesign,
                          'shade': _selectedShade,
                          'width': _widthCtrl.text,
                          'ratio': _ratioCtrl.text,
                          'reqQty': _reqQtyCtrl.text,
                          'wast': _wastCtrl.text,
                          'cutQty': _cutQtyCtrl.text,
                          'stkQty': _stkQtyCtrl.text,
                          'description': _descriptionCtrl.text,
                        });
                      },
                      child: const Text('Confirm'),
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