import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/Outstanding_Reports/Payable/outstanding_payable.dart';
import 'package:vrs_erp/Outstanding_Reports/Receivable/outstanding_receivable.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class OutstandingMainScreen extends StatefulWidget {
  const OutstandingMainScreen({super.key});

  @override
  State<OutstandingMainScreen> createState() => _OutstandingMainScreenState();
}

class _OutstandingMainScreenState extends State<OutstandingMainScreen> {
  String _selectedFilter = 'Today';

  // Sample data - replace with actual API data
  int _totalParties = 24;
  int _totalItems = 156;

  final List<Map<String, dynamic>> _outstandingOptions = [
    {
      'title': 'Outstanding Receivable',
      'subtitle': 'View all receivable outstanding',
      'icon': Icons.call_received,
      'iconColor': Colors.green,
      'page': const OutstandingReceivablePage(),
    },
    {
      'title': 'Outstanding Payable',
      'subtitle': 'View all payable outstanding',
      'icon': Icons.call_made,
      'iconColor': Colors.red,
      'page': const OutstandingPayablePage(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      appBar: AppBar(
        title: Text(
          'Outstanding',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined, color: Colors.white),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              _refreshData();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Filter Row
            _buildDateFilterRow(),
            
            const SizedBox(height: 8),
            
            // Items and Party Info Row
            _buildInfoRow(),
            
            const SizedBox(height: 16),
            
            // Outstanding Options List
            Expanded(
              child: _buildOutstandingList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterRow() {
    final List<String> filterOptions = ['Today', 'This Week', 'This Month', 'Custom'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filterOptions.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  if (filter == 'Custom') {
                    _selectCustomDateRange();
                  } else {
                    _fetchDataByFilter(filter);
                  }
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Items Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Items',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalItems',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Parties Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: Colors.purple.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Parties',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_totalParties',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
    );
  }

  Widget _buildOutstandingList() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Outstanding Reports',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _outstandingOptions.length,
              itemBuilder: (context, index) {
                final option = _outstandingOptions[index];
                return _buildOutstandingTile(option);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingTile(Map<String, dynamic> option) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (option['iconColor'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            option['icon'],
            color: option['iconColor'],
            size: 24,
          ),
        ),
        title: Text(
          option['title'],
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          option['subtitle'],
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => option['page'],
            ),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Options',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption('Party Wise', Icons.people),
                _buildFilterOption('Date Wise', Icons.calendar_today),
                _buildFilterOption('Age Wise', Icons.timeline),
                _buildFilterOption('Status Wise', Icons.assessment),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        Navigator.pop(context);
        // Apply filter logic
      },
    );
  }

  void _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _fetchDataByDateRange(picked.start, picked.end);
    }
  }

  void _fetchDataByFilter(String filter) {
    print('Fetching data for: $filter');
    setState(() {
      // Update values based on API response
    });
  }

  void _fetchDataByDateRange(DateTime start, DateTime end) {
    print('Fetching data from ${DateFormat('dd/MM/yyyy').format(start)} to ${DateFormat('dd/MM/yyyy').format(end)}');
    setState(() {
      // Update values based on API response
    });
  }

  void _refreshData() {
    _fetchDataByFilter(_selectedFilter);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}