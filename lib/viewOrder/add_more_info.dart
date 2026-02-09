import 'dart:async';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/item.dart';
import 'package:vrs_erp/services/app_services.dart';
import 'package:vrs_erp/models/PytTermDisc.dart';
import 'package:vrs_erp/models/salesman.dart';
import 'package:vrs_erp/models/consignee.dart';

class AddMoreInfoDialog extends StatefulWidget {
  final List<Map<String, String>> salesPersonList;
  final String? partyLedKey;
  final String? pytTermDiscKey;
  final String? salesPersonKey;
  final int? creditPeriod;
  final String? salesLedKey;
  final String? ledgerName;
  final Map<String, dynamic>? additionalInfo;
  final List<Consignee> consignees;
  final List<PytTermDisc> paymentTerms;
  final List<Item> bookingTypes;
  final Function(Map<String, dynamic>) onValueChanged;

  const AddMoreInfoDialog({
    super.key,
    required this.salesPersonList,
    required this.partyLedKey,
    this.pytTermDiscKey,
    this.salesPersonKey,
    this.creditPeriod,
    this.salesLedKey,
    this.ledgerName,
    this.additionalInfo,
    required this.consignees,
    required this.paymentTerms,
    required this.bookingTypes,
    required this.onValueChanged,
  });

  @override
  _AddMoreInfoDialogState createState() => _AddMoreInfoDialogState();
}

class _AddMoreInfoDialogState extends State<AddMoreInfoDialog> {
  late DateTime _baseDate;
  Consignee? _selectedConsignee;
  String? _selectedPaymentTerms;
  String? _selectedBookingType;
  String? _selectedSalesmanKey;
  String? _selectedSalesmanName;

  final TextEditingController _paymentDaysController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isLoadingBookingTypes = false;
  Item? _selectedBookingTypeItem;
  String? _selectedPytTermDiscKey;
  List<Item> _bookingTypes = [];

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _baseDate = DateTime.now();

    // Precompute initial values
    _paymentDaysController.text = widget.creditPeriod?.toString() ??
        widget.additionalInfo?['paymentdays'] ??
        '0';
    _dateController.text =
        widget.additionalInfo?['date'] ?? _formatDate(_baseDate);
    _dueDateController.text =
        widget.additionalInfo?['duedate'] ?? _formatDate(_baseDate);
    _referenceNoController.text = widget.additionalInfo?['refno'] ?? '';
    _selectedPytTermDiscKey =
        widget.pytTermDiscKey ?? widget.additionalInfo?['paymentterms'];
    _selectedBookingType = widget.additionalInfo?['bookingtype'];
    _selectedSalesmanKey =
        widget.salesPersonKey ?? widget.additionalInfo?['salesman'];
    _selectedSalesmanName = widget.salesPersonList.firstWhere(
      (e) => e['ledKey'] == _selectedSalesmanKey,
      orElse: () => {'ledName': ''},
    )['ledName'];

    if (widget.additionalInfo?['consignee']?.isNotEmpty ?? false) {
      _initializeConsignee();
    }

    // Add debounced listeners
    _paymentDaysController.addListener(_debouncedUpdateDueDate);
    _dueDateController.addListener(_debouncedUpdatePaymentDays);
    _dateController.addListener(_debouncedUpdatePaymentDays);

