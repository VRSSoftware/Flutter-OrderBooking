import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_widgets.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/AccountReport_Services.dart';

// Filter field IDs
enum FilterFieldId {
  customerVendorLedgerRadio,
  state,
  city,
  group,
  subGroup,
  ledger,
  broker,
  radioSummaryDetail,
  checkBoxBillWise,
  checkBoxNarration,
  checkBoxLedgerWise,
  checkBoxDueOnly,
  checkBoxAgeWise,
  checkBoxShowOverdueOnly,
}

// Filter configuration for each report type
const Map<String, List<FilterFieldId>> reportFilterConfig = {
  'CashBook': [
    FilterFieldId.ledger,
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxNarration,
  ],
  'BankBook': [
    FilterFieldId.ledger,
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxNarration,
  ],
  'Ledger': [
    FilterFieldId.customerVendorLedgerRadio,
    FilterFieldId.state,
    FilterFieldId.city,
    FilterFieldId.group,
    FilterFieldId.subGroup,
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.ledger,
    FilterFieldId.checkBoxBillWise,
    FilterFieldId.checkBoxNarration,
  ],
  'GroupSummary': [
    FilterFieldId.group,
    FilterFieldId.subGroup,
    FilterFieldId.radioSummaryDetail,
  ],
  'GroupVoucher': [
    FilterFieldId.group,
    FilterFieldId.subGroup,
    FilterFieldId.radioSummaryDetail,
  ],
  'TrialBalance': [
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxLedgerWise,
    FilterFieldId.checkBoxDueOnly,
  ],
  'Receivable': [
    FilterFieldId.ledger,
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxShowOverdueOnly,
    FilterFieldId.checkBoxAgeWise,
  ],
  'Payable': [
    FilterFieldId.ledger,
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxShowOverdueOnly,
    FilterFieldId.checkBoxAgeWise,
  ],
  'DayBook': [
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxNarration,
    FilterFieldId.checkBoxBillWise,
  ],
  'ProfitLoss': [FilterFieldId.checkBoxLedgerWise],
  'BalanceSheet': [FilterFieldId.checkBoxLedgerWise],
  'BrokerCommReceipt': [
    FilterFieldId.state,
    FilterFieldId.city,
    FilterFieldId.ledger,
    FilterFieldId.broker,
  ],
  'OutstandingRemainder': [
    FilterFieldId.state,
    FilterFieldId.city,
    FilterFieldId.ledger,
  ],
  'CustomerLedger': [
    FilterFieldId.state,
    FilterFieldId.city,
    FilterFieldId.ledger,
  ],
  'CustomerLedgerBillWise': [
    FilterFieldId.state,
    FilterFieldId.city,
    FilterFieldId.ledger,
  ],
  'GroupTrialBalance': [
    FilterFieldId.group,
    FilterFieldId.subGroup,
    FilterFieldId.ledger,
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxLedgerWise,
    FilterFieldId.checkBoxDueOnly,
  ],
  'JournalRegister': [
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxBillWise,
    FilterFieldId.checkBoxNarration,
  ],
  'DebitNoteRegister': [
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxBillWise,
    FilterFieldId.checkBoxNarration,
  ],
  'CreditNoteRegister': [
    FilterFieldId.radioSummaryDetail,
    FilterFieldId.checkBoxBillWise,
    FilterFieldId.checkBoxNarration,
  ],
};

// Radio options for ledger type selection
const List<Map<String, dynamic>> ledgerTypeRadioOptions = [
  {'value': 'customer', 'label': 'Customer'},
  {'value': 'vendor', 'label': 'Vendor'},
  {'value': 'ledger', 'label': 'Ledger'},
  {'value': 'all', 'label': 'All'},
];

class CommonFilterPage extends StatefulWidget {
  final String title;
  final String reportType;
  final VoidCallback onApply;
  final VoidCallback? onClear;

  // Data for dropdowns
  final List<KeyName>? customers;
  final List<KeyName>? vendors;
  final List<KeyName>? ledgers;
  final List<KeyName>? banks;
  final List<KeyName>? states;
  final List<KeyName>? cities;
  final List<KeyName>? groups;
  final List<KeyName>? subGroups;
  final List<KeyName>? brokers;

