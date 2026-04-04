import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/Planning/Job_Work_Order/jobWorkFinishDtl.dart';
import 'package:vrs_erp/production/Widgets/custom_date_field.dart';
import 'package:vrs_erp/production/Widgets/custom_searchable_dropdown.dart';
import 'package:vrs_erp/production/Widgets/custom_text_field.dart';
import 'package:vrs_erp/services/production_services.dart';

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
  final TextEditingController _seriesCtrl = TextEditingController(text: '');
  final TextEditingController _lastCdCtrl = TextEditingController(text: '');
  final TextEditingController _docNoCtrl = TextEditingController(text: '');
  final TextEditingController _docDtCtrl = TextEditingController();
  final TextEditingController _refNoCtrl = TextEditingController();
  final TextEditingController _expectedDlvDtCtrl = TextEditingController();
  final TextEditingController _estStartDtCtrl = TextEditingController();
  final TextEditingController _estEndDtCtrl = TextEditingController();
  final TextEditingController _actualStartDtCtrl = TextEditingController();
  final TextEditingController _actualEndDtCtrl = TextEditingController();

  // ────────────────────── Dropdown Values ──────────────────────
  Map<String, dynamic>? _selectedJobber;
  Map<String, dynamic>? _selectedStation;
  String? _selectedProcess;

  // ────────────────────── Radio Button Values ──────────────────────
  String _orderType = 'Open';
  String _stockPickup = 'Partial';

  // ────────────────────── Checkbox Values ──────────────────────
  bool _receivedAsFinished = false;
  bool _reProcess = false;

  // ────────────────────── Dynamic Dropdown Lists ──────────────────────
  List<Map<String, dynamic>> _jobberList = [];
  List<String> _stations = [];
  final List<String> _processes = [
    'Cutting',
    'Stitching',
    'Washing',
    'Packing',
    'Finishing',
  ];

  // ────────────────────── Loading States ──────────────────────
  bool _isLoadingJobbers = false;

  // ────────────────────── Validation Error Messages ──────────────────────
  String? _estDateError;
  String? _actualDateError;

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
  final FocusNode _othAmtFocus = FocusNode();
  final FocusNode _gstPercFocus = FocusNode();

  // ────────────────────── Financial Controllers ──────────────────────
  final TextEditingController _grossAmtCtrl = TextEditingController(text: '0');
  final TextEditingController _othAmtCtrl = TextEditingController(text: '0');
  final TextEditingController _gstPercCtrl = TextEditingController(
    text: '5',
  ); // Changed default to 5
  final TextEditingController _gstAmtCtrl = TextEditingController(text: '0');
  final TextEditingController _netAmtCtrl = TextEditingController(text: '0');

  // ────────────────────── Other Process Controllers ──────────────────────
  final TextEditingController _otherProcessCtrl = TextEditingController();
  final TextEditingController _jobRateCtrl = TextEditingController();
  final TextEditingController _jobAmtCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  Map<String, dynamic>? _selectedOtherProcess;
  final List<Map<String, dynamic>> _otherProcessesList = [
    {'key': 'Dyeing', 'name': 'Dyeing'},
    {'key': 'Printing', 'name': 'Printing'},
    {'key': 'Washing', 'name': 'Washing'},
    {'key': 'Finishing', 'name': 'Finishing'},
    {'key': 'Embroidery', 'name': 'Embroidery'},
  ];

  // ────────────────────── Finish Details ──────────────────────
  final List<Map<String, dynamic>> _finishDetailsList = [];
  final Set<int> _expandedCards = {};

  // ────────────────────── Animation ──────────────────────
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ────────────────────── Controllers for dropdowns ──────────────────────
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

    // Set default dates for other date fields
    _estStartDtCtrl.text = _getCurrentDate();
    _estEndDtCtrl.text = _getCurrentDate();
    _actualStartDtCtrl.text = _getCurrentDate();
    _actualEndDtCtrl.text = _getCurrentDate();
    _expectedDlvDtCtrl.text = _getCurrentDate();

    // Make Gross Amount read-only
    _grossAmtCtrl.addListener(() {
      if (_grossAmtCtrl.text.isEmpty) {
        _grossAmtCtrl.text = '0';
      }
    });

    _loadSeries();
    if (widget.jobWork == null) {
      _loadDocNo();
    }

    // Load jobbers and set default after loading
    _loadJobbers().then((_) {
      if (widget.jobWork == null && _jobberList.isNotEmpty) {
        setState(() {
          _selectedJobber = _jobberList[0];
          _jobberCtrl.text = _jobberList[0]['name'] ?? '';
          if (_jobberList[0]['station'] != null &&
              _jobberList[0]['station'].isNotEmpty) {
            _selectedStation = {
              "key": _jobberList[0]['stationKey'],
              "name": _jobberList[0]['station'],
            };

            _stationCtrl.text = _selectedStation?['name'] ?? '';
          }
        });
      }
    });

    // Set default process
    if (_processes.isNotEmpty) {
      _selectedProcess = _processes[0];
      _processCtrl.text = _processes[0];
    }

    // Set default other process
    if (_otherProcessesList.isNotEmpty) {
      _selectedOtherProcess = _otherProcessesList[0];
      _otherProcessCtrl.text = _otherProcessesList[0]['name'] ?? '';
    }

    // If editing, populate the form with existing data (this will override defaults)
    if (widget.jobWork != null) {
      _populateFormWithExistingData();
    }

    // Add this line to trigger initial calculation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateNetAmt();
    });
  }

  Future<void> _loadSeries() async {
    final seriesData = await ProductionService.getSeries('143');
    if (seriesData.isNotEmpty) {
      setState(() {
        _seriesCtrl.text = seriesData['Sr_Code'] ?? '';
      });
    }
  }

  Future<void> _loadDocNo() async {
    final docNoData = await ProductionService.getDocNo();
    setState(() {
      _lastCdCtrl.text = docNoData['LastCd'] ?? '';
      _docNoCtrl.text = docNoData['DocNo'] ?? '';
    });
  }

  Future<void> _loadJobbers() async {
    setState(() => _isLoadingJobbers = true);
    _jobberList = await ProductionService.getJobbers();
    setState(() => _isLoadingJobbers = false);
  }

  void _populateFormWithExistingData() {
    final data = widget.jobWork!;
    _seriesCtrl.text = data['series']?.toString() ?? '';
    _lastCdCtrl.text = data['lastCd']?.toString() ?? '';
    _docNoCtrl.text = data['docNo']?.toString() ?? '';
    _docDtCtrl.text = data['docDt']?.toString() ?? _getCurrentDate();
    _refNoCtrl.text = data['refNo']?.toString() ?? '';
    _expectedDlvDtCtrl.text =
        data['expectedDlvDt']?.toString() ?? _getCurrentDate();

    if (data['jobber'] != null) {
      _selectedJobber = {
        'key': data['jobberKey'] ?? '',
        'name': data['jobber'],
        'station': data['station'] ?? '',
      };
      _jobberCtrl.text = data['jobber'];
    }

    if (data['station'] != null) {
      _selectedStation = {"key": data['stationKey'], "name": data['station']};

      _stationCtrl.text = _selectedStation?['name'] ?? '';
    }
    _orderType = data['orderType']?.toString() ?? 'Open';
    _estStartDtCtrl.text = data['estStartDt']?.toString() ?? _getCurrentDate();
    _estEndDtCtrl.text = data['estEndDt']?.toString() ?? _getCurrentDate();
    _actualStartDtCtrl.text =
        data['actualStartDt']?.toString() ?? _getCurrentDate();
    _actualEndDtCtrl.text =
        data['actualEndDt']?.toString() ?? _getCurrentDate();
    _selectedProcess =
        data['process']?.toString() ??
        (_processes.isNotEmpty ? _processes[0] : null);
    _processCtrl.text = _selectedProcess ?? '';
    _stockPickup = data['stockPickup']?.toString() ?? 'Partial';
    _receivedAsFinished = data['receivedAsFinished'] ?? false;
    _reProcess = data['reProcess'] ?? false;
    _grossAmtCtrl.text = data['grossAmt']?.toString() ?? '0';
    _othAmtCtrl.text = data['othAmt']?.toString() ?? '0';
    _gstPercCtrl.text = data['gstPerc']?.toString() ?? '5';

    // Finish details
    if (data['finishDetails'] != null) {
      _finishDetailsList.addAll(
        List<Map<String, dynamic>>.from(data['finishDetails']),
      );
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

  // Calculate Gross Amount from all finish details
  double _calculateGrossAmount() {
    double total = 0;
    for (var finish in _finishDetailsList) {
      total += finish['amount'] as double? ?? 0;
    }
    return total;
  }

  // Update Gross Amount whenever finish details change
  void _updateGrossAmount() {
    double grossAmount = _calculateGrossAmount();
    _grossAmtCtrl.text = grossAmount.toStringAsFixed(2);
    _calculateNetAmt();
  }

  void _calculateNetAmt() {
    // Handle empty or invalid values gracefully
    double gross = 0.0;
    double oth = 0.0;
    double gstPerc = 5.0;

    // Only parse if text is not empty
    if (_grossAmtCtrl.text.isNotEmpty && _grossAmtCtrl.text != '-') {
      gross = double.tryParse(_grossAmtCtrl.text) ?? 0;
    }

    if (_othAmtCtrl.text.isNotEmpty && _othAmtCtrl.text != '-') {
      oth = double.tryParse(_othAmtCtrl.text) ?? 0;
    }

    if (_gstPercCtrl.text.isNotEmpty && _gstPercCtrl.text != '-') {
      gstPerc = double.tryParse(_gstPercCtrl.text) ?? 5;
    }

    double totalBeforeGst = gross + oth;
    double gstAmt = totalBeforeGst * (gstPerc / 100);
    double netAmt = totalBeforeGst + gstAmt;

    // Use setState to ensure UI updates
    setState(() {
      _gstAmtCtrl.text = gstAmt.toStringAsFixed(2);
      _netAmtCtrl.text = netAmt.toStringAsFixed(2);
    });
  }

  // ────────────────────── Validation Methods ──────────────────────
  void _validateEstDates() {
    if (_estStartDtCtrl.text.isNotEmpty && _estEndDtCtrl.text.isNotEmpty) {
      final startDate = _parseDate(_estStartDtCtrl.text);
      final endDate = _parseDate(_estEndDtCtrl.text);

      if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
        setState(() {
          _estDateError = 'Est End Date cannot be before Est Start Date';
        });
      } else {
        setState(() {
          _estDateError = null;
        });
      }
    } else {
      setState(() {
        _estDateError = null;
      });
    }
  }

  void _validateActualDates() {
    if (_actualStartDtCtrl.text.isNotEmpty &&
        _actualEndDtCtrl.text.isNotEmpty) {
      final startDate = _parseDate(_actualStartDtCtrl.text);
      final endDate = _parseDate(_actualEndDtCtrl.text);

      if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
        setState(() {
          _actualDateError =
              'Actual End Date cannot be before Actual Start Date';
        });
      } else {
        setState(() {
          _actualDateError = null;
        });
      }
    } else {
      setState(() {
        _actualDateError = null;
      });
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      return null;
    }
    return null;
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
    _othAmtFocus.dispose();
    _gstPercFocus.dispose();
    super.dispose();
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
        _updateGrossAmount(); // Update gross amount when adding finish
      });
    }
  }

  void _editFinishDetail(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FinishDetailScreenForJobWork(
              finishDetail: _finishDetailsList[index],
            ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _finishDetailsList[index] = result;
        _updateGrossAmount(); // Update gross amount when editing finish
      });
    }
  }

  void _deleteFinishDetail(int index) {
    setState(() {
      _finishDetailsList.removeAt(index);
      _updateGrossAmount(); // Update gross amount when deleting finish
    });
  }

  void _saveJobOrder() async {
    // Final validation before save
    _validateEstDates();
    _validateActualDates();

    if (_estDateError != null || _actualDateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _estDateError ?? _actualDateError ?? 'Please fix validation errors',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Get current date and time for various fields
    final now = DateTime.now();
    final currentDate = _formatDateTime(now);
    final currentTime = _formatTimeOfDay(now);

    // Transform finish details to jobOrderDetails format
    final jobOrderDetails = _transformFinishDetailsToJobOrderDetailsForAPI();

    final payload = {
      // Header Fields (without number suffixes)
      "CoBr_Id": UserSession.coBrId,
      "FcYr_Id": UserSession.userFcYr,
      "Doc_Sr": _seriesCtrl.text,
      "Doc_Dt": _parseDateToISO(_docDtCtrl.text) ?? currentDate,
      "Party_Key": _selectedJobber?['key'] ?? '',
      "Stn_Key": _selectedStation?['key'] ?? '',
      "Our_RefNo": _refNoCtrl.text,
      "Exp_Dlv_dt": _parseDateToISO(_expectedDlvDtCtrl.text) ?? currentDate,
      "TotPcs": _calculateTotalPcs(),
      "Job_Rate": double.tryParse(_jobRateCtrl.text) ?? 0,
      "Job_ANX": _remarkCtrl.text,
      "Status": "1", // 1 = Active
      "Remark": _remarkCtrl.text,
      "Print_Doc": 0,
      "Created_By": 1,
      "Created_Time": currentTime,
      "JobCard_From": _orderType == 'Open' ? "M" : "B",
      "EstStart_Dt": _parseDateToISO(_estStartDtCtrl.text) ?? currentDate,
      "EstEnd_Dt": _parseDateToISO(_estEndDtCtrl.text) ?? currentDate,
      "ActStart_Dt": _parseDateToISO(_actualStartDtCtrl.text),
      "ActEnd_Dt": _parseDateToISO(_actualEndDtCtrl.text),
      "Dlv_Days": _calculateDeliveryDays(),
      "ProStg_Id": 1,
      "In_Out": "I",
      "Gross_Amt": double.tryParse(_grossAmtCtrl.text) ?? 0,
      "Oth_Amt": double.tryParse(_othAmtCtrl.text) ?? 0,
      "GSTPerc": double.tryParse(_gstPercCtrl.text) ?? 0,
      "Gst_Amt": double.tryParse(_gstAmtCtrl.text) ?? 0,
      "Net_Amt": double.tryParse(_netAmtCtrl.text) ?? 0,
      "Finish_Stk": _receivedAsFinished ? "1" : "0",
      "ReProcess": _reProcess ? "1" : "0",
      "StockPickFrom": _stockPickup == 'Partial' ? "P" : "R",
      "Consperson_Id": 0,
      "IsSemiProcess": "0",
      "ProductPickAsPer": "C",

      // Details
      "jobOrderDetails": jobOrderDetails,
    };

    // Call the API
    final result = await ProductionService.insertJobOrder(payload);

    // Hide loading indicator
    Navigator.pop(context);

    if (result['success']) {
      // Show success message and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job Order created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, payload);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  List<Map<String, dynamic>> _transformFinishDetailsToJobOrderDetailsForAPI() {
    List<Map<String, dynamic>> details = [];

    for (int i = 0; i < _finishDetailsList.length; i++) {
      final finish = _finishDetailsList[i];
      final sizeDetailsMap =
          finish['sizeDetails'] as Map<String, Map<String, dynamic>>? ?? {};
      print('@@@@@@@@@@@@Size Details Map: $sizeDetailsMap');
      sizeDetailsMap.forEach((sizeName, sizeData) {
        print(
          'Size: $sizeName, Data: $sizeData, StyleSize_Id: ${sizeData['StyleSize_Id']}',
        );
      });
      final fabricsList =
          finish['fabrics'] as List<Map<String, dynamic>>? ?? [];

      // Transform size details
      final sizeDetails = _transformSizeDetailsForAPI(sizeDetailsMap);

      // Transform fabric details
      final fabricDetails = _transformFabricDetailsForAPI(fabricsList);

      details.add({
        "Item_Key": finish['productKey'] ?? '',
        "Style_Key": finish['designKey'] ?? '',
        "Type_Key": finish['typeKey'] ?? '',
        "Shade_Key": finish['shadeKey'] ?? '',
        "TotalQty": finish['totalPcs'] ?? 0,
        "Fab_Ratio": finish['avgRatio'] ?? 0,
        "Fab_Qty": finish['cutMtr'] ?? 0,
        "Description": finish['description'] ?? '',
        "BomPrdStyle_Id": 0,
        "SO_DocDtlId": 0,
        "Merch_Key": finish['merchandiserKey'] ?? '',
        "PP_DocDtlId": 0,
        "JobRate": finish['jobRate'] ?? 0,
        "JobAmt": finish['amount'] ?? 0,
        "Var_Perc": finish['qtyValPerc'] ?? 0,
        "Unit_Key": "011", // Default unit key
        "InitDt": _getCurrentDateTimeISO(),
        "InitQty": finish['totalPcs'] ?? 0,
        "InitRemark": "Initial",
        "DispShade_Key": finish['shadeKey'] ?? '',

        "sizeDetails": sizeDetails,
        "fabricDetails": fabricDetails,
      });
    }

    return details;
  }

  List<Map<String, dynamic>> _transformSizeDetailsForAPI(
    Map<String, Map<String, dynamic>> sizeDetailsMap,
  ) {
    List<Map<String, dynamic>> sizeDetails = [];

    sizeDetailsMap.forEach((sizeName, sizeData) {
      // Debug check (VERY IMPORTANT)
      if (sizeData['StyleSize_Id'] == null) {
        print("❌ ERROR: StyleSize_Id missing for size → $sizeName : $sizeData");
      }

      sizeDetails.add({
        "StyleSize_Id": sizeData['StyleSize_Id'], // ✅ ONLY THIS KEY
        "Qty": sizeData['aQty'] ?? 0,
        "Fab_Qty": sizeData['aQty'] ?? 0,
        "BalQty": 0,
        "ProdnPlnDtlSz_ID": 0,
        "InitDt": _getCurrentDateTimeISO(),
        "InitQty": sizeData['aQty'] ?? 0,
        "InitRemark": "Size Initial",
      });
    });

    return sizeDetails;
  }

  List<Map<String, dynamic>> _transformFabricDetailsForAPI(
    List<Map<String, dynamic>> fabricsList,
  ) {
    List<Map<String, dynamic>> fabricDetails = [];

    for (int i = 0; i < fabricsList.length; i++) {
      final fabric = fabricsList[i];

      fabricDetails.add({
        "BomPrdStyleDtl_Id": 0,
        "ProdPlanFab_Id": 0,
        "ItemSubGrp_key": fabric['itemSubGrpKey'] ?? '',
        "Shade_Key": fabric['shadeKey'] ?? '',
        "Brand_Key": fabric['brandKey'] ?? '',
        "Ratio": fabric['ratio'] ?? 0,
        "Req_Qty": fabric['reqQty'] ?? 0,
        "WastePerc": fabric['wast'] ?? 0,
        "Waste_Qty": fabric['wasteAmt'] ?? 0,
        "Description": fabric['description'] ?? '',
        "Placement": "",
        "Item_Key": fabric['productKey'] ?? '',
        "Style_Key": fabric['designKey'] ?? '',
        // "Type_Key": fabric['typeKey'] ?? '',
        "Type_Key": '',
        "Act_Qty": fabric['actualQty'] ?? 0,
        "BalQty": (fabric['reqQty'] ?? 0) - (fabric['actualQty'] ?? 0),
        "Var_Perc": fabric['qtyVar'] ?? 0,
      });
    }

    return fabricDetails;
  }

  // Helper method for time formatting
  String _formatTimeOfDay(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour % 12;
    if (hour12 == 0) hour12 = 12;
    return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  // Helper methods for date formatting
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}T${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String? _parseDateToISO(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return _formatDateTime(date);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String _getCurrentDateTimeISO() {
    final now = DateTime.now();
    return _formatDateTime(now);
  }

  int _calculateDeliveryDays() {
    if (_expectedDlvDtCtrl.text.isEmpty) return 0;

    final expectedDate = _parseDateToISO(_expectedDlvDtCtrl.text);
    if (expectedDate == null) return 0;

    final docDate = _parseDateToISO(_docDtCtrl.text);
    if (docDate == null) return 0;

    final expected = DateTime.parse(expectedDate);
    final doc = DateTime.parse(docDate);

    return expected.difference(doc).inDays;
  }

  void _saveOtherProcess() {
    final otherProcessData = {
      'process': _selectedOtherProcess?['name'],
      'processKey': _selectedOtherProcess?['key'],
      'jobRate': double.tryParse(_jobRateCtrl.text),
      'jobAmt': double.tryParse(_jobAmtCtrl.text),
      'remark': _remarkCtrl.text,
    };

    Navigator.pop(context, otherProcessData);
  }

  Widget _buildFinishCard(int index, Map<String, dynamic> finish) {
    final isExpanded = _expandedCards.contains(index);
    final fabrics = finish['fabrics'] as List? ?? [];
    final totalPcs = finish['totalPcs'] ?? 0;
    final avgRatio = finish['avgRatio'] ?? 0;
    final cutMtr = finish['cutMtr'] ?? 0;
    final amount = finish['amount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(index);
                } else {
                  _expandedCards.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.checklist,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finish['product'] ?? 'Finish ${index + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PCS: $totalPcs',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Amount: ₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () => _editFinishDetail(index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteFinishDetail(index),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded Content
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  // Finish Summary
                  _buildInfoRow('Design No:', finish['designNo'] ?? '-'),
                  _buildInfoRow('Type:', finish['type'] ?? '-'),
                  _buildInfoRow('Shade:', finish['shade'] ?? '-'),
                  _buildInfoRow('Order No:', finish['orderNo'] ?? '-'),
                  _buildInfoRow('Merchandiser:', finish['merchandiser'] ?? '-'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Avg Ratio',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                avgRatio.toStringAsFixed(5),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Cut Mtr',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cutMtr.toStringAsFixed(3),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Fabrics Section
                  if (fabrics.isNotEmpty) ...[
                    const Text(
                      'FABRICS DETAILS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...fabrics.map((fabric) => _buildFabricCard(fabric)),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No fabrics added',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFabricCard(Map<String, dynamic> fabric) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fabric['product'] ?? 'Product',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ratio: ${(fabric['ratio'] ?? 0).toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildFabricDetailChip(
                'Type',
                fabric['type'] ?? '-',
                Colors.purple,
              ),
              _buildFabricDetailChip(
                'Design',
                fabric['design'] ?? '-',
                Colors.teal,
              ),
              _buildFabricDetailChip(
                'Shade',
                fabric['shade'] ?? '-',
                Colors.pink,
              ),
              _buildFabricDetailChip(
                'Req Qty',
                (fabric['reqQty'] ?? 0).toStringAsFixed(3),
                Colors.blue,
              ),
              _buildFabricDetailChip(
                'Wast%',
                (fabric['wast'] ?? 0).toStringAsFixed(2),
                Colors.red,
              ),
              _buildFabricDetailChip(
                'Actual Qty',
                (fabric['actualQty'] ?? 0).toStringAsFixed(3),
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFabricDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
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
          children: [_buildJobOrderForm(), _buildOtherProcessForm()],
        ),
      ),
    );
  }

  Widget _buildJobOrderForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Series',
                                controller: _seriesCtrl,
                                focusNode: FocusNode(),
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Last Cd',
                                controller: _lastCdCtrl,
                                focusNode: FocusNode(),
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Doc No',
                                controller: _docNoCtrl,
                                focusNode: FocusNode(),
                                readOnly: true,
                                isRequired: true,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDateField(
                                label: 'Doc Dt',
                                controller: _docDtCtrl,
                                focusNode: _docDtFocus,
                                maxDate: DateTime.now(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Ref No',
                                controller: _refNoCtrl,
                                focusNode: _refNoFocus,
                              ),
                            ),
                          ],
                        ),
                        CustomDateField(
                          label: 'Expected Dlv Dt',
                          controller: _expectedDlvDtCtrl,
                          focusNode: _expectedDlvDtFocus,
                          minDate: DateTime.now(),
                        ),
                        CustomSearchableDropdown(
                          label: 'Jobber',
                          controller: _jobberCtrl,
                          items: _jobberList,
                          selected: _selectedJobber,
                          onChanged: (v) {
                            setState(() {
                              _selectedJobber = v;
                              if (v != null &&
                                  v['station'] != null &&
                                  v['station'].isNotEmpty) {
                                _selectedStation = {
                                  "key": v['stationKey'], // ✅ ONLY KEY
                                  "name": v['station'], // ✅ ONLY NAME
                                };

                                _stationCtrl.text =
                                    _selectedStation?['name'] ?? '';
                              }
                            });
                          },
                          focusNode: _jobberFocus,
                          isRequired: true,
                          isLoading: _isLoadingJobbers,
                          showClearButton: true,
                          allowClear: true,
                        ),
                        CustomTextField(
                          label: 'Station',
                          controller: _stationCtrl,
                          focusNode: _stationFocus,
                          readOnly: true,
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
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
                                      title: const Text(
                                        'Open',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: 'Open',
                                      groupValue: _orderType,
                                      onChanged:
                                          (value) => setState(
                                            () => _orderType = value!,
                                          ),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text(
                                        'BOM',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: 'BOM',
                                      groupValue: _orderType,
                                      onChanged:
                                          (value) => setState(
                                            () => _orderType = value!,
                                          ),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDateField(
                                label: 'Est Start Dt',
                                controller: _estStartDtCtrl,
                                focusNode: _estStartDtFocus,
                                onDateChanged: (date) => _validateEstDates(),
                                onValidationError:
                                    (error) =>
                                        setState(() => _estDateError = error),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomDateField(
                                label: 'Est End Dt',
                                controller: _estEndDtCtrl,
                                focusNode: _estEndDtFocus,
                                fromDate: _parseDate(_estStartDtCtrl.text),
                                errorText: _estDateError,
                                onDateChanged: (date) => _validateEstDates(),
                                onValidationError:
                                    (error) =>
                                        setState(() => _estDateError = error),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CustomDateField(
                                label: 'Actual Start Dt',
                                controller: _actualStartDtCtrl,
                                focusNode: _actualStartDtFocus,
                                onDateChanged: (date) => _validateActualDates(),
                                onValidationError:
                                    (error) => setState(
                                      () => _actualDateError = error,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomDateField(
                                label: 'Actual End Dt',
                                controller: _actualEndDtCtrl,
                                focusNode: _actualEndDtFocus,
                                fromDate: _parseDate(_actualStartDtCtrl.text),
                                errorText: _actualDateError,
                                onDateChanged: (date) => _validateActualDates(),
                                onValidationError:
                                    (error) => setState(
                                      () => _actualDateError = error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        CustomSearchableDropdown(
                          label: 'Process',
                          controller: _processCtrl,
                          items:
                              _processes
                                  .map((p) => {'key': p, 'name': p})
                                  .toList(),
                          selected:
                              _selectedProcess != null
                                  ? {
                                    'key': _selectedProcess!,
                                    'name': _selectedProcess!,
                                  }
                                  : null,
                          onChanged:
                              (v) =>
                                  setState(() => _selectedProcess = v?['name']),
                          focusNode: _processFocus,
                          showClearButton: true,
                          allowClear: true,
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
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
                                      title: const Text(
                                        'Partial',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: 'Partial',
                                      groupValue: _stockPickup,
                                      onChanged:
                                          (value) => setState(
                                            () => _stockPickup = value!,
                                          ),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text(
                                        'Ready',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      value: 'Ready',
                                      groupValue: _stockPickup,
                                      onChanged:
                                          (value) => setState(
                                            () => _stockPickup = value!,
                                          ),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text(
                                  'Received As Finished',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: _receivedAsFinished,
                                onChanged:
                                    (value) => setState(
                                      () => _receivedAsFinished = value!,
                                    ),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text(
                                  'ReProcess',
                                  style: TextStyle(fontSize: 13),
                                ),
                                value: _reProcess,
                                onChanged:
                                    (value) =>
                                        setState(() => _reProcess = value!),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
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
                      InkWell(
                        onTap: _addFinishDetail,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.checklist,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.1,
                                      ),
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
                                  color: AppColors.primaryColor.withOpacity(
                                    0.1,
                                  ),
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
                      if (_finishDetailsList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: List.generate(_finishDetailsList.length, (
                              index,
                            ) {
                              return _buildFinishCard(
                                index,
                                _finishDetailsList[index],
                              );
                            }),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No finish details added',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Financial Details Card
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
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Gross Amt',
                                controller: _grossAmtCtrl,
                                focusNode: FocusNode(),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Oth Amt',
                                controller: _othAmtCtrl,
                                focusNode:
                                    _othAmtFocus, // Use the dedicated focus node
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _calculateNetAmt();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'GST Perc (%)',
                                controller: _gstPercCtrl,
                                focusNode:
                                    _gstPercFocus, // Use the dedicated focus node
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _calculateNetAmt();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'GST Amt',
                                controller: _gstAmtCtrl,
                                focusNode: FocusNode(),
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Net Amount with maroon color bold
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF800000).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF800000).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'NET AMOUNT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF800000),
                                ),
                              ),
                              Text(
                                '₹${_netAmtCtrl.text}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF800000),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(),
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                      backgroundColor: Colors.grey.shade50,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _saveJobOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherProcessForm() {
    return Column(
      children: [
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
                    const Text(
                      'OTHER PROCESS DETAILS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Divider(height: 20),
                    CustomSearchableDropdown(
                      label: 'Process',
                      controller: _otherProcessCtrl,
                      items: _otherProcessesList,
                      selected: _selectedOtherProcess,
                      onChanged:
                          (v) => setState(() => _selectedOtherProcess = v),
                      focusNode: FocusNode(),
                      isRequired: true,
                      showClearButton: true,
                      allowClear: true,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Job Rate',
                      controller: _jobRateCtrl,
                      focusNode: FocusNode(),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Job Amt',
                      controller: _jobAmtCtrl,
                      focusNode: FocusNode(),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Remark',
                      controller: _remarkCtrl,
                      focusNode: FocusNode(),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(),
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                      backgroundColor: Colors.grey.shade50,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _saveOtherProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
