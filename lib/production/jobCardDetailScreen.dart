import 'package:flutter/material.dart';
import 'package:vrs_erp/production/fabric_details_screen.dart';
import 'package:vrs_erp/production/finishdetailsscreen.dart';


class JobCardDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? jobCard;

  const JobCardDetailScreen({super.key, this.jobCard});

  @override
  State<JobCardDetailScreen> createState() => _JobCardDetailScreenState();
}

class _JobCardDetailScreenState extends State<JobCardDetailScreen>
    with SingleTickerProviderStateMixin {
  // ──────────────────────  Job Card Controllers  ──────────────────────
  final TextEditingController _seriesCtrl = TextEditingController(text: 'JC');
  final TextEditingController _lastCodCtrl = TextEditingController();
  final TextEditingController _docNoCtrl = TextEditingController();
  final TextEditingController _docDtCtrl = TextEditingController();
  final TextEditingController _refNoCtrl = TextEditingController();
  final TextEditingController _jobberCtrl = TextEditingController();
  final TextEditingController _jwNoCtrl = TextEditingController();
  final TextEditingController _stationCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _jobChgCtrl = TextEditingController();
  final TextEditingController _jobAmtCtrl = TextEditingController();
  final TextEditingController _otherProcAmtCtrl = TextEditingController();
  final TextEditingController _netAmtCtrl = TextEditingController();
  final TextEditingController _receiptAgentCtrl = TextEditingController();
  final TextEditingController _expectedDtCtrl = TextEditingController();
  final TextEditingController _statusCtrl = TextEditingController();

  String? _selectedStatus = 'Open';
  String? _selectedJobber;
  String? _selectedStation;
  String? _selectedReceiptAgent;
  String? _selectedProcess;

  final List<String> _jobbers = ['Jobber 1', 'Jobber 2'];
  final List<String> _stations = ['Station A', 'Station B'];
  final List<String> _receiptAgents = ['Agent 1', 'Agent 2'];
  final List<String> _processes = ['Process 1', 'Process 2'];
  final List<String> _statusList = ['Open', 'BOM', 'Other'];

  final List<Map<String, dynamic>> _finishDetailsList = [];

  // ──────────────────────  Other Process Controllers  ──────────────────────
  String? _selectedOtherProcess;
  final TextEditingController _jobRateCtrl = TextEditingController();
  final TextEditingController _jobAmtOtherCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();

  final List<String> _otherProcesses = [
    'Dyeing',
    'Printing',
    'Washing',
    'Finishing',
  ];

  // ──────────────────────  Focus Nodes  ──────────────────────
  final FocusNode _seriesFocus = FocusNode();
  final FocusNode _lastCodFocus = FocusNode();
  final FocusNode _docNoFocus = FocusNode();
  final FocusNode _docDtFocus = FocusNode();
  final FocusNode _refNoFocus = FocusNode();
  final FocusNode _jobberFocus = FocusNode();
  final FocusNode _jwNoFocus = FocusNode();
  final FocusNode _stationFocus = FocusNode();
  final FocusNode _processFocus = FocusNode();
  final FocusNode _receiptAgentFocus = FocusNode();
  final FocusNode _expectedDtFocus = FocusNode();
  final FocusNode _statusFocus = FocusNode();
  final FocusNode _jobChgFocus = FocusNode();
  final FocusNode _jobAmtFocus = FocusNode();
  final FocusNode _otherProcAmtFocus = FocusNode();
  final FocusNode _netAmtFocus = FocusNode();

  // Other Process
  final FocusNode _otherProcessFocus = FocusNode();
  final FocusNode _jobRateFocus = FocusNode();
  final FocusNode _jobAmtOtherFocus = FocusNode();
  final FocusNode _remarkFocus = FocusNode();

  // ──────────────────────  Tab & Animation  ──────────────────────
  int _selectedTab = 0;
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    if (widget.jobCard != null) {
      final jc = widget.jobCard!;
      _seriesCtrl.text = jc['series']?.toString() ?? 'JC';
      _lastCodCtrl.text = jc['lastCod']?.toString() ?? '';
      _docNoCtrl.text = jc['docNo']?.toString() ?? '';
      _docDtCtrl.text = jc['docDt']?.toString() ?? '';
      _refNoCtrl.text = jc['refNo']?.toString() ?? '';
      _jobberCtrl.text = jc['jobber']?.toString() ?? '';
      _jwNoCtrl.text = jc['id'] != null
          ? '${jc['id']}-->S000001'
          : '';
      _stationCtrl.text = jc['station']?.toString() ?? '';
      _processCtrl.text = jc['process']?.toString() ?? '';
      _receiptAgentCtrl.text = jc['receiptAgent']?.toString() ?? '';
      _expectedDtCtrl.text = jc['expectedRtnDt']?.toString() ?? '';
      _statusCtrl.text = jc['status']?.toString() ?? 'Open';
      _selectedStatus = jc['status']?.toString() ?? 'Open';
      _selectedJobber = jc['jobber']?.toString();
      _selectedStation = jc['station']?.toString();
      _selectedReceiptAgent = jc['receiptAgent']?.toString();
      _selectedProcess = jc['process']?.toString();

      if (jc['finishDetails'] is List) {
        _finishDetailsList.addAll(
          List<Map<String, dynamic>>.from(jc['finishDetails']),
        );
      }
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();

    // Controllers
    _seriesCtrl.dispose();
    _lastCodCtrl.dispose();
    _docNoCtrl.dispose();
    _docDtCtrl.dispose();
    _refNoCtrl.dispose();
    _jobberCtrl.dispose();
    _jwNoCtrl.dispose();
    _stationCtrl.dispose();
    _processCtrl.dispose();
    _jobChgCtrl.dispose();
    _jobAmtCtrl.dispose();
    _otherProcAmtCtrl.dispose();
    _netAmtCtrl.dispose();
    _receiptAgentCtrl.dispose();
    _expectedDtCtrl.dispose();
    _statusCtrl.dispose();
    _jobRateCtrl.dispose();
    _jobAmtOtherCtrl.dispose();
    _remarkCtrl.dispose();

    // Focus Nodes
    _seriesFocus.dispose();
    _lastCodFocus.dispose();
    _docNoFocus.dispose();
    _docDtFocus.dispose();
    _refNoFocus.dispose();
    _jobberFocus.dispose();
    _jwNoFocus.dispose();
    _stationFocus.dispose();
    _processFocus.dispose();
    _receiptAgentFocus.dispose();
    _expectedDtFocus.dispose();
    _statusFocus.dispose();
    _jobChgFocus.dispose();
    _jobAmtFocus.dispose();
    _otherProcAmtFocus.dispose();
    _netAmtFocus.dispose();
    _otherProcessFocus.dispose();
    _jobRateFocus.dispose();
    _jobAmtOtherFocus.dispose();
    _remarkFocus.dispose();

    super.dispose();
  }

  // ──────────────────────  Re‑usable TextField with Focus Highlight  ──────────────────────
Widget _buildTextField(
  String label,
  TextEditingController ctrl,
  FocusNode focusNode, {
  TextInputType? keyboard,
  VoidCallback? onTap,
  bool isDate = false,
}) {
  final bool isInteractive = onTap != null;

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
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 92, 91, 91),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 221, 220, 220),
                width: 1,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
            ),
            suffixIcon: onTap != null
                ? Icon(
                    isDate ? Icons.event : Icons.expand_more,
                    size: 24,
                    color: isDate
                        ? Color.fromARGB(255, 3, 72, 82) // 📅 event color
                        : Colors.grey, // ⬇️ dropdown color
                  )
                : null,
          ),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
    ),
  );
}

  // ──────────────────────  Dropdown with Focus Highlight  ──────────────────────
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

  Widget _dateField(String label, TextEditingController ctrl, FocusNode focusNode) {
    return _buildTextField(
      label,
      ctrl,
      focusNode,
      isDate: true,
      onTap: () async {
        focusNode.requestFocus();
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          ctrl.text =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        }
      },
    );
  }

  // ──────────────────────  Finish Details (unchanged)  ──────────────────────
  void _addFinishDetail() async {
    final res = await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const FinishDetailsScreen()));
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        res['fabricDetails'] ??= <Map<String, dynamic>>[];
        _finishDetailsList.add(res);
      });
    }
  }

  void _editFinishDetail(int i) async {
    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FinishDetailsScreen(finishDetail: _finishDetailsList[i])));
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        res['fabricDetails'] ??= <Map<String, dynamic>>[];
        _finishDetailsList[i] = res;
      });
    }
  }

  void _deleteFinishDetail(int i) => setState(() => _finishDetailsList.removeAt(i));

  void _addFabric(int finishIdx) async {
    final finish = _finishDetailsList[finishIdx];
    final totalPcs = finish['totalPcs'] as int? ?? 0;
    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FabricDetailsScreen(
                initialReqQty: totalPcs.toString(), fabricDetail: null)));
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        (finish['fabricDetails'] as List).add(res);
      });
    }
  }

  void _editFabric(int finishIdx, int fabIdx) async {
    final finish = _finishDetailsList[finishIdx];
    final fab = (finish['fabricDetails'] as List)[fabIdx];
    final totalPcs = finish['totalPcs'] as int? ?? 0;
    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FabricDetailsScreen(
                initialReqQty: totalPcs.toString(), fabricDetail: fab)));
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        (finish['fabricDetails'] as List)[fabIdx] = res;
      });
    }
  }

  void _deleteFabric(int finishIdx, int fabIdx) => setState(() {
        (_finishDetailsList[finishIdx]['fabricDetails'] as List).removeAt(fabIdx);
      });

  Widget _buildFinishDetailCard(Map<String, dynamic> finishDetail, int index) {
    final Map<String, Map<String, dynamic>>? sizeMap = () {
      final raw = finishDetail['sizeDetails'];
      if (raw is Map<String, dynamic>) {
        return raw.map((key, value) {
          if (value is Map<String, dynamic>) {
            return MapEntry(key, value);
          }
          return MapEntry(key, <String, dynamic>{});
        });
      }
      return null;
    }();

    int shortTotal = 0;
    int defectTotal = 0;
    if (sizeMap != null) {
      for (final entry in sizeMap.entries) {
        final vals = entry.value as Map<String, dynamic>;
        shortTotal += (vals['Short Qty'] as int? ?? 0);
        defectTotal += (vals['Defect'] as int? ?? 0);
      }
    }

    Widget _kv(String label, String? value) {
      final v = value?.toString().isNotEmpty == true ? value! : '-';
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
             color: Color.fromARGB(255, 92, 91, 91),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 216, 142, 32),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    Widget _row(List<Widget> cells) {
      final children = <Widget>[];
      for (int i = 0; i < cells.length; i++) {
        if (i > 0) {
          children.addAll([
            const SizedBox(width: 6),
            const Text('|',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(width: 6),
          ]);
        }
        children.add(Expanded(child: cells[i]));
      }
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }

    final rows = [
      [
        _kv('Product', finishDetail['product']),
        _kv('Design', finishDetail['designNo']),
        _kv('Type', finishDetail['type']),
      ],
      [
        _kv('Shade', finishDetail['shade']),
        _kv('Tot Pcs', finishDetail['totalPcs']?.toString()),
        _kv('Fab Ratio', finishDetail['avgRatio']),
      ],
      [
        _kv('Cut Mtr', finishDetail['cutMtr']),
        _kv('Short Qty', shortTotal.toString()),
        _kv('Defect Qty', defectTotal.toString()),
      ],
      [
        _kv('Description', finishDetail['description']),
        _kv('SO No', finishDetail['orderNo']),
        _kv('Job Charge', finishDetail['jobCharge']),
      ],
      [
        _kv('Job Amt', finishDetail['jobAmt']),
        _kv('PP No', finishDetail['ppNo']),
        const SizedBox.shrink(),
      ],
    ];

    final fabricList =
        (finishDetail['fabricDetails'] as List<Map<String, dynamic>>?) ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${index + 1}: ${finishDetail['orderNo'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Colors.blueAccent, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _editFinishDetail(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.redAccent, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _deleteFinishDetail(index),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(thickness: 1, height: 8),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _row(r),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'TOTAL PCS: ${finishDetail['totalPcs']?.toString() ?? '0'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                      fontSize: 12.5),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 245, 246, 247),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FABRIC DETAILS',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle,
                            color: _finishDetailsList.isNotEmpty
                                ? Colors.blue
                                : Colors.grey,
                            size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: _finishDetailsList.isNotEmpty
                            ? () => _addFabric(index)
                            : null,
                      ),
                    ],
                  ),
                  if (fabricList.isNotEmpty)
                    ...fabricList.asMap().entries.map((e) {
                      final fab = e.value;
                      final fabIdx = e.key;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${fabIdx + 1}: ${fab['design'] ?? ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                        color: Colors.blueAccent),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            size: 13, color: Colors.blue),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            _editFabric(index, fabIdx),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 13, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            _deleteFabric(index, fabIdx),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(thickness: 1, height: 8),
                              Column(
                                children: [
                                  _row([
                                    _kv('Type', fab['type']),
                                    _kv('Design', fab['design']),
                                    _kv('Shade', fab['shade']),
                                  ]),
                                  const SizedBox(height: 3),
                                  _row([
                                    _kv('Req Qty', fab['reqQty']),
                                    _kv('Cut Qty', fab['cutQty']),
                                    _kv('Remarks', fab['remarks']),
                                  ]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                        child: Text(
                          'No fabric added',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.jobCard != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'View Job Card ${widget.jobCard!['id'] ?? ''}'
              : 'New Job Card',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: _selectedTab == 0
                              ? const Color.fromARGB(255, 213, 229, 231)
                              : Colors.white,
                          alignment: Alignment.center,
                          child: Text(
                            'Job Card',
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.black : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: _selectedTab == 1
                              ? const Color.fromARGB(255, 213, 229, 231)
                              : Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: Text(
                            'Other Process',
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.black : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedTab == 0 ? _jobCardForm() : _otherProcessForm(),
              ),
              _selectedTab == 0 ? _jobCardButtons() : _otherProcessButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobCardForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            color: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField('Series', _seriesCtrl, _seriesFocus),
                  const SizedBox(height: 8),
                  _buildTextField('Last Cod', _lastCodCtrl, _lastCodFocus),
                  const SizedBox(height: 8),
                  _buildTextField('Doc No', _docNoCtrl, _docNoFocus),
                  const SizedBox(height: 8),
                  _dateField('Doc Dt', _docDtCtrl, _docDtFocus),
                  const SizedBox(height: 8),
                  _buildTextField('Ref No', _refNoCtrl, _refNoFocus),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    label: 'Jobber',
                    ctrl: _jobberCtrl,
                    items: _jobbers,
                    selected: _selectedJobber,
                    onChanged: (v) => _selectedJobber = v,
                    focusNode: _jobberFocus,
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    label: 'Station',
                    ctrl: _stationCtrl,
                    items: _stations,
                    selected: _selectedStation,
                    onChanged: (v) => _selectedStation = v,
                    focusNode: _stationFocus,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField('J.W.No', _jwNoCtrl, _jwNoFocus),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    label: 'Receipt AGSt',
                    ctrl: _receiptAgentCtrl,
                    items: _receiptAgents,
                    selected: _selectedReceiptAgent,
                    onChanged: (v) => _selectedReceiptAgent = v,
                    focusNode: _receiptAgentFocus,
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    label: 'Process',
                    ctrl: _processCtrl,
                    items: _processes,
                    selected: _selectedProcess,
                    onChanged: (v) => _selectedProcess = v,
                    focusNode: _processFocus,
                  ),
                  const SizedBox(height: 8),
                  _dateField('Expected Rtn Dt', _expectedDtCtrl, _expectedDtFocus),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    label: 'Status',
                    ctrl: _statusCtrl,
                    items: _statusList,
                    selected: _selectedStatus,
                    onChanged: (v) => _selectedStatus = v,
                    focusNode: _statusFocus,
                    allowAdd: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            color: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: InkWell(
              onTap: _addFinishDetail,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FINISH DETAILS', style: TextStyle(fontSize: 17,fontWeight:FontWeight.bold)),
                    Icon(Icons.add_circle, color: Color.fromARGB(255, 46, 107, 48)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._finishDetailsList
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildFinishDetailCard(e.value, e.key),
                  )),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField('Job Chg /Pc', _jobChgCtrl, _jobChgFocus,
                              keyboard: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildTextField('Job Amount', _jobAmtCtrl, _jobAmtFocus,
                              keyboard: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              'Other Proc Amt', _otherProcAmtCtrl, _otherProcAmtFocus,
                              keyboard: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildTextField('Net Amount', _netAmtCtrl, _netAmtFocus,
                              keyboard: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otherProcessForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDropdown(
                label: 'Process',
                ctrl: TextEditingController(text: _selectedOtherProcess ?? ''),
                items: _otherProcesses,
                selected: _selectedOtherProcess,
                onChanged: (v) => setState(() => _selectedOtherProcess = v),
                focusNode: _otherProcessFocus,
                allowAdd: true,
              ),
              const SizedBox(height: 16),
              _buildTextField('Job Rate', _jobRateCtrl, _jobRateFocus,
                  keyboard: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Job Amt', _jobAmtOtherCtrl, _jobAmtOtherFocus,
                  keyboard: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Remark', _remarkCtrl, _remarkFocus,
                  keyboard: TextInputType.multiline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobCardButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.pop(context, {
                'series': _seriesCtrl.text,
                'lastCod': _lastCodCtrl.text,
                'docNo': _docNoCtrl.text,
                'docDt': _docDtCtrl.text,
                'refNo': _refNoCtrl.text,
                'jobber': _selectedJobber,
                'jwNo': _jwNoCtrl.text,
                'station': _selectedStation,
                'process': _selectedProcess,
                'jobChg': _jobChgCtrl.text,
                'jobAmount': _jobAmtCtrl.text,
                'otherProcAmt': _otherProcAmtCtrl.text,
                'netAmount': _netAmtCtrl.text,
                'receiptAgent': _selectedReceiptAgent,
                'expectedRtnDt': _expectedDtCtrl.text,
                'status': _selectedStatus,
                'finishDetails': _finishDetailsList,
              });
            },
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _otherProcessButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              Navigator.pop(context, {
                'type': 'other_process',
                'process': _selectedOtherProcess,
                'jobRate': _jobRateCtrl.text,
                'jobAmt': _jobAmtOtherCtrl.text,
                'remark': _remarkCtrl.text,
              });
            },
            child: const Text('Confirm'),
          ),
        ),
      ],
    );
  }
}