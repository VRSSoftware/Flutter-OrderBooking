import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class OrderDetailsPage123 extends StatefulWidget {
  const OrderDetailsPage123({super.key});

  @override
  State<OrderDetailsPage123> createState() => _OrderDetailsPage123State();
}

class _OrderDetailsPage123State extends State<OrderDetailsPage123> {
  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF2196F3);
    final Color slate600 = const Color(0xFF64748B);
    final Color slateBorder = const Color(0xFFCBD5E1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text("View Order", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        elevation: 4,
      ),
      body: Column(
        children: [
          // Custom Tab Navigation
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab("Transaction", isActive: false),
                _buildTab("Customer Details", isActive: true),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOutlineField("Select Date", value: "2026-02-12", icon: Icons.calendar_today),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOutlineField("Party Name", value: "Select Party", isDropdown: true),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildOutlineField("Broker", value: "Select Broker", isDropdown: true),
                  
                  const SizedBox(height: 20),
                  _buildOutlineField("Comm (%)", hint: "Enter Percentage", isNumber: true),
                  
                  const SizedBox(height: 20),
                  _buildOutlineField("Transporter", value: "Select Transporter", isDropdown: true),
                  
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildOutlineField("Delivery Days", value: "0", isNumber: true, textAlign: TextAlign.center)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildOutlineField("Delivery Date", value: "2026-02-12", icon: Icons.event)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildOutlineField("Remark", hint: "Enter any additional notes...", isMultiline: true),

                  const SizedBox(height: 24),
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // blue-50
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow("Total Item", "0"),
                        const SizedBox(height: 12),
                        _summaryRow("Total Quantity", "0"),
                        const Divider(color: Color(0xFFBFDBFE), height: 24),
                        _summaryRow("Total Amount (₹)", "0.00", isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120), // Bottom padding for buttons
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue.withOpacity(0.1),
                      foregroundColor: primaryBlue,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Add More Info", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {}, 
                  child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12))
                ),
                TextButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text("BACK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, {required bool isActive}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2196F3) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? const Color(0xFF2196F3) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineField(String label, {
    String? value, 
    String? hint, 
    IconData? icon, 
    bool isDropdown = false,
    bool isNumber = false,
    bool isMultiline = false,
    TextAlign textAlign = TextAlign.start
  }) {
    return TextField(
      controller: value != null ? TextEditingController(text: value) : null,
      readOnly: value != null && !isNumber,
      maxLines: isMultiline ? 3 : 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textAlign: textAlign,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : 
                    isDropdown ? const Icon(Icons.expand_more, color: Colors.grey) : null,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isTotal ? const Color(0xFF2196F3) : const Color(0xFF64748B),
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          fontSize: 14
        )),
        Text(value, style: TextStyle(
          color: isTotal ? const Color(0xFF2196F3) : Colors.black87,
          fontWeight: isTotal ? FontWeight.normal : FontWeight.bold,
          fontSize: isTotal ? 20 : 16,
        )),
      ],
    );
  }
}