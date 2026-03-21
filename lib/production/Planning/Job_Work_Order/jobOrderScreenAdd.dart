import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/Planning/Job_Work_Order/jobWorkFinishDtl.dart';


class CreateJobOrderScreen extends StatefulWidget {
  final Map<String, dynamic>? jobWork;
  
  const CreateJobOrderScreen({super.key, this.jobWork});

  @override
  State<CreateJobOrderScreen> createState() => _CreateJobOrderScreenState();
}

class _CreateJobOrderScreenState extends State<CreateJobOrderScreen>
    with TickerProviderStateMixin {
  // ────────────────────── Tab Controller ──────────────────────
  late TabController _tabController;
  int _selectedTab = 0;

  // ────────────────────── Job Order Controllers ──────────────────────
  final TextEditingController _seriesCtrl = TextEditingController(text: 'JW');
  final TextEditingController _lastCdCtrl = TextEditingController(text: '00005');
  final TextEditingController _docNoCtrl = TextEditingController(text: 'JW00006');
  final TextEditingController _docDtCtrl = TextEditingController();
  final TextEditingController _refNoCtrl = TextEditingController();
  final TextEditingController _expectedDlvDtCtrl = TextEditingController();
  final TextEditingController _estStartDtCtrl = TextEditingController();
  final TextEditingController _estEndDtCtrl = TextEditingController();
  final TextEditingController _actualStartDtCtrl = TextEditingController();
  final TextEditingController _actualEndDtCtrl = TextEditingController();
  
  // ────────────────────── Dropdown Values ──────────────────────
  String? _selectedJobber;
  String? _selectedStation;
  String? _selectedProcess;
  
  // ────────────────────── Radio Button Values ──────────────────────
  String _orderType = 'Open';
  String _stockPickup = 'Partial';
  
  // ────────────────────── Checkbox Values ──────────────────────
  bool _receivedAsFinished = false;
  bool _reProcess = false;
  
  // ────────────────────── Dropdown Lists ──────────────────────
  final List<String> _jobbers = ['SELF', 'ABC Textiles', 'XYZ Garments', 'LMN Industries'];
  final List<String> _stations = ['SURAT', 'MUMBAI', 'DELHI', 'AHMEDABAD', 'BANGALORE'];
  final List<String> _processes = ['Cutting', 'Stitching', 'Washing', 'Packing', 'Finishing'];
  
  // ────────────────────── Focus Nodes ──────────────────────
  final FocusNode _docDtFocus = FocusNode();
  final FocusNode _refNoFocus = FocusNode();
  final FocusNode _expectedDlvDtFocus = FocusNode();
  final FocusNode _jobberFocus = FocusNode();
  final FocusNode _stationFocus = FocusNode();
  final FocusNode _processFocus = FocusNode();
  final FocusNode _estStartDtFocus = FocusNode();
  final FocusNode _estEndDtFocus = FocusNode();
  final FocusNode _actualStartDtFocus = FocusNode();
  final FocusNode _actualEndDtFocus = FocusNode();
  
  // ────────────────────── Financial Controllers ──────────────────────
  final TextEditingController _grossAmtCtrl = TextEditingController(text: '0');
  final TextEditingController _othAmtCtrl = TextEditingController(text: '0');
  final TextEditingController _gstPercCtrl = TextEditingController(text: '18');
  final TextEditingController _gstAmtCtrl = TextEditingController(text: '0');
  final TextEditingController _netAmtCtrl = TextEditingController(text: '0');
  
  // ────────────────────── Other Process Controllers ──────────────────────
  final TextEditingController _otherProcessCtrl = TextEditingController();
  final TextEditingController _jobRateCtrl = TextEditingController();
  final TextEditingController _jobAmtCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  String? _selectedOtherProcess;
  final List<String> _otherProcesses = ['Dyeing', 'Printing', 'Washing', 'Finishing', 'Embroidery'];
  
  // ────────────────────── Finish Details ──────────────────────
  final List<Map<String, dynamic>> _finishDetailsList = [];
  
  // ────────────────────── Animation ──────────────────────
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // ────────────────────── Search Controllers for Dropdowns ──────────────────────
  final TextEditingController _jobberSearchCtrl = TextEditingController();
  final TextEditingController _stationSearchCtrl = TextEditingController();
  final TextEditingController _processSearchCtrl = TextEditingController();
  
  // Controllers for dropdowns
  final TextEditingController _jobberCtrl = TextEditingController();
  final TextEditingController _stationCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    
    // Set default date
    _docDtCtrl.text = _getCurrentDate();
    
    // Add listeners for financial calculations
    _grossAmtCtrl.addListener(_calculateNetAmt);
    _othAmtCtrl.addListener(_calculateNetAmt);
    _gstPercCtrl.addListener(_calculateNetAmt);
    
    // If editing, populate the form with existing data
    if (widget.jobWork != null) {
      _populateFormWithExistingData();
    }
  }
  
  void _populateFormWithExistingData() {
    final data = widget.jobWork!;
    _seriesCtrl.text = data['series']?.toString() ?? 'JW';
    _lastCdCtrl.text = data['lastCd']?.toString() ?? '';
    _docNoCtrl.text = data['docNo']?.toString() ?? '';
    _docDtCtrl.text = data['docDt']?.toString() ?? _getCurrentDate();
    _refNoCtrl.text = data['refNo']?.toString() ?? '';
    _expectedDlvDtCtrl.text = data['expectedDlvDt']?.toString() ?? '';
    _selectedJobber = data['jobber']?.toString();
    _jobberCtrl.text = _selectedJobber ?? '';
    _selectedStation = data['station']?.toString();
    _stationCtrl.text = _selectedStation ?? '';
    _orderType = data['orderType']?.toString() ?? 'Open';
    _estStartDtCtrl.text = data['estStartDt']?.toString() ?? '';
    _estEndDtCtrl.text = data['estEndDt']?.toString() ?? '';
    _actualStartDtCtrl.text = data['actualStartDt']?.toString() ?? '';
    _actualEndDtCtrl.text = data['actualEndDt']?.toString() ?? '';
    _selectedProcess = data['process']?.toString();
    _processCtrl.text = _selectedProcess ?? '';
    _stockPickup = data['stockPickup']?.toString() ?? 'Partial';
    _receivedAsFinished = data['receivedAsFinished'] ?? false;
    _reProcess = data['reProcess'] ?? false;
    _grossAmtCtrl.text = data['grossAmt']?.toString() ?? '0';
    _othAmtCtrl.text = data['othAmt']?.toString() ?? '0';
    _gstPercCtrl.text = data['gstPerc']?.toString() ?? '18';
    
    // Finish details
    if (data['finishDetails'] != null) {
      _finishDetailsList.addAll(List<Map<String, dynamic>>.from(data['finishDetails']));
    }
    
    // Calculate net amount
    _calculateNetAmt();
  }
  
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
  
  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }
  
  int _calculateTotalPcs() {
    int total = 0;
    for (var finish in _finishDetailsList) {
      total += finish['totalPcs'] as int? ?? 0;
    }
    return total;
  }
  
  void _calculateNetAmt() {
    double gross = double.tryParse(_grossAmtCtrl.text) ?? 0;
    double oth = double.tryParse(_othAmtCtrl.text) ?? 0;
    double gstPerc = double.tryParse(_gstPercCtrl.text) ?? 0;
    
    double total = gross + oth;
    double gstAmt = total * (gstPerc / 100);
    double netAmt = total + gstAmt;
    
    _gstAmtCtrl.text = gstAmt.toStringAsFixed(2);
    _netAmtCtrl.text = netAmt.toStringAsFixed(2);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _seriesCtrl.dispose();
    _lastCdCtrl.dispose();
    _docNoCtrl.dispose();
    _docDtCtrl.dispose();
    _refNoCtrl.dispose();
    _expectedDlvDtCtrl.dispose();
    _estStartDtCtrl.dispose();
    _estEndDtCtrl.dispose();
    _actualStartDtCtrl.dispose();
    _actualEndDtCtrl.dispose();
    _grossAmtCtrl.dispose();
    _othAmtCtrl.dispose();
    _gstPercCtrl.dispose();
    _gstAmtCtrl.dispose();
    _netAmtCtrl.dispose();
    _otherProcessCtrl.dispose();
    _jobRateCtrl.dispose();
    _jobAmtCtrl.dispose();
    _remarkCtrl.dispose();
    _jobberSearchCtrl.dispose();
    _stationSearchCtrl.dispose();
    _processSearchCtrl.dispose();
    _jobberCtrl.dispose();
    _stationCtrl.dispose();
    _processCtrl.dispose();
    _docDtFocus.dispose();
    _refNoFocus.dispose();
    _expectedDlvDtFocus.dispose();
    _jobberFocus.dispose();
    _stationFocus.dispose();
    _processFocus.dispose();
    _estStartDtFocus.dispose();
    _estEndDtFocus.dispose();
    _actualStartDtFocus.dispose();
    _actualEndDtFocus.dispose();
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
    bool isDate = false,
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
                color: focusNode.hasFocus
                    ? AppColors.primaryColor
                    : Colors.grey.shade300,
                width: focusNode.hasFocus ? 2 : 1,
              ),
            ),
            child: GestureDetector(
              onTap: onTap,
              child: AbsorbPointer(
                absorbing: readOnly || onTap != null,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  readOnly: readOnly || onTap != null,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                    hintText: label,
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    suffixIcon: onTap != null
                        ? Icon(
                            isDate ? Icons.calendar_today : Icons.arrow_drop_down,
                            size: 20,
                            color: Colors.grey.shade600,
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
  
  Widget _buildDateField(String label, TextEditingController controller, FocusNode focusNode) {
    return _buildTextField(
      label: label,
      controller: controller,
      focusNode: focusNode,
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
                colorScheme: const ColorScheme.light(primary: AppColors.primaryColor),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        }
      },
      isDate: true,
    );
  }
  
void _addFinishDetail() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FinishDetailScreenForJobWork(),
    ),
  );
  
  if (result != null && mounted) {
    setState(() {
      _finishDetailsList.add(result);
    });
  }
}

