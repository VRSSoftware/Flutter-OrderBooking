import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vrs_erp/Accounts_Reports/Acc_Widgets/common_widgets.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/AccountReport_Services.dart';

class LedgerFilterPage extends StatefulWidget {
  final List<KeyName> ledgers;
  final List<KeyName> states;
  final List<KeyName> cities;
  final List<KeyName> groups;
  final List<KeyName> subGroups;

  final String initialLedgerType;
  final List<KeyName> initialLedgers;
  final List<KeyName> initialStates;
  final List<KeyName> initialCities;
  final List<KeyName> initialGroups;
  final List<KeyName> initialSubGroups;
  final String initialReportType;
  final bool initialBillWise;
  final bool initialNarration;

  final Function(String) onLedgerTypeChanged;
  final Function(List<KeyName>) onLedgersChanged;
  final Function(List<KeyName>) onStatesChanged;
  final Function(List<KeyName>) onCitiesChanged;
  final Function(List<KeyName>) onGroupsChanged;
  final Function(List<KeyName>) onSubGroupsChanged;
  final Function(String) onReportTypeChanged;
  final Function(bool) onBillWiseChanged;
  final Function(bool) onNarrationChanged;
  final VoidCallback onApply;
  final VoidCallback? onClear;

  const LedgerFilterPage({
    super.key,
    required this.ledgers,
    required this.states,
    required this.cities,
    required this.groups,
    required this.subGroups,
    required this.initialLedgerType,
    required this.initialLedgers,
    required this.initialStates,
    required this.initialCities,
    required this.initialGroups,
    required this.initialSubGroups,
    required this.initialReportType,
    required this.initialBillWise,
    required this.initialNarration,
    required this.onLedgerTypeChanged,
    required this.onLedgersChanged,
    required this.onStatesChanged,
    required this.onCitiesChanged,
    required this.onGroupsChanged,
    required this.onSubGroupsChanged,
    required this.onReportTypeChanged,
    required this.onBillWiseChanged,
    required this.onNarrationChanged,
    required this.onApply,
    this.onClear,
  });

  @override
  State<LedgerFilterPage> createState() => _LedgerFilterPageState();
}

class _LedgerFilterPageState extends State<LedgerFilterPage> {
  late String _selectedLedgerType;
  late List<KeyName> _selectedLedgers;
  late List<KeyName> _selectedStates;
  late List<KeyName> _selectedCities;
  late List<KeyName> _selectedGroups;
  late List<KeyName> _selectedSubGroups;
  late String _selectedReportType;
  late bool _showBillWise;
  late bool _showNarration;

  // Local ledgers list that can be updated dynamically
  List<KeyName> _availableLedgers = [];
  bool _isLoadingLedgers = false;
  
  // Filtered cities based on selected states
  List<KeyName> _filteredCities = [];

  // Unique key to force dropdown rebuild
  int _dropdownKey = 0;

  final List<Map<String, dynamic>> ledgerTypeOptions = [
    {'value': 'customer', 'label': 'Customer', 'ledCat': 'W', 'icon': Icons.people},
    {'value': 'vendor', 'label': 'Vendor', 'ledCat': 'V', 'icon': Icons.business},
    {'value': 'ledger', 'label': 'Ledger', 'ledCat': 'L', 'icon': Icons.book},
    {'value': 'all', 'label': 'All', 'ledCat': 'ALL', 'icon': Icons.apps},
  ];

  String? _getLedCat() {
    switch (_selectedLedgerType) {
      case 'customer':
        return 'W';
      case 'vendor':
        return 'V';
      case 'ledger':
        return 'L';
      case 'all':
        return 'ALL';
      default:
        return 'L';
    }
  }

