import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    fetchDropdowns();
  }

  Future<void> fetchDropdowns() async {
    try {
      final results = await Future.wait([
        ApiService.fetchLedgers(ledCat: 'L', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchStations(coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchLedgers(ledCat: 'B', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchLedgers(ledCat: 'T', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchLedgers(ledCat: 'S', coBrId: UserSession.coBrId ?? ''),
        ApiService.fetchPayTerms(coBrId: UserSession.coBrId ?? ''),
      ]);

      setState(() {
        salesTypes = List<KeyName>.from(results[0]['result']);
        stations = List<KeyName>.from(results[1]['result']);
        brokers = List<KeyName>.from(results[2]['result']);
        transporters = List<KeyName>.from(results[3]['result']);
        salesPersons = List<KeyName>.from(results[4]['result']);
        paymentTerms = List<KeyName>.from(results[5]['result']);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load dropdowns: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double dialogWidth = constraints.maxWidth * 0.9;
        if (dialogWidth > 600) dialogWidth = 600;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth, minWidth: 300),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Customer Master",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    buildTextField("Party Name", partyNameController),
                    buildTextField("Contact Person", contactPersonController),
                    buildTextField(
                      "Whatsapp No",
                      whatsappController,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return "Please enter WhatsApp number";
                        if (val.length != 10)
                          return "Enter exactly 10 digit number";
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    buildDropdown(
                      "Sales Type",
                      salesTypes,
                      selectedSalesType,
                      (val) => setState(() => selectedSalesType = val),
                    ),
                    buildTextField(
                      "GST No",
                      gstController,
                      validator:
                          (val) =>
                              val!.length > 15 ? "Max 15 characters" : null,
                    ),
                    buildTextField("Address", addressController, maxLines: 3),
                    buildDropdown(
                      "Station",
                      stations,
                      selectedStation,
                      (val) => setState(() => selectedStation = val),
                    ),
                    buildDropdown(
                      "Broker",
                      brokers,
                      selectedBroker,
                      (val) => setState(() => selectedBroker = val),
                    ),
                    buildDropdown(
                      "Transporter",
                      transporters,
                      selectedTransporter,
                      (val) => setState(() => selectedTransporter = val),
                    ),
                    buildDropdown(
                      "SalesPerson",
                      salesPersons,
                      selectedSalesPerson,
                      (val) => setState(() => selectedSalesPerson = val),
                    ),
                    buildDropdown(
                      "Payment Terms",
                      paymentTerms,
                      selectedPaymentTerms,
                      (val) => setState(() => selectedPaymentTerms = val),
                      validator:
                          null, // Explicitly set validator to null to make it optional
                    ),
                    buildTextField(
                      "Credit Days",
                      creditDaysController,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: ElevatedButton(
                            onPressed: onSave,
                            style: ElevatedButton.styleFrom(
                              //  backgroundColor: Colors.blue,
                            ),
                            child: Text(
                              "Save",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: 50),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              // backgroundColor: Colors.red,
                            ),
                            child: Text(
                              "Close",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildDropdown(
    String label,
    List<KeyName> items,
    KeyName? selected,
    Function(KeyName?) onChanged, {
    String? Function(KeyName?)? validator, // Add optional validator parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<KeyName>(
        isExpanded: true,
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items:
            items
                .map(
                  (item) => DropdownMenuItem<KeyName>(
                    value: item,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        validator: validator, // Use the passed validator (can be null)
      ),
    );
  }

Future<void> onSave() async {
  if (_formKey.currentState!.validate()) {
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
      "salespersonDDL": selectedSalesPerson?.key ?? '', // This ensures empty string if null
      "paymenttermsDDL": selectedPaymentTerms?.key ?? '',
      "creditdays": creditDaysController.text,
      "createddate": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
    };

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        // Convert data to JSON string
        final dataJson = jsonEncode(data);

        // Prepare request body
        final requestBody = {
          "coBrId": UserSession.coBrId ?? '',
          "userId": UserSession.userName ?? '',
          "fcYrId": UserSession.userFcYr ?? '',
          "data2": dataJson,
        };

        // Make API call
        final response = await http.post(
          Uri.parse('${AppConstants.BASE_URL}/orderBooking/InsertCust'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        // Close loading indicator
        Navigator.pop(context);

        if (response.statusCode == 200) {
          // Show success alert
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text("Success"),
                  content: Text("Customer added successfully!"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close alert dialog
                        Navigator.of(
                          context,
                        ).pop(true); // Close CustomerMasterDialog
                      },
                      child: Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create customer: ${response.body}'),
            ),
          );
        }
      } catch (e) {
        // Close loading indicator if open
        if (Navigator.canPop(context)) Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