  // Initial selected values
  final String? initialLedgerType;
  final KeyName? initialCustomer;
  final KeyName? initialVendor;
  final KeyName? initialLedger;
  final KeyName? initialBank;
  final String? initialReportType;
  final bool? initialShowBillWise;
  final bool? initialShowNarration;
  final bool? initialShowLedgerWise;
  final bool? initialShowDueOnly;
  final bool? initialShowAgeWise;
  final bool? initialShowOverdueOnly;

  // For multi-select
  final List<KeyName>? initialStates;
  final List<KeyName>? initialCities;
  final List<KeyName>? initialGroups;
  final List<KeyName>? initialSubGroups;
  final List<KeyName>? initialLedgers;
  final List<KeyName>? initialCustomers;
  final List<KeyName>? initialVendors;
  final List<KeyName>? initialBanks;
  final List<KeyName>? initialBrokers;

  // Callbacks
  final Function(String?)? onLedgerTypeChanged;
  final Function(List<KeyName>?)? onCustomersChanged;
  final Function(List<KeyName>?)? onVendorsChanged;
  final Function(List<KeyName>?)? onLedgersChanged;
  final Function(List<KeyName>?)? onBanksChanged;
  final Function(List<KeyName>?)? onStatesChanged;
  final Function(List<KeyName>?)? onCitiesChanged;
  final Function(List<KeyName>?)? onGroupsChanged;
  final Function(List<KeyName>?)? onSubGroupsChanged;
  final Function(List<KeyName>?)? onBrokersChanged;
  final Function(String?)? onReportTypeChanged;
  final Function(bool?)? onBillWiseChanged;
  final Function(bool?)? onNarrationChanged;
  final Function(bool?)? onLedgerWiseChanged;
  final Function(bool?)? onDueOnlyChanged;
  final Function(bool?)? onAgeWiseChanged;
  final Function(bool?)? onOverdueOnlyChanged;

  const CommonFilterPage({
    super.key,
    required this.title,
    required this.reportType,
    required this.onApply,
    this.onClear,
    this.customers,
    this.vendors,
    this.ledgers,
    this.banks,
    this.states,
    this.cities,
    this.groups,
    this.subGroups,
    this.brokers,
    this.initialLedgerType,
    this.initialCustomer,
    this.initialVendor,
    this.initialLedger,
    this.initialBank,
    this.initialReportType,
    this.initialShowBillWise,
    this.initialShowNarration,
    this.initialShowLedgerWise,
    this.initialShowDueOnly,
    this.initialShowAgeWise,
    this.initialShowOverdueOnly,
    this.initialStates,
    this.initialCities,
    this.initialGroups,
    this.initialSubGroups,
    this.initialLedgers,
    this.initialCustomers,
    this.initialVendors,
    this.initialBanks,
    this.initialBrokers,
    this.onLedgerTypeChanged,
    this.onCustomersChanged,
    this.onVendorsChanged,
    this.onLedgersChanged,
    this.onBanksChanged,
    this.onStatesChanged,
    this.onCitiesChanged,
    this.onGroupsChanged,
    this.onSubGroupsChanged,
    this.onBrokersChanged,
    this.onReportTypeChanged,
    this.onBillWiseChanged,
    this.onNarrationChanged,
    this.onLedgerWiseChanged,
    this.onDueOnlyChanged,
    this.onAgeWiseChanged,
    this.onOverdueOnlyChanged,
  });

  @override
  State<CommonFilterPage> createState() => _CommonFilterPageState();
}

class _CommonFilterPageState extends State<CommonFilterPage> {
  // Local state for all filter values
  late String? _selectedLedgerType;
  late List<KeyName> _selectedCustomers;
  late List<KeyName> _selectedVendors;
  late List<KeyName> _selectedLedgers;
  late List<KeyName> _selectedBanks;
  late List<KeyName> _selectedStates;
  late List<KeyName> _selectedCities;
  late List<KeyName> _selectedGroups;
  late List<KeyName> _selectedSubGroups;
  late List<KeyName> _selectedBrokers;
  late String? _selectedReportType;
  late bool _showBillWise;
  late bool _showNarration;
  late bool _showLedgerWise;
  late bool _showDueOnly;
  late bool _showAgeWise;
  late bool _showOverdueOnly;