void _editFinishDetail(int index) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FinishDetailScreenForJobWork(
        finishDetail: _finishDetailsList[index],
      ),
    ),
  );
  
  if (result != null && mounted) {
    setState(() {
      _finishDetailsList[index] = result;
    });
  }
}
 
  
  void _deleteFinishDetail(int index) {
    setState(() {
      _finishDetailsList.removeAt(index);
    });
  }
  
  void _saveJobOrder() {
    final jobOrderData = {
      'series': _seriesCtrl.text,
      'lastCd': _lastCdCtrl.text,
      'docNo': _docNoCtrl.text,
      'docDt': _docDtCtrl.text,
      'refNo': _refNoCtrl.text,
      'expectedDlvDt': _expectedDlvDtCtrl.text,
      'jobber': _selectedJobber,
      'station': _selectedStation,
      'orderType': _orderType,
      'estStartDt': _estStartDtCtrl.text,
      'estEndDt': _estEndDtCtrl.text,
      'actualStartDt': _actualStartDtCtrl.text,
      'actualEndDt': _actualEndDtCtrl.text,
      'process': _selectedProcess,
      'stockPickup': _stockPickup,
      'receivedAsFinished': _receivedAsFinished,
      'reProcess': _reProcess,
      'grossAmt': double.tryParse(_grossAmtCtrl.text) ?? 0,
      'othAmt': double.tryParse(_othAmtCtrl.text) ?? 0,
      'gstPerc': double.tryParse(_gstPercCtrl.text) ?? 0,
      'gstAmt': double.tryParse(_gstAmtCtrl.text) ?? 0,
      'netAmt': double.tryParse(_netAmtCtrl.text) ?? 0,
      'finishDetails': _finishDetailsList,
      'status': 'Planned',
      'createdBy': 'Current User',
      'createdOn': _getCurrentDateTime(),
      'updatedBy': 'Current User',
      'updatedOn': _getCurrentDateTime(),
      'totPcs': _calculateTotalPcs(),
      'jobChgPc': double.tryParse(_jobRateCtrl.text) ?? 0,
    };
    
    Navigator.pop(context, jobOrderData);
  }
  
  void _saveOtherProcess() {
    final otherProcessData = {
      'process': _selectedOtherProcess,
      'jobRate': double.tryParse(_jobRateCtrl.text),
      'jobAmt': double.tryParse(_jobAmtCtrl.text),
      'remark': _remarkCtrl.text,
    };
    
    Navigator.pop(context, otherProcessData);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.jobWork == null ? 'Create Job Order' : 'Edit Job Order',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'JOB ORDER', icon: Icon(Icons.work)),
            Tab(text: 'OTHER PROCESS', icon: Icon(Icons.settings_applications)),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildJobOrderForm(),
            _buildOtherProcessForm(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJobOrderForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Divider(height: 20),
                  
                  // Row 1: Series, Last Cd, Doc No
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Series',
                          controller: _seriesCtrl,
                          focusNode: FocusNode(),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Last Cd',
                          controller: _lastCdCtrl,
                          focusNode: FocusNode(),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Doc No',
                          controller: _docNoCtrl,
                          focusNode: FocusNode(),
                          readOnly: true,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  
                  // Row 2: Doc Dt, Ref No
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField('Doc Dt', _docDtCtrl, _docDtFocus),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Ref No',
                          controller: _refNoCtrl,
                          focusNode: _refNoFocus,
                        ),
                      ),
                    ],
                  ),
                  
                  // Row 3: Expected Dlv Dt
                  _buildDateField('Expected Dlv Dt', _expectedDlvDtCtrl, _expectedDlvDtFocus),
                  
                  // Row 4: Jobber, Station
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchableDropdown(
                          label: 'Jobber',
                          controller: _jobberCtrl,
                          items: _jobbers,
                          selected: _selectedJobber,
                          onChanged: (v) => _selectedJobber = v,
                          focusNode: _jobberFocus,
                          searchController: _jobberSearchCtrl,
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSearchableDropdown(
                          label: 'Station',
                          controller: _stationCtrl,
                          items: _stations,
                          selected: _selectedStation,
                          onChanged: (v) => _selectedStation = v,
                          focusNode: _stationFocus,
                          searchController: _stationSearchCtrl,
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  
                  // Order Type Radio Buttons
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Order Type',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Open', style: TextStyle(fontSize: 14)),
                                value: 'Open',
                                groupValue: _orderType,
                                onChanged: (value) => setState(() => _orderType = value!),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('BOM', style: TextStyle(fontSize: 14)),
                                value: 'BOM',
                                groupValue: _orderType,
                                onChanged: (value) => setState(() => _orderType = value!),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Dates Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField('Est Start Dt', _estStartDtCtrl, _estStartDtFocus),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField('Est End Dt', _estEndDtCtrl, _estEndDtFocus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField('Actual Start Dt', _actualStartDtCtrl, _actualStartDtFocus),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField('Actual End Dt', _actualEndDtCtrl, _actualEndDtFocus),
                      ),
                    ],
                  ),
                  
                  // Process Dropdown
                  _buildSearchableDropdown(
                    label: 'Process',
                    controller: _processCtrl,
                    items: _processes,
                    selected: _selectedProcess,
                    onChanged: (v) => _selectedProcess = v,
                    focusNode: _processFocus,
                    searchController: _processSearchCtrl,
                  ),
                  
                  // Stock Pickup Radio Buttons
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Stock Pickup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Partial', style: TextStyle(fontSize: 14)),
                                value: 'Partial',
                                groupValue: _stockPickup,
                                onChanged: (value) => setState(() => _stockPickup = value!),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Ready', style: TextStyle(fontSize: 14)),
                                value: 'Ready',
                                groupValue: _stockPickup,
                                onChanged: (value) => setState(() => _stockPickup = value!),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Checkboxes Row
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Received As Finished', style: TextStyle(fontSize: 13)),
                          value: _receivedAsFinished,
                          onChanged: (value) => setState(() => _receivedAsFinished = value!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('ReProcess', style: TextStyle(fontSize: 13)),
                          value: _reProcess,
                          onChanged: (value) => setState(() => _reProcess = value!),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Finish Details Section
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
            child: Column(
              children: [
                // Header
                InkWell(
                  onTap: _addFinishDetail,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                                color: AppColors.primaryColor.withOpacity(0.1),
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
                            color: AppColors.primaryColor.withOpacity(0.1),
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
                
                // Finish Details List
                if (_finishDetailsList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: _finishDetailsList.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> finish = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            title: Text(
                              finish['product'] ?? 'Finish ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              'Design: ${finish['designNo'] ?? '-'} | PCS: ${finish['totalPcs'] ?? 0}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryColor),
                                  onPressed: () => _editFinishDetail(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  onPressed: () => _deleteFinishDetail(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Financial Details Card
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
                  const Divider(height: 20),
                  
                  // Row 1: Gross Amt, Oth Amt
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Gross Amt',
                          controller: _grossAmtCtrl,
                          focusNode: FocusNode(),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Oth Amt',
                          controller: _othAmtCtrl,
                          focusNode: FocusNode(),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Row 2: GST Perc, GST Amt
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'GST Perc (%)',
                          controller: _gstPercCtrl,
                          focusNode: FocusNode(),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'GST Amt',
                          controller: _gstAmtCtrl,
                          focusNode: FocusNode(),
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Net Amt
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                    ),
                    child: _buildTextField(
                      label: 'Net Amt',
                      controller: _netAmtCtrl,
                      focusNode: FocusNode(),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Buttons Row - Cancel and Save
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
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveJobOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildOtherProcessForm() {
    return SingleChildScrollView(
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
              const Text(
                'OTHER PROCESS DETAILS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const Divider(height: 20),
              
              // Process Dropdown
              _buildSearchableDropdown(
                label: 'Process',
                controller: _otherProcessCtrl,
                items: _otherProcesses,
                selected: _selectedOtherProcess,
                onChanged: (v) => _selectedOtherProcess = v,
                focusNode: FocusNode(),
                searchController: TextEditingController(),
                isRequired: true,
              ),
              
              const SizedBox(height: 8),
              
              // Job Rate
              _buildTextField(
                label: 'Job Rate',
                controller: _jobRateCtrl,
                focusNode: FocusNode(),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 8),
              
              // Job Amt
              _buildTextField(
                label: 'Job Amt',
                controller: _jobAmtCtrl,
                focusNode: FocusNode(),
                keyboardType: TextInputType.number,
              ),
              
              const SizedBox(height: 8),
              
              // Remark
              _buildTextField(
                label: 'Remark',
                controller: _remarkCtrl,
                focusNode: FocusNode(),
                keyboardType: TextInputType.multiline,
              ),
              
              const SizedBox(height: 20),
              
              // Buttons Row - Cancel and Save
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
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveOtherProcess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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