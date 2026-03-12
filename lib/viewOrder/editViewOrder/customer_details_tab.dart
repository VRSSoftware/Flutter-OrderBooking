// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:vrs_erp/models/CatalogOrderData.dart';
// import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

// class CustomerDetailTab extends StatefulWidget {
//   const CustomerDetailTab({super.key});

//   @override
//   State<CustomerDetailTab> createState() => _CustomerDetailTabState();
// }

// class _CustomerDetailTabState extends State<CustomerDetailTab> {
//   String? selectedBrokerKey;
//   String? selectedTransporterKey;

//   final TextEditingController commController = TextEditingController();
//   final TextEditingController deliveryDaysController = TextEditingController();
//   final TextEditingController deliveryDateController = TextEditingController();
//   final TextEditingController remarkController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();

//     if (EditOrderData.brokerList.any((item) => item['key'] == EditOrderData.brokerKey)) {
//       selectedBrokerKey = EditOrderData.brokerKey;
//     }

//     if (EditOrderData.transporterList.any((item) => item['key'] == EditOrderData.transporterKey)) {
//       selectedTransporterKey = EditOrderData.transporterKey;
//     }

//     commController.text = EditOrderData.commission;
//     deliveryDaysController.text = EditOrderData.deliveryDays;
//     deliveryDateController.text = EditOrderData.deliveryDate;
//     remarkController.text = EditOrderData.remark;

//     commController.addListener(updateEditOrderData);
//     deliveryDaysController.addListener(updateEditOrderData);
//     deliveryDateController.addListener(updateEditOrderData);
//     remarkController.addListener(updateEditOrderData);
//   }

//   void updateEditOrderData() {
//     EditOrderData.brokerKey = selectedBrokerKey ?? '';
//     EditOrderData.transporterKey = selectedTransporterKey ?? '';
//     EditOrderData.commission = commController.text;
//     EditOrderData.deliveryDays = deliveryDaysController.text;
//     EditOrderData.deliveryDate = deliveryDateController.text;
//     EditOrderData.remark = remarkController.text;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           buildReadOnlyField('Date', EditOrderData.detailsForEdit),
//           buildReadOnlyField('Party Name', EditOrderData.partyName),
//           const SizedBox(height: 10),
//           buildDropdownField(
//             label: 'Broker',
//             value: selectedBrokerKey,
//             items: EditOrderData.brokerList,
//             onChanged: (val) {
//               setState(() {
//                 selectedBrokerKey = val;
//                 updateEditOrderData();
//               });
//             },
//           ),
//           buildTextField('Commission %', commController, TextInputType.number),
//           buildDropdownField(
//             label: 'Transporter',
//             value: selectedTransporterKey,
//             items: EditOrderData.transporterList,
//             onChanged: (val) {
//               setState(() {
//                 selectedTransporterKey = val;
//                 updateEditOrderData();
//               });
//             },
//           ),
//           buildTextField('Delivery Days', deliveryDaysController, TextInputType.number),
//           GestureDetector(
//             onTap: pickDeliveryDate,
//             child: AbsorbPointer(
//               child: buildTextField('Delivery Date', deliveryDateController, TextInputType.text),
//             ),
//           ),
//           buildTextField('Remark', remarkController, TextInputType.text),
//         ],
//       ),
//     );
//   }

//   Widget buildReadOnlyField(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label),
//         Container(
//           width: double.infinity,
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade400),
//             borderRadius: BorderRadius.circular(5),
//             color: Colors.grey.shade100,
//           ),
//           child: Text(value),
//         ),
//       ],
//     );
//   }

//   Widget buildTextField(String label, TextEditingController controller, TextInputType type) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label),
//           const SizedBox(height: 6),
//           TextField(
//             controller: controller,
//             keyboardType: type,
//             decoration: InputDecoration(
//               border: OutlineInputBorder(),
//               isDense: true,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildDropdownField({
//     required String label,
//     required String? value,
//     required List<Map<String, String>> items,
//     required Function(String?) onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label),
//           const SizedBox(height: 6),
//           DropdownButtonFormField<String>(
//             value: value,
//             items: items.map((item) {
//               return DropdownMenuItem<String>(
//                 value: item['key'],
//                 child: Text(item['name'] ?? ''),
//               );
//             }).toList(),
//             onChanged: onChanged,
//             decoration: const InputDecoration(
//               border: OutlineInputBorder(),
//               isDense: true,
//               contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> pickDeliveryDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.tryParse(deliveryDateController.text) ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null) {
//       setState(() {
//         deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
//         updateEditOrderData();
//       });
//     }
//   }