    // Load booking types
    _loadBookingTypes();
  }

  void _initializeConsignee() {
    _selectedConsignee = widget.consignees.firstWhere(
      (c) => c.ledKey == widget.additionalInfo!['consignee'],
      orElse: () => Consignee(
        ledKey: '',
        ledName: '',
        stnKey: '',
        stnName: '',
        paymentTermsKey: '',
        paymentTermsName: '',
        pytTermDiscdays: '0',
      ),
    );
    if (_selectedConsignee?.paymentTermsKey.isNotEmpty ?? false) {
      _selectedPytTermDiscKey = _selectedConsignee!.paymentTermsKey;
      _selectedPaymentTerms = _selectedConsignee!.paymentTermsName;
    }
  }

  Future<void> _loadBookingTypes() async {
    if (widget.bookingTypes.isNotEmpty) {
      setState(() {
        _bookingTypes = widget.bookingTypes;
        _selectInitialBookingType();
      });
      return;
    }

    setState(() => _isLoadingBookingTypes = true);
    try {
      final rawData = await ApiService.fetchBookingTypes(coBrId: UserSession.coBrId??'');
      final data = (rawData as List)
          .map((json) => Item(
                itemKey: json['key'],
                itemName: json['name'],
                itemSubGrpKey: '',
              ))
          .toList();
      setState(() {
        _bookingTypes = data;
        _selectInitialBookingType();
      });
    } catch (e) {
      print('Failed to load booking types: $e');
    } finally {
      setState(() => _isLoadingBookingTypes = false);
    }
  }

  void _selectInitialBookingType() {
    if (_bookingTypes.isNotEmpty && _selectedBookingType != null) {
      _selectedBookingTypeItem = _bookingTypes.firstWhere(
        (item) => item.itemKey == _selectedBookingType,
        orElse: () => _bookingTypes[0],
      );
    }
  }

  void _debouncedUpdateDueDate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final days = int.tryParse(_paymentDaysController.text) ?? 0;
      final newDueDate = _baseDate.add(Duration(days: days));
      _dueDateController.text = _formatDate(newDueDate);
    });
  }

  void _debouncedUpdatePaymentDays() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      final dateStr = _dateController.text;
      final dueDateStr = _dueDateController.text;

      final baseDate = _parseDate(dateStr);
      final dueDate = _parseDate(dueDateStr);

      if (baseDate != null && dueDate != null) {
        _baseDate = baseDate;
        final days = dueDate.difference(baseDate).inDays;
        _paymentDaysController.text = days.toString();
      }
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _parseDate(controller.text) ?? _baseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = _formatDate(picked);
          if (label == 'Date') {
            _baseDate = picked;
            _debouncedUpdateDueDate();
          } else if (label == 'Due Date') {
            _debouncedUpdatePaymentDays();
          }
        }
      },
    );
  }

  Widget _buildConsigneeDropdown() {
    return DropdownSearch<Consignee>(
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        itemBuilder: _consigneeItemBuilder,
      ),
      items: widget.consignees,
      itemAsString: (item) => item.ledName ?? '',
      selectedItem: _selectedConsignee,
      onChanged: (Consignee? value) {
        if (value != _selectedConsignee) {
          setState(() {
            _selectedConsignee = value;
            if (value?.paymentTermsKey.isNotEmpty ?? false) {
              _selectedPytTermDiscKey = value!.paymentTermsKey;
              _selectedPaymentTerms = value.paymentTermsName;
            }
          });
        }
      },
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Consignee',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  static Widget _consigneeItemBuilder(
      BuildContext context, Consignee item, bool isSelected) {
    return ListTile(title: Text(item.ledName ?? ''));
  }

  Widget _buildPaymentTermsDropdown() {
    return DropdownSearch<PytTermDisc>(
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        itemBuilder: _paymentTermsItemBuilder,
      ),
      items: widget.paymentTerms,
      itemAsString: (item) => item.name,
      selectedItem: widget.paymentTerms.firstWhere(
        (e) => e.key == _selectedPytTermDiscKey,
        orElse: () => PytTermDisc(key: '', name: ''),
      ),
      onChanged: (PytTermDisc? value) {
        if (value?.key != _selectedPytTermDiscKey) {
          setState(() {
            _selectedPytTermDiscKey = value?.key;
            _selectedPaymentTerms = value?.name;
          });
        }
      },
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Payment Terms',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  static Widget _paymentTermsItemBuilder(
      BuildContext context, PytTermDisc item, bool isSelected) {
    return ListTile(title: Text(item.name));
  }

  Widget _buildBookingTypeDropdown() {
    return _isLoadingBookingTypes
        ? const Center(child: CircularProgressIndicator())
        : DropdownButton<Item>(
            value: _selectedBookingTypeItem,
            hint: const Text("Select booking type"),
            isExpanded: true,
            items: _bookingTypes.map((Item item) {
              return DropdownMenuItem<Item>(
                value: item,
                child: Text(item.itemName),
              );
            }).toList(),
            onChanged: (Item? newValue) {
              if (newValue != _selectedBookingTypeItem) {
                setState(() {
                  _selectedBookingTypeItem = newValue;
                  _selectedBookingType = newValue?.itemKey;
                });
              }
            },
          );
  }

  Widget _buildSalesmanDropdown() {
    final salesmen = widget.salesPersonList
        .map((e) => Salesman(key: e['ledKey'] ?? '', name: e['ledName'] ?? ''))
        .toList();

    return DropdownSearch<Salesman>(
      popupProps: const PopupProps.menu(
        showSearchBox: true,
        itemBuilder: _salesmanItemBuilder,
      ),
      items: salesmen,
      itemAsString: (item) => item.name,
      selectedItem: salesmen.firstWhere(
        (e) => e.key == _selectedSalesmanKey,
        orElse: () => Salesman(key: '', name: ''),
      ),
      onChanged: (Salesman? value) {
        if (value?.key != _selectedSalesmanKey) {
          setState(() {
            _selectedSalesmanKey = value?.key ?? '';
            _selectedSalesmanName = value?.name;
          });
        }
      },
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Salesman Name',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  static Widget _salesmanItemBuilder(
      BuildContext context, Salesman item, bool isSelected) {
    return ListTile(title: Text(item.name));
  }

  void _saveFormData() {
    final formData = {
      'consignee': _selectedConsignee?.ledKey ?? '',
      'station': _selectedConsignee?.stnKey ?? '',
      'paymentterms': _selectedPytTermDiscKey ?? '',
      'paymentdays': _paymentDaysController.text,
      'duedate': _dueDateController.text,
      'refno': _referenceNoController.text,
      'date': _dateController.text,
      'bookingtype': _selectedBookingType ?? '',
      'salesman': _selectedSalesmanKey ?? '',
    };
    widget.onValueChanged(formData);
    Navigator.pop(context, formData);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _paymentDaysController.removeListener(_debouncedUpdateDueDate);
    _dueDateController.removeListener(_debouncedUpdatePaymentDays);
    _dateController.removeListener(_debouncedUpdatePaymentDays);
    _paymentDaysController.dispose();
    _dueDateController.dispose();
    _referenceNoController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Add More Info",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildConsigneeDropdown(),
              const SizedBox(height: 12),
              _buildPaymentTermsDropdown(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField("Payment Days", _paymentDaysController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField("Due Date", _dueDateController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField("Reference No", _referenceNoController),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField("Date", _dateController)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSalesmanDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBookingTypeDropdown()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _saveFormData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text("OK", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text("Close", style: TextStyle(color: Colors.white)),
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