  // Filtered cities based on selected states
  List<KeyName> _filteredCities = [];

  // Filtered ledgers based on selected states/cities
  List<KeyName> _filteredLedgers = [];
  bool _isLoadingLedgers = false;

  // Filtered sub-groups based on selected groups
  List<KeyName> _filteredSubGroups = [];

  // Track which dropdown is currently open
  String? _openDropdownId;

  @override
  void initState() {
    super.initState();

    // Initialize local state from widget props
    _selectedLedgerType = widget.initialLedgerType ?? 'all';
    _selectedCustomers = List.from(widget.initialCustomers ?? []);
    _selectedVendors = List.from(widget.initialVendors ?? []);
    _selectedLedgers = List.from(widget.initialLedgers ?? []);
    _selectedBanks = List.from(widget.initialBanks ?? []);
    _selectedStates = List.from(widget.initialStates ?? []);
    _selectedCities = List.from(widget.initialCities ?? []);
    _selectedGroups = List.from(widget.initialGroups ?? []);
    _selectedSubGroups = List.from(widget.initialSubGroups ?? []);
    _selectedBrokers = List.from(widget.initialBrokers ?? []);
    _selectedReportType = widget.initialReportType ?? 'summary';
    _showBillWise = widget.initialShowBillWise ?? false;
    _showNarration = widget.initialShowNarration ?? false;
    _showLedgerWise = widget.initialShowLedgerWise ?? false;
    _showDueOnly = widget.initialShowDueOnly ?? false;
    _showAgeWise = widget.initialShowAgeWise ?? false;
    _showOverdueOnly = widget.initialShowOverdueOnly ?? false;

    // Initialize filtered cities as EMPTY
    _filteredCities = [];
    _filteredLedgers = widget.ledgers ?? [];
    _filteredSubGroups = widget.subGroups ?? [];

    // If there are initial states, filter cities and ledgers
    if (_selectedStates.isNotEmpty) {
      _filterCitiesByStates();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterLedgersByLocation();
      });
    }
  }

  // Filter cities based on selected states
  void _filterCitiesByStates() {
    setState(() {
      if (_selectedStates.isEmpty) {
        _filteredCities = [];
      } else {
        final selectedStateKeys =
            _selectedStates.map((state) => state.key.toString()).toSet();
        _filteredCities =
            (widget.cities ?? []).where((city) {
              final cityStateKey = city.extra?['State_Key']?.toString();
              return cityStateKey != null &&
                  selectedStateKeys.contains(cityStateKey);
            }).toList();

        // Clear selected cities that are no longer available
        _selectedCities =
            _selectedCities
                .where(
                  (selectedCity) => _filteredCities.any(
                    (city) => city.key == selectedCity.key,
                  ),
                )
                .toList();
      }
    });
  }

  // Filter ledgers based on selected states/cities
  // Filter ledgers based on selected states/cities
  Future<void> _filterLedgersByLocation() async {
    setState(() {
      _isLoadingLedgers = true;
    });

    try {
      // Priority 1: If cities are selected directly, use ONLY those city keys
      List<String> cityKeys = _selectedCities.map((city) => city.key).toList();

      // Priority 2: If NO cities selected but states are selected,
      // get ALL city keys for ALL selected states
      if (cityKeys.isEmpty && _selectedStates.isNotEmpty) {
        final selectedStateKeys =
            _selectedStates.map((state) => state.key).toSet();
        cityKeys =
            (widget.cities ?? [])
                .where((city) {
                  final cityStateKey = city.extra?['State_Key']?.toString();
                  return cityStateKey != null &&
                      selectedStateKeys.contains(cityStateKey);
                })
                .map((city) => city.key)
                .toList();
      }

      print('========== FILTERING LEDGERS ==========');
      print(
        'Selected States: ${_selectedStates.map((s) => '${s.name} (${s.key})')}',
      );
      print(
        'Selected Cities: ${_selectedCities.map((c) => '${c.name} (${c.key})')}',
      );
      print('City Keys to filter: $cityKeys');
      print('City Keys count: ${cityKeys.length}');

      List<KeyName> fetchedLedgers = [];

      // Case 1: No filters at all - show all ledgers
      if (_selectedStates.isEmpty && _selectedCities.isEmpty) {
        print('No filters - showing all ledgers');
        fetchedLedgers = widget.ledgers ?? [];
      }
      // Case 2: Has city keys - fetch ledgers for those cities
      else if (cityKeys.isNotEmpty) {
        print('Filtering by city keys: $cityKeys');

        if (widget.reportType == 'OutstandingRemainder') {
          fetchedLedgers =
              await AccountReportService.fetchOutstandingRemainderLedgers(
                cityKeys: cityKeys,
              );
        } else if (widget.reportType == 'CustomerLedger' ||
            widget.reportType == 'CustomerLedgerBillWise') {
          fetchedLedgers = await AccountReportService.fetchCustomerLedgers(
            cityKeys: cityKeys,
          );
        } else if (widget.reportType == 'BrokerCommReceipt') {
          fetchedLedgers = await AccountReportService.fetchBrokerLedgers(
            cityKeys: cityKeys,
          );
        } else {
          fetchedLedgers = widget.ledgers ?? [];
        }
      }
      // Case 3: States selected but NO cities found for those states
      else {
        print('States selected but no cities found - returning empty list');
        fetchedLedgers = [];
      }

      // Local debug: Check if any ledgers have matching Stn_Key
      if (cityKeys.isNotEmpty && fetchedLedgers.isEmpty) {
        print('WARNING: No ledgers found for city keys: $cityKeys');
        print('Available ledgers with Stn_Key:');
        (widget.ledgers ?? []).forEach((ledger) {
          if (ledger.extra?['Stn_Key']?.toString().isNotEmpty == true) {
            print('  ${ledger.name} -> Stn_Key: ${ledger.extra?['Stn_Key']}');
          }
        });
      }

      setState(() {
        _filteredLedgers = fetchedLedgers;
        // Clear selected ledgers that are no longer available
        _selectedLedgers =
            _selectedLedgers
                .where(
                  (selected) => fetchedLedgers.any(
                    (ledger) => ledger.key == selected.key,
                  ),
                )
                .toList();
      });

      print('Filtered ledgers count: ${fetchedLedgers.length}');

      if (fetchedLedgers.isEmpty &&
          (_selectedStates.isNotEmpty || _selectedCities.isNotEmpty) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No ledgers found for selected filters'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error filtering ledgers: $e');
    } finally {
      setState(() {
        _isLoadingLedgers = false;
      });
    }
  }

  // Filter sub-groups based on selected groups
  void _filterSubGroupsByGroups() {
    setState(() {
      final allSubGroups = widget.subGroups ?? [];

      if (_selectedGroups.isEmpty) {
        _filteredSubGroups = List.from(allSubGroups);
      } else {
        final selectedGroupIds =
            _selectedGroups.map((group) => group.key.toString()).toSet();
        _filteredSubGroups =
            allSubGroups.where((subGroup) {
              final subGroupGroupId = subGroup.extra?['AccGrp_Id']?.toString();
              return subGroupGroupId != null &&
                  selectedGroupIds.contains(subGroupGroupId);
            }).toList();

        _selectedSubGroups =
            _selectedSubGroups
                .where(
                  (selectedSubGroup) => _filteredSubGroups.any(
                    (subGroup) => subGroup.key == selectedSubGroup.key,
                  ),
                )
                .toList();
      }
    });
  }

  void _closeAllDropdowns() {
    setState(() {
      _openDropdownId = null;
    });
  }

  bool _hasActiveFilter(FilterFieldId field) {
    switch (field) {
      case FilterFieldId.customerVendorLedgerRadio:
        return _selectedLedgerType != 'all';
      case FilterFieldId.ledger:
        return _selectedLedgers.isNotEmpty;
      case FilterFieldId.broker:
        return _selectedBrokers.isNotEmpty;
      case FilterFieldId.radioSummaryDetail:
        return _selectedReportType != 'summary';
      case FilterFieldId.checkBoxBillWise:
        return _showBillWise == true;
      case FilterFieldId.checkBoxNarration:
        return _showNarration == true;
      case FilterFieldId.checkBoxLedgerWise:
        return _showLedgerWise == true;
      case FilterFieldId.checkBoxDueOnly:
        return _showDueOnly == true;
      case FilterFieldId.checkBoxAgeWise:
        return _showAgeWise == true;
      case FilterFieldId.checkBoxShowOverdueOnly:
        return _showOverdueOnly == true;
      case FilterFieldId.state:
        return _selectedStates.isNotEmpty;
      case FilterFieldId.city:
        return _selectedCities.isNotEmpty;
      case FilterFieldId.group:
        return _selectedGroups.isNotEmpty;
      case FilterFieldId.subGroup:
        return _selectedSubGroups.isNotEmpty;
      default:
        return false;
    }
  }

  int get _totalActiveFilters {
    int count = 0;
    final configFields = reportFilterConfig[widget.reportType] ?? [];
    for (var field in configFields) {
      if (_hasActiveFilter(field)) count++;
    }
    return count;
  }

  void _applyFilters() {
    widget.onLedgerTypeChanged?.call(_selectedLedgerType);
    widget.onCustomersChanged?.call(_selectedCustomers);
    widget.onVendorsChanged?.call(_selectedVendors);
    widget.onLedgersChanged?.call(_selectedLedgers);
    widget.onBanksChanged?.call(_selectedBanks);
    widget.onStatesChanged?.call(_selectedStates);
    widget.onCitiesChanged?.call(_selectedCities);
    widget.onGroupsChanged?.call(_selectedGroups);
    widget.onSubGroupsChanged?.call(_selectedSubGroups);
    widget.onBrokersChanged?.call(_selectedBrokers);
    widget.onReportTypeChanged?.call(_selectedReportType);
    widget.onBillWiseChanged?.call(_showBillWise);
    widget.onNarrationChanged?.call(_showNarration);
    widget.onLedgerWiseChanged?.call(_showLedgerWise);
    widget.onDueOnlyChanged?.call(_showDueOnly);
    widget.onAgeWiseChanged?.call(_showAgeWise);
    widget.onOverdueOnlyChanged?.call(_showOverdueOnly);
    widget.onApply();
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _selectedLedgerType = 'all';
      _selectedCustomers = [];
      _selectedVendors = [];
      _selectedLedgers = [];
      _selectedBanks = [];
      _selectedStates = [];
      _selectedCities = [];
      _selectedGroups = [];
      _selectedSubGroups = [];
      _selectedBrokers = [];
      _selectedReportType = 'summary';
      _showBillWise = false;
      _showNarration = false;
      _showLedgerWise = false;
      _showDueOnly = false;
      _showAgeWise = false;
      _showOverdueOnly = false;
      _filteredCities = [];
      _filteredLedgers = widget.ledgers ?? [];
      _filteredSubGroups = widget.subGroups ?? [];
    });

    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final configFields = reportFilterConfig[widget.reportType] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  children: [
                    for (var field in configFields) ...[
                      _buildFilterCard(field),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Apply Filters',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_totalActiveFilters > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_totalActiveFilters',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Widget _buildFilterCard(FilterFieldId field) {
    final hasActiveFilter = _hasActiveFilter(field);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasActiveFilter ? AppColors.primaryColor : Colors.grey.shade200,
          width: hasActiveFilter ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getCardTitle(field),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (hasActiveFilter)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 14, right: 14),
            child: _buildFilterField(field),
          ),
        ],
      ),
    );
  }

  String _getCardTitle(FilterFieldId field) {
    switch (field) {
      case FilterFieldId.customerVendorLedgerRadio:
        return 'Select Ledger Type';
      case FilterFieldId.state:
        return 'Select States';
      case FilterFieldId.city:
        return 'Select Cities';
      case FilterFieldId.group:
        return 'Select Groups';
      case FilterFieldId.subGroup:
        return 'Select Sub Groups';
      case FilterFieldId.ledger:
        return 'Select Ledgers';
      case FilterFieldId.broker:
        return 'Select Brokers';
      case FilterFieldId.radioSummaryDetail:
        return 'Report Type';
      case FilterFieldId.checkBoxBillWise:
        return 'Bill Wise';
      case FilterFieldId.checkBoxNarration:
        return 'Narration';
      case FilterFieldId.checkBoxLedgerWise:
        return 'Ledger Wise';
      case FilterFieldId.checkBoxDueOnly:
        return 'Due Only';
      case FilterFieldId.checkBoxAgeWise:
        return 'Age Wise';
      case FilterFieldId.checkBoxShowOverdueOnly:
        return 'Overdue Only';
      default:
        return '';
    }
  }

  Widget _buildFilterField(FilterFieldId field) {
    switch (field) {
      case FilterFieldId.customerVendorLedgerRadio:
        return Wrap(
          children:
              ledgerTypeRadioOptions.map((option) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: RadioListTile<String>(
                    title: Text(
                      option['label'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                    value: option['value'],
                    groupValue: _selectedLedgerType,
                    onChanged: (value) {
                      setState(() {
                        _selectedLedgerType = value;
                      });
                      widget.onLedgerTypeChanged?.call(value);
                    },
                    activeColor: AppColors.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                );
              }).toList(),
        );

      case FilterFieldId.state:
        return CommonMultiSelectDropdown<KeyName>(
          config: MultiSelectConfig<KeyName>(
            items: widget.states ?? [],
            selectedItems: _selectedStates,
            onChanged: (items) {
              setState(() {
                _selectedStates = items;
                _filterCitiesByStates();
                _filterLedgersByLocation();
              });
              widget.onStatesChanged?.call(items);
            },
            displayName: (keyName) => keyName.name ?? '',
            hintText: 'Select States',
            searchHintText: 'Search States',
            primaryColor: AppColors.primaryColor,
          ),
          onDropdownOpen: () {
            setState(() {
              _openDropdownId = 'state';
            });
          },
          onDropdownClose: () {
            setState(() {
              _openDropdownId = null;
            });
          },
        );

      case FilterFieldId.city:
        return IgnorePointer(
          ignoring: _selectedStates.isEmpty,
          child: Opacity(
            opacity: _selectedStates.isEmpty ? 0.5 : 1.0,
            child: CommonMultiSelectDropdown<KeyName>(
              config: MultiSelectConfig<KeyName>(
                items: _filteredCities,
                selectedItems: _selectedCities,
                onChanged: (items) {
                  setState(() {
                    _selectedCities = items;
                    _filterLedgersByLocation();
                  });
                  widget.onCitiesChanged?.call(items);
                },
                displayName: (keyName) => keyName.name ?? '',
                hintText:
                    _selectedStates.isEmpty
                        ? 'Select state first to see cities'
                        : (_filteredCities.isEmpty
                            ? 'No cities found for selected states'
                            : 'Select Cities'),
                searchHintText: 'Search Cities',
                primaryColor: AppColors.primaryColor,
              ),
              onDropdownOpen: () {
                setState(() {
                  _openDropdownId = 'city';
                });
              },
              onDropdownClose: () {
                setState(() {
                  _openDropdownId = null;
                });
              },
            ),
          ),
        );

      case FilterFieldId.group:
        return CommonMultiSelectDropdown<KeyName>(
          config: MultiSelectConfig<KeyName>(
            items: widget.groups ?? [],
            selectedItems: _selectedGroups,
            onChanged: (items) {
              setState(() {
                _selectedGroups = items;
                _filterSubGroupsByGroups();
              });
              widget.onGroupsChanged?.call(items);
            },
            displayName: (keyName) => keyName.name ?? '',
            hintText: 'Select Groups',
            searchHintText: 'Search Groups',
            primaryColor: AppColors.primaryColor,
          ),
          onDropdownOpen: () {
            setState(() {
              _openDropdownId = 'group';
            });
          },
          onDropdownClose: () {
            setState(() {
              _openDropdownId = null;
            });
          },
        );

      case FilterFieldId.subGroup:
        return CommonMultiSelectDropdown<KeyName>(
          config: MultiSelectConfig<KeyName>(
            items: _filteredSubGroups,
            selectedItems: _selectedSubGroups,
            onChanged: (items) {
              setState(() {
                _selectedSubGroups = items;
              });
              widget.onSubGroupsChanged?.call(items);
            },
            displayName: (keyName) => keyName.name ?? '',
            hintText:
                _filteredSubGroups.isEmpty && _selectedGroups.isNotEmpty
                    ? 'No sub-groups found for selected groups'
                    : 'Select Sub Groups',
            searchHintText: 'Search Sub Groups',
            primaryColor: AppColors.primaryColor,
          ),
          onDropdownOpen: () {
            setState(() {
              _openDropdownId = 'subgroup';
            });
          },
          onDropdownClose: () {
            setState(() {
              _openDropdownId = null;
            });
          },
        );

      case FilterFieldId.ledger:
        return Stack(
          children: [
            Opacity(
              opacity: _isLoadingLedgers ? 0.5 : 1.0,
              child: IgnorePointer(
                ignoring: _isLoadingLedgers,
                child: CommonMultiSelectDropdown<KeyName>(
                  config: MultiSelectConfig<KeyName>(
                    items: _filteredLedgers,
                    selectedItems: _selectedLedgers,
                    onChanged: (items) {
                      setState(() {
                        _selectedLedgers = items;
                      });
                      widget.onLedgersChanged?.call(items);
                    },
                    displayName: (keyName) => keyName.name ?? '',
                    hintText:
                        _isLoadingLedgers
                            ? 'Loading ledgers...'
                            : (_filteredLedgers.isEmpty &&
                                    (_selectedStates.isNotEmpty ||
                                        _selectedCities.isNotEmpty)
                                ? 'No ledgers found for selected filters'
                                : 'Select Ledgers'),
                    searchHintText: 'Search Ledgers',
                    primaryColor: AppColors.primaryColor,
                  ),
                  onDropdownOpen: () {
                    setState(() {
                      _openDropdownId = 'ledger';
                    });
                  },
                  onDropdownClose: () {
                    setState(() {
                      _openDropdownId = null;
                    });
                  },
                ),
              ),
            ),
            if (_isLoadingLedgers)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        );

      case FilterFieldId.broker:
        return CommonMultiSelectDropdown<KeyName>(
          config: MultiSelectConfig<KeyName>(
            items: widget.brokers ?? [],
            selectedItems: _selectedBrokers,
            onChanged: (items) {
              setState(() {
                _selectedBrokers = items;
              });
              widget.onBrokersChanged?.call(items);
            },
            displayName: (keyName) => keyName.name ?? '',
            hintText: 'Select Brokers',
            searchHintText: 'Search Brokers',
            primaryColor: AppColors.primaryColor,
          ),
          onDropdownOpen: () {
            setState(() {
              _openDropdownId = 'broker';
            });
          },
          onDropdownClose: () {
            setState(() {
              _openDropdownId = null;
            });
          },
        );

      case FilterFieldId.radioSummaryDetail:
        return Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(
                  'Summary',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                value: 'summary',
                groupValue: _selectedReportType,
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value;
                  });
                },
                activeColor: AppColors.primaryColor,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(
                  'Detail',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                value: 'detail',
                groupValue: _selectedReportType,
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value;
                  });
                },
                activeColor: AppColors.primaryColor,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        );

      case FilterFieldId.checkBoxBillWise:
        return CheckboxListTile(
          title: Text(
            'Show All Bill Wise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: _showBillWise,
          onChanged: (value) {
            setState(() {
              _showBillWise = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case FilterFieldId.checkBoxNarration:
        return CheckboxListTile(
          title: Text(
            'Show Narration',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: _showNarration,
          onChanged: (value) {
            setState(() {
              _showNarration = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case FilterFieldId.checkBoxLedgerWise:
        return CheckboxListTile(
          title: Text(
            'Show Ledger Wise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: _showLedgerWise,
          onChanged: (value) {
            setState(() {
              _showLedgerWise = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case FilterFieldId.checkBoxDueOnly:
        return CheckboxListTile(
          title: Text(
            'Show Due Only',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: _showDueOnly,
          onChanged: (value) {
            setState(() {
              _showDueOnly = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case FilterFieldId.checkBoxAgeWise:
        return CheckboxListTile(
          title: Text(
            'Age Wise',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: _showAgeWise,
          onChanged: (value) {
            setState(() {
              _showAgeWise = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );

      case FilterFieldId.checkBoxShowOverdueOnly:
        return CheckboxListTile(
          title: Text(
            'Show Overdue Only',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: _showOverdueOnly,
          onChanged: (value) {
            setState(() {
              _showOverdueOnly = value ?? false;
            });
          },
          activeColor: AppColors.primaryColor,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
    }
  }
}