  Future<void> _fetchLedgersByType() async {
    setState(() {
      _isLoadingLedgers = true;
    });

    try {
      final ledCat = _getLedCat();
      print('Fetching ledgers with ledCat: $ledCat');

      final fetchedLedgers = await AccountReportService.fetchLedgersByFilters(
        ledCat: ledCat,
      );

      setState(() {
        _availableLedgers = fetchedLedgers;
        _dropdownKey++;
        _selectedLedgers =
            _selectedLedgers
                .where(
                  (selected) => fetchedLedgers.any(
                    (ledger) => ledger.key == selected.key,
                  ),
                )
                .toList();
      });

      print('Fetched ${fetchedLedgers.length} ledgers');
    } catch (e) {
      print('Error fetching ledgers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching ledgers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLedgers = false;
      });
    }
  }

  // Filter cities based on selected states using the extra field
  void _filterCitiesByStates() {
    setState(() {
      if (_selectedStates.isEmpty) {
        // If no states selected, show all cities
        _filteredCities = List.from(widget.cities);
      } else {
        // Get selected state keys
        final selectedStateKeys = _selectedStates.map((state) => state.key.toString()).toSet();
        
        // Filter cities that belong to selected states using extra field
        _filteredCities = widget.cities.where((city) {
          final cityStateKey = city.extra?['State_Key']?.toString();
          return cityStateKey != null && selectedStateKeys.contains(cityStateKey);
        }).toList();
        
        print('Selected States: $selectedStateKeys');
        print('Filtered Cities Count: ${_filteredCities.length}');
        
        // Remove selected cities that are no longer in filtered list
        _selectedCities = _selectedCities
            .where((selectedCity) => _filteredCities.any((city) => city.key == selectedCity.key))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedLedgerType = widget.initialLedgerType;
    _selectedLedgers = List.from(widget.initialLedgers);
    _selectedStates = List.from(widget.initialStates);
    _selectedCities = List.from(widget.initialCities);
    _selectedGroups = List.from(widget.initialGroups);
    _selectedSubGroups = List.from(widget.initialSubGroups);
    _selectedReportType = widget.initialReportType;
    _showBillWise = widget.initialBillWise;
    _showNarration = widget.initialNarration;
    _availableLedgers = List.from(widget.ledgers);
    
    // Initialize filtered cities with all cities
    _filteredCities = List.from(widget.cities);
  }

  int get _totalActiveFilters {
    int count = 0;
    if (_selectedLedgerType != 'ledger') count++;
    if (_selectedLedgers.isNotEmpty) count++;
    if (_selectedStates.isNotEmpty) count++;
    if (_selectedCities.isNotEmpty) count++;
    if (_selectedGroups.isNotEmpty) count++;
    if (_selectedSubGroups.isNotEmpty) count++;
    if (_selectedReportType != 'summary') count++;
    if (_showBillWise) count++;
    if (_showNarration) count++;
    return count;
  }

  void _applyFilters() {
    widget.onLedgerTypeChanged(_selectedLedgerType);
    widget.onLedgersChanged(_selectedLedgers);
    widget.onStatesChanged(_selectedStates);
    widget.onCitiesChanged(_selectedCities);
    widget.onGroupsChanged(_selectedGroups);
    widget.onSubGroupsChanged(_selectedSubGroups);
    widget.onReportTypeChanged(_selectedReportType);
    widget.onBillWiseChanged(_showBillWise);
    widget.onNarrationChanged(_showNarration);
    widget.onApply();
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _selectedLedgerType = 'ledger';
      _selectedLedgers = [];
      _selectedStates = [];
      _selectedCities = [];
      _selectedGroups = [];
      _selectedSubGroups = [];
      _selectedReportType = 'summary';
      _showBillWise = false;
      _showNarration = false;
      _filteredCities = List.from(widget.cities);
    });
    _fetchLedgersByType();
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Ledger Filters',
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildLedgerTypeCard(),
                    const SizedBox(height: 12),
                    _buildStateDropdownCard(),
                    const SizedBox(height: 12),
                    _buildCityDropdownCard(),
                    const SizedBox(height: 12),
                    _buildGroupDropdownCard(),
                    const SizedBox(height: 12),
                    _buildSubGroupDropdownCard(),
                    const SizedBox(height: 12),
                    _buildReportTypeCard(),
                    const SizedBox(height: 12),
                    _buildLedgerDropdownCard(),
                    const SizedBox(height: 12),
                    _buildCheckboxCard(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerTypeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            child: Text(
              'Select Ledger Type',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 14, right: 14),
            child: Row(
              children: ledgerTypeOptions.map((option) {
                final isSelected = _selectedLedgerType == option['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedLedgerType = option['value'];
                      });
                      _fetchLedgersByType();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryColor : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            option['icon'],
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            option['label'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerDropdownCard() {
    return _buildCard(
      title: 'Select Ledgers',
      child: Stack(
        children: [
          Opacity(
            opacity: _isLoadingLedgers ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: _isLoadingLedgers,
              child: CommonMultiSelectDropdown<KeyName>(
                key: ValueKey(_dropdownKey),
                config: MultiSelectConfig<KeyName>(
                  items: _availableLedgers,
                  selectedItems: _selectedLedgers,
                  onChanged: (items) {
                    setState(() {
                      _selectedLedgers = items;
                    });
                  },
                  displayName: (keyName) => keyName.name ?? '',
                  hintText: _availableLedgers.isEmpty && !_isLoadingLedgers
                      ? 'No ledgers found'
                      : 'Select Ledgers',
                  searchHintText: 'Search Ledgers',
                  primaryColor: AppColors.primaryColor,
                ),
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
      ),
    );
  }

  Widget _buildStateDropdownCard() {
    return _buildCard(
      title: 'Select States',
      child: CommonMultiSelectDropdown<KeyName>(
        config: MultiSelectConfig<KeyName>(
          items: widget.states,
          selectedItems: _selectedStates,
          onChanged: (items) {
            setState(() {
              _selectedStates = items;
              _filterCitiesByStates(); // Filter cities when states change
            });
          },
          displayName: (keyName) => keyName.name ?? '',
          hintText: 'Select States',
          searchHintText: 'Search States',
          primaryColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildCityDropdownCard() {
    return _buildCard(
      title: 'Select Cities',
      child: CommonMultiSelectDropdown<KeyName>(
        config: MultiSelectConfig<KeyName>(
          items: _filteredCities,
          selectedItems: _selectedCities,
          onChanged: (items) {
            setState(() {
              _selectedCities = items;
            });
          },
          displayName: (keyName) => keyName.name ?? '',
          hintText: _filteredCities.isEmpty && _selectedStates.isNotEmpty
              ? 'No cities found for selected states'
              : 'Select Cities',
          searchHintText: 'Search Cities',
          primaryColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildGroupDropdownCard() {
    return _buildCard(
      title: 'Select Groups',
      child: CommonMultiSelectDropdown<KeyName>(
        config: MultiSelectConfig<KeyName>(
          items: widget.groups,
          selectedItems: _selectedGroups,
          onChanged: (items) {
            setState(() {
              _selectedGroups = items;
            });
          },
          displayName: (keyName) => keyName.name ?? '',
          hintText: 'Select Groups',
          searchHintText: 'Search Groups',
          primaryColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSubGroupDropdownCard() {
    return _buildCard(
      title: 'Select Sub Groups',
      child: CommonMultiSelectDropdown<KeyName>(
        config: MultiSelectConfig<KeyName>(
          items: widget.subGroups,
          selectedItems: _selectedSubGroups,
          onChanged: (items) {
            setState(() {
              _selectedSubGroups = items;
            });
          },
          displayName: (keyName) => keyName.name ?? '',
          hintText: 'Select Sub Groups',
          searchHintText: 'Search Sub Groups',
          primaryColor: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildReportTypeCard() {
    return _buildCard(
      title: 'Report Type',
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: Text('Summary', style: GoogleFonts.poppins(fontSize: 13)),
              value: 'summary',
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                });
              },
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: Text('Detail', style: GoogleFonts.poppins(fontSize: 13)),
              value: 'detail',
              groupValue: _selectedReportType,
              onChanged: (value) {
                setState(() {
                  _selectedReportType = value!;
                });
              },
              activeColor: AppColors.primaryColor,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxCard() {
    return _buildCard(
      title: 'Additional Options',
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(
              'Show All Bill Wise',
              style: GoogleFonts.poppins(fontSize: 13),
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
          ),
          CheckboxListTile(
            title: Text(
              'Show Narration',
              style: GoogleFonts.poppins(fontSize: 13),
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
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14, left: 14, right: 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
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
    );
  }
}