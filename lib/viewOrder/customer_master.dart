import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/keyName.dart';
import 'package:vrs_erp/services/app_services.dart';

class CustomerMasterDialog extends StatefulWidget {
  @override
  _CustomerMasterDialogState createState() => _CustomerMasterDialogState();
}

class _CustomerMasterDialogState extends State<CustomerMasterDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController partyNameController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController creditDaysController = TextEditingController();

  KeyName? selectedSalesType;
  KeyName? selectedStation;
  KeyName? selectedBroker;
  KeyName? selectedTransporter;
  KeyName? selectedSalesPerson;
  KeyName? selectedPaymentTerms;

  List<KeyName> salesTypes = [];
  List<KeyName> stations = [];
  List<KeyName> brokers = [];
  List<KeyName> transporters = [];
  List<KeyName> salesPersons = [];
  List<KeyName> paymentTerms = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDropdowns();
  }

  Future<void> fetchDropdowns() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchLedgers(ledCat: 'L', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchStations(coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchLedgers(ledCat: 'B', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchLedgers(ledCat: 'T', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchLedgers(ledCat: 'S', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchPayTerms(coBrId: UserSession.coBrId ?? ''),
      ]);

      if (mounted) {
        setState(() {
          salesTypes = List<KeyName>.from(results[0]['result']);
          stations = List<KeyName>.from(results[1]['result']);
          brokers = List<KeyName>.from(results[2]['result']);
          transporters = List<KeyName>.from(results[3]['result']);
          salesPersons = List<KeyName>.from(results[4]['result']);
          paymentTerms = List<KeyName>.from(results[5]['result']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dropdowns: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2196F3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Customer Master",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: Colors.grey.shade300, height: 1),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildTextField("Party Name", partyNameController),
                            buildTextField("Contact Person", contactPersonController),
                            buildTextField(
                              "Whatsapp No",
                              whatsappController,
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                if (val == null || val.isEmpty) return "Please enter WhatsApp number";
                                if (val.length != 10) return "Enter exactly 10 digit number";
                                return null;
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                            
                            buildDropdown("Sales Type", salesTypes, selectedSalesType, (val) {
                              setState(() => selectedSalesType = val);
                            }),
                            
                            buildTextField("GST No", gstController, validator: (val) => val!.length > 15 ? "Max 15 characters" : null),
                            buildTextField("Address", addressController, maxLines: 2),
                            
                            buildDropdown("Station", stations, selectedStation, (val) {
                              setState(() => selectedStation = val);
                            }),
                            
                            buildDropdown("Broker", brokers, selectedBroker, (val) {
                              setState(() => selectedBroker = val);
                            }),
                            
                            buildDropdown("Transporter", transporters, selectedTransporter, (val) {
                              setState(() => selectedTransporter = val);
                            }),
                            
                            buildDropdown("SalesPerson", salesPersons, selectedSalesPerson, (val) {
                              setState(() => selectedSalesPerson = val);
                            }),
                            
                            buildDropdown("Payment Terms", paymentTerms, selectedPaymentTerms, (val) {
                              setState(() => selectedPaymentTerms = val);
                            }),
                            
                            buildTextField("Credit Days", creditDaysController, keyboardType: TextInputType.number),
                            
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
            ),
            
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF2196F3), width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget buildDropdown(
    String label,
    List<KeyName> items,
    KeyName? selected,
    Function(KeyName?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownSearch<KeyName>(
        items: items,
        selectedItem: selected,
        onChanged: onChanged,
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search $label",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              isDense: true,
            ),
          ),
          itemBuilder: (context, item, isSelected) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 13)),
                     //   Text("Code: ${item.key}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          constraints: const BoxConstraints(maxHeight: 300),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF2196F3), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        dropdownButtonProps: const DropdownButtonProps(icon: Icon(Icons.keyboard_arrow_down)),
        dropdownBuilder: (context, selectedItem) {
          if (selectedItem == null) {
            return Text("Select $label", style: const TextStyle(fontSize: 13, color: Colors.grey));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selectedItem.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
           //   Text(selectedItem.key, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          );
        },
        filterFn: (item, filter) {
          if (filter.isEmpty) return true;
          final searchTerm = filter.toLowerCase();
          return item.name.toLowerCase().contains(searchTerm) || item.key.toLowerCase().contains(searchTerm);
        },
        compareFn: (item, selectedItem) => item.key == selectedItem?.key,
      ),
    );
  }

  Future<void> onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        "partyname": partyNameController.text,
        "contactperson": contactPersonController.text,
        "whatsappno": whatsappController.text,
        "salestypeDDL": selectedSalesType?.key ?? '',
        "gstno": gstController.text,
        "address": addressController.text,
        "stationDDL": selectedStation?.key ?? '',
        "brokerDDL": selectedBroker?.key ?? '',
        "transportDDL": selectedTransporter?.key ?? '',
        "salespersonDDL": selectedSalesPerson?.key ?? '',
        "paymenttermsDDL": selectedPaymentTerms?.key ?? '',
        "creditdays": creditDaysController.text,
        "createddate": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
      };

      try {
        final dataJson = jsonEncode(data);
        final requestBody = {
          "coBrId": UserSession.coBrId ?? '',
          "userId": UserSession.userName ?? '',
          "fcYrId": UserSession.userFcYr ?? '',
          "data2": dataJson,
        };

        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/orderBooking/InsertCust'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (response.statusCode == 200) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Success"),
                content: const Text("Customer added successfully!"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("OK", style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create customer: ${response.body}'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}