//   @override
//   void dispose() {
//     commController.dispose();
//     deliveryDaysController.dispose();
//     deliveryDateController.dispose();
//     remarkController.dispose();
//     super.dispose();
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/models/CatalogOrderData.dart';
import 'package:vrs_erp/viewOrder/editViewOrder/edit_order_data.dart';

class CustomerDetailTab extends StatefulWidget {
  const CustomerDetailTab({super.key});

  @override
  State<CustomerDetailTab> createState() => _CustomerDetailTabState();
}

class _CustomerDetailTabState extends State<CustomerDetailTab> {
  String? selectedBrokerKey;
  String? selectedTransporterKey;

  final TextEditingController commController = TextEditingController();
  final TextEditingController deliveryDaysController = TextEditingController();
  final TextEditingController deliveryDateController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  final Color slate600 = const Color(0xFF64748B);
  final Color slateBorder = const Color(0xFFCBD5E1);

  @override
  void initState() {
    super.initState();

    if (EditOrderData.brokerList.any((item) => item['key'] == EditOrderData.brokerKey)) {
      selectedBrokerKey = EditOrderData.brokerKey;
    }

    if (EditOrderData.transporterList.any((item) => item['key'] == EditOrderData.transporterKey)) {
      selectedTransporterKey = EditOrderData.transporterKey;
    }

    commController.text = EditOrderData.commission;
    deliveryDaysController.text = EditOrderData.deliveryDays;
    deliveryDateController.text = EditOrderData.deliveryDate;
    remarkController.text = EditOrderData.remark;

    commController.addListener(updateEditOrderData);
    deliveryDaysController.addListener(updateEditOrderData);
    deliveryDateController.addListener(updateEditOrderData);
    remarkController.addListener(updateEditOrderData);
  }

  void updateEditOrderData() {
    EditOrderData.brokerKey = selectedBrokerKey ?? '';
    EditOrderData.transporterKey = selectedTransporterKey ?? '';
    EditOrderData.commission = commController.text;
    EditOrderData.deliveryDays = deliveryDaysController.text;
    EditOrderData.deliveryDate = deliveryDateController.text;
    EditOrderData.remark = remarkController.text;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date field (single)
          _buildReadOnlyField('Date', EditOrderData.detailsForEdit),
          const SizedBox(height: 12),
          
          // Party Name field (single)
          _buildReadOnlyField('Party Name', EditOrderData.partyName),
          const SizedBox(height: 16),
          
          // Broker dropdown
          _buildDropdownField(
            label: 'Broker',
            value: selectedBrokerKey,
            items: EditOrderData.brokerList,
            onChanged: (val) {
              setState(() {
                selectedBrokerKey = val;
                updateEditOrderData();
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Commission field
          _buildTextField('Commission %', commController, TextInputType.number),
          const SizedBox(height: 12),
          
          // Transporter dropdown
          _buildDropdownField(
            label: 'Transporter',
            value: selectedTransporterKey,
            items: EditOrderData.transporterList,
            onChanged: (val) {
              setState(() {
                selectedTransporterKey = val;
                updateEditOrderData();
              });
            },
          ),
          const SizedBox(height: 12),
          
          // Delivery Days and Date in a row
          Row(
            children: [
              Expanded(child: _buildTextField('Delivery Days', deliveryDaysController, TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateField('Delivery Date', deliveryDateController)),
            ],
          ),
          const SizedBox(height: 12),
          
          // Remark field
          _buildTextField('Remark', remarkController, TextInputType.text, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: slateBorder),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: slate600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    TextInputType type, {
    int maxLines = 1,
  }) {
    return Container(
      height: maxLines > 1 ? 80 : 52,
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: slateBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: slateBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          labelStyle: TextStyle(
            color: slate600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Container(
      height: 52,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => pickDeliveryDate(),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
          suffixIcon: Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: slateBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: slateBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          labelStyle: TextStyle(
            color: slate600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 52,
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['key'],
            child: Text(
              item['name'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: slateBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: slateBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          labelStyle: TextStyle(
            color: slate600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        dropdownColor: Colors.white,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Future<void> pickDeliveryDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(deliveryDateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        updateEditOrderData();
      });
    }
  }

  @override
  void dispose() {
    commController.dispose();
    deliveryDaysController.dispose();
    deliveryDateController.dispose();
    remarkController.dispose();
    super.dispose();
  }
}