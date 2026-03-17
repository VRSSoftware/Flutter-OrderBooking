import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/JobCard_cutting/fabric_details_screen.dart';
import 'package:vrs_erp/production/JobCard_cutting/finishdetailsscreen.dart';

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
    bool isRequired = false,
  }) {
    final bool isInteractive = onTap != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
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
                color: focusNode.hasFocus
                    ?  AppColors.primaryColor
                    : Colors.grey.shade300,
                width: focusNode.hasFocus ? 2 : 1,
              ),
            ),
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
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    hintText: label,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                    suffixIcon: onTap != null
                        ? Icon(
                            isDate ? Icons.calendar_today : Icons.arrow_drop_down,
                            size: 20,
                            color: isDate
                                ?  AppColors.primaryColor
                                : Colors.grey.shade600,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
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
    bool isRequired = false,
  }) {
    OverlayEntry? _overlay;

    void _removeOverlay() {
      _overlay?.remove();
      _overlay = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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

                  final filtered = List<String>.from(items);
                  final searchCtrl = TextEditingController();

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
                                      controller: searchCtrl,
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
                                  Expanded(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: filtered.length + (allowAdd ? 1 : 0),
                                      itemBuilder: (c, i) {
                                        if (allowAdd && i == filtered.length) {
                                          return ListTile(
                                            leading: const Icon(Icons.add, 
                                                color: AppColors.primaryColor, size: 20),
                                            title: Text(
                                              'Add New $label',
                                              style: const TextStyle(
                                                color: AppColors.primaryColor,
                                                fontSize: 13,
                                              ),
                                            ),
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
                                          dense: true,
                                          title: Text(
                                            item,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          selected: selected == item,
                                          selectedTileColor:
                                               AppColors.primaryColor.withOpacity(0.1),
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
                      color: focusNode.hasFocus
                          ?  AppColors.primaryColor
                          : Colors.grey.shade300,
                      width: focusNode.hasFocus ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ctrl.text.isEmpty ? 'Select $label' : ctrl.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: ctrl.text.isEmpty
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
        content: TextField(
          controller: addCtrl,
          decoration: InputDecoration(
            hintText: 'Enter $field',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:  AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          ctrl.text =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        }
      },
    );
  }

  // ──────────────────────  Finish Details (redesigned)  ──────────────────────
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

    Widget _infoChip(String label, String? value) {
      final v = value?.toString().isNotEmpty == true ? value! : '-';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                v,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    final fabricList =
        (finishDetail['fabricDetails'] as List<Map<String, dynamic>>?) ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with order number and actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:  AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1}. ${finishDetail['orderNo'] ?? 'Order'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppColors.primaryColor, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _editFinishDetail(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteFinishDetail(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Main details grid
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      Expanded(child: _infoChip('Product', finishDetail['product'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Design', finishDetail['designNo'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Type', finishDetail['type'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 2
                  Row(
                    children: [
                      Expanded(child: _infoChip('Shade', finishDetail['shade'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Tot Pcs', finishDetail['totalPcs']?.toString())),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Fab Ratio', finishDetail['avgRatio'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 3
                  Row(
                    children: [
                      Expanded(child: _infoChip('Cut Mtr', finishDetail['cutMtr'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Short Qty', shortTotal.toString())),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Defect Qty', defectTotal.toString())),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 4
                  Row(
                    children: [
                      Expanded(child: _infoChip('Desc', finishDetail['description'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('SO No', finishDetail['orderNo'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('Job Charge', finishDetail['jobCharge'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Row 5
                  Row(
                    children: [
                      Expanded(child: _infoChip('Job Amt', finishDetail['jobAmt'])),
                      const SizedBox(width: 8),
                      Expanded(child: _infoChip('PP No', finishDetail['ppNo'])),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Total PCS highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                     AppColors.primaryColor.withOpacity(0.1),
                     AppColors.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color:  AppColors.primaryColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  'TOTAL PCS: ${finishDetail['totalPcs']?.toString() ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Fabric Details Section
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  childrenPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Icon(Icons.inventory, size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'FABRIC DETAILS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color:  AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          '${fabricList.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle,
                        color: _finishDetailsList.isNotEmpty
                            ?  AppColors.primaryColor
                            : Colors.grey,
                        size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _finishDetailsList.isNotEmpty
                        ? () => _addFabric(index)
                        : null,
                  ),
                  children: [
                    if (fabricList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: fabricList.asMap().entries.map((e) {
                            final fab = e.value;
                            final fabIdx = e.key;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${fabIdx + 1}. ${fab['design'] ?? ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Color(0xFF2C3E50),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 16, color: AppColors.primaryColor),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () =>
                                                  _editFabric(index, fabIdx),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  size: 16, color: Colors.red),
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
                                    const SizedBox(height: 4),
                                    // Fabric details in 2 rows
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _infoChip('Type', fab['type']),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _infoChip('Design', fab['design']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _infoChip('Shade', fab['shade']),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _infoChip('Req Qty', fab['reqQty']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _infoChip('Cut Qty', fab['cutQty']),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _infoChip('Remarks', fab['remarks']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No fabric added yet',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Job Card #${widget.jobCard!['id'] ?? ''}'
              : 'New Job Card',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:  AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // Tab Bar
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ?  AppColors.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Job Card',
                              style: TextStyle(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ?  AppColors.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Other Process',
                              style: TextStyle(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _selectedTab == 0 
                      ? _jobCardForm() 
                      : _otherProcessForm(),
                ),
                
                // Buttons
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade700,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _selectedTab == 0 ? _saveJobCard : _saveOtherProcess,
                          child: Text(_selectedTab == 0 ? 'Save' : 'Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveJobCard() {
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
  }

  void _saveOtherProcess() {
    Navigator.pop(context, {
      'type': 'other_process',
      'process': _selectedOtherProcess,
      'jobRate': _jobRateCtrl.text,
      'jobAmt': _jobAmtOtherCtrl.text,
      'remark': _remarkCtrl.text,
    });
  }

  Widget _jobCardForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Basic Information Card
          Container(
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
                  const Text(
                    'BASIC INFORMATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const Divider(height: 16),
                  
                  // Row 1: Series, Last Cod, Doc No
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Series', _seriesCtrl, _seriesFocus, isRequired: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Last Cod', _lastCodCtrl, _lastCodFocus)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Doc No', _docNoCtrl, _docNoFocus, isRequired: true)),
                    ],
                  ),
                  
                  // Row 2: Doc Dt, Ref No
                  Row(
                    children: [
                      Expanded(child: _dateField('Doc Dt', _docDtCtrl, _docDtFocus)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Ref No', _refNoCtrl, _refNoFocus)),
                    ],
                  ),
                  
                  // Row 3: Jobber, Station
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Jobber',
                          ctrl: _jobberCtrl,
                          items: _jobbers,
                          selected: _selectedJobber,
                          onChanged: (v) => _selectedJobber = v,
                          focusNode: _jobberFocus,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Station',
                          ctrl: _stationCtrl,
                          items: _stations,
                          selected: _selectedStation,
                          onChanged: (v) => _selectedStation = v,
                          focusNode: _stationFocus,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  
                  // Row 4: J.W.No, Receipt AGSt
                  Row(
                    children: [
                      Expanded(child: _buildTextField('J.W.No', _jwNoCtrl, _jwNoFocus)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Receipt AGSt',
                          ctrl: _receiptAgentCtrl,
                          items: _receiptAgents,
                          selected: _selectedReceiptAgent,
                          onChanged: (v) => _selectedReceiptAgent = v,
                          focusNode: _receiptAgentFocus,
                        ),
                      ),
                    ],
                  ),
                  
                  // Row 5: Process, Expected Rtn Dt
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Process',
                          ctrl: _processCtrl,
                          items: _processes,
                          selected: _selectedProcess,
                          onChanged: (v) => _selectedProcess = v,
                          focusNode: _processFocus,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _dateField('Expected Rtn Dt', _expectedDtCtrl, _expectedDtFocus)),
                    ],
                  ),
                  
                  // Row 6: Status
                  _buildDropdown(
                    label: 'Status',
                    ctrl: _statusCtrl,
                    items: _statusList,
                    selected: _selectedStatus,
                    onChanged: (v) => _selectedStatus = v,
                    focusNode: _statusFocus,
                    allowAdd: false,
                    isRequired: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Finish Details Header
          Container(
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
            child: InkWell(
              onTap: _addFinishDetail,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.checklist, color: AppColors.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'FINISH DETAILS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:  AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_finishDetailsList.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:  AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Finish Details Cards
          ..._finishDetailsList
              .asMap()
              .entries
              .map((e) => _buildFinishDetailCard(e.value, e.key)),
          
          const SizedBox(height: 12),
          
          // Financial Information Card
          Container(
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
                  const Text(
                    'FINANCIAL DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const Divider(height: 16),
                  
                  // Row 1: Job Chg /Pc, Job Amount
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Job Chg /Pc', 
                          _jobChgCtrl, 
                          _jobChgFocus,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          'Job Amount', 
                          _jobAmtCtrl, 
                          _jobAmtFocus,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Row 2: Other Proc Amt, Net Amount (highlighted)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Other Proc Amt', 
                          _otherProcAmtCtrl, 
                          _otherProcAmtFocus,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:  AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: _buildTextField(
                            'Net Amount', 
                            _netAmtCtrl, 
                            _netAmtFocus,
                            keyboard: TextInputType.number,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _otherProcessForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
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
              const Text(
                'OTHER PROCESS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const Divider(height: 16),
              
              _buildDropdown(
                label: 'Process',
                ctrl: TextEditingController(text: _selectedOtherProcess ?? ''),
                items: _otherProcesses,
                selected: _selectedOtherProcess,
                onChanged: (v) => setState(() => _selectedOtherProcess = v),
                focusNode: _otherProcessFocus,
                allowAdd: true,
                isRequired: true,
              ),
              
              const SizedBox(height: 8),
              
              _buildTextField(
                'Job Rate', 
                _jobRateCtrl, 
                _jobRateFocus,
                keyboard: TextInputType.number,
              ),
              
              const SizedBox(height: 8),
              
              _buildTextField(
                'Job Amt', 
                _jobAmtOtherCtrl, 
                _jobAmtOtherFocus,
                keyboard: TextInputType.number,
              ),
              
              const SizedBox(height: 8),
              
              _buildTextField(
                'Remark', 
                _remarkCtrl, 
                _remarkFocus,
                keyboard: TextInputType.multiline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}