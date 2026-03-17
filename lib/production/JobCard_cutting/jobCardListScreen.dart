import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/JobCard_cutting/jobCardDetailScreen.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';

class JobCardListScreen extends StatefulWidget {
  const JobCardListScreen({super.key});

  @override
  State<JobCardListScreen> createState() => _JobCardListScreenState();
}

class _JobCardListScreenState extends State<JobCardListScreen> {
  final List<Map<String, dynamic>> _jobCards = [
    {
      'docNo': 'JC00001',
      'docDt': '19/09/2025',
      'soNo': 'SO001',
      'jobber': 'SELF',
      'station': 'SURAT',
      'totQty': 376,
      'totPcs': 376,
      'wasteQty': 10,
      'jobChgPc': 50.0,
      'jobAmt': 18800.0,
      'otherProctAmt': 500.0,
      'otherChargeAmt': 200.0,
      'netAmt': 19500.0,
      'createdBy': 'Admin',
      'createdOn': '18/09/2025 10:00 AM',
      'updatedBy': 'Admin',
      'updatedOn': '18/09/2025 03:00 PM',
      'status': 'In Progress',
      'finishDetails': [
        {'Finish Type': 'WASH', 'Quantity': '200', 'Status': 'Done'},
        {'Finish Type': 'IRON', 'Quantity': '176', 'Status': 'Pending'},
      ],
      'fabricDetails': [
        {'Fabric': 'DENIM', 'Color': 'BLUE', 'Meters Used': '450'},
        {'Fabric': 'COTTON', 'Color': 'WHITE', 'Meters Used': '120'},
      ],
    },
    {
      'docNo': 'JC00002',
      'docDt': '20/09/2025',
      'soNo': 'SO002',
      'jobber': 'SELF',
      'station': 'SURAT',
      'totQty': 500,
      'totPcs': 500,
      'wasteQty': 15,
      'jobChgPc': 40.0,
      'jobAmt': 20000.0,
      'otherProctAmt': 300.0,
      'otherChargeAmt': 150.0,
      'netAmt': 20450.0,
      'createdBy': 'User1',
      'createdOn': '19/09/2025 09:00 AM',
      'updatedBy': 'User1',
      'updatedOn': '19/09/2025 02:00 PM',
      'status': 'Planned',
      'finishDetails': [
        {'Finish Type': 'PACKING', 'Quantity': '100', 'Status': 'Planned'},
      ],
      'fabricDetails': [
        {'Fabric': 'COTTON', 'Color': 'WHITE', 'Meters Used': '300'},
      ],
    },
    {
      'docNo': 'JC00003',
      'docDt': '21/09/2025',
      'soNo': 'SO003',
      'jobber': 'SELF',
      'station': 'SURAT',
      'totQty': 250,
      'totPcs': 250,
      'wasteQty': 5,
      'jobChgPc': 45.0,
      'jobAmt': 11250.0,
      'otherProctAmt': 250.0,
      'otherChargeAmt': 100.0,
      'netAmt': 11600.0,
      'createdBy': 'Admin',
      'createdOn': '20/09/2025 11:00 AM',
      'updatedBy': 'Admin',
      'updatedOn': '21/09/2025 09:00 AM',
      'status': 'Completed',
      'finishDetails': [
        {'Finish Type': 'WASH', 'Quantity': '250', 'Status': 'Done'},
        {'Finish Type': 'IRON', 'Quantity': '250', 'Status': 'Done'},
        {'Finish Type': 'PACKING', 'Quantity': '250', 'Status': 'Done'},
      ],
      'fabricDetails': [
        {'Fabric': 'LINEN', 'Color': 'BEIGE', 'Meters Used': '300'},
        {'Fabric': 'COTTON', 'Color': 'NAVY', 'Meters Used': '150'},
      ],
    },
  ];

  void _navigateToJobCardDetail(Map<String, dynamic>? jobCard) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobCardDetailScreen(jobCard: jobCard),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return AppColors.primaryColor;
      case 'Planned':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Delayed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'In Progress':
        return AppColors.primaryColor.shade50;
      case 'Planned':
        return Colors.orange.shade50;
      case 'Completed':
        return Colors.green.shade50;
      case 'Delayed':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  void _showDetailsDialog(String title, List<Map<String, String>> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                children: details.first.keys
                    .map((key) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            key,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ))
                    .toList(),
              ),
              ...details.map(
                (row) => TableRow(
                  children: row.values
                      .map((value) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(value.isNotEmpty ? value : '-'),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _onMenuSelected(String choice) {
    if (choice == 'Finish Details') {
      final allFinishDetails = _jobCards
          .expand((job) => List<Map<String, String>>.from(job['finishDetails']))
          .toList();
      _showDetailsDialog('Finish Details', allFinishDetails);
    } else if (choice == 'Fabric Details') {
      final allFabricDetails = _jobCards
          .expand((job) => List<Map<String, String>>.from(job['fabricDetails']))
          .toList();
      _showDetailsDialog('Fabric Details', allFabricDetails);
    }
  }

  String _formatCurrency(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerScreen(),
      appBar: AppBar(
        title: const Text(
          'Job Cards',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality here
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Finish Details',
                child: Text('Finish Details'),
              ),
              const PopupMenuItem(
                value: 'Fabric Details',
                child: Text('Fabric Details'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _jobCards.length,
            itemBuilder: (context, index) {
              final jobCard = _jobCards[index];
              final status = jobCard['status']?.toString() ?? 'Unknown';
              final statusColor = _getStatusColor(status);
              final statusBgColor = _getStatusBackgroundColor(status);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        childrenPadding: EdgeInsets.zero,
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            jobCard['status'] == 'Completed' 
                                ? Icons.check_circle_outline
                                : jobCard['status'] == 'In Progress'
                                    ? Icons.autorenew
                                    : Icons.schedule,
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    jobCard['docNo']?.toString() ?? 'JC00000',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${jobCard['docDt']?.toString() ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(Icons.shopping_cart, size: 12, color: Colors.grey.shade600),
                                      const SizedBox(width: 2),
                                      Text(
                                        'SO: ${jobCard['soNo']?.toString() ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Jobber & Station Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailChip(
                                        icon: Icons.person,
                                        label: 'Jobber',
                                        value: jobCard['jobber']?.toString() ?? '-',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildDetailChip(
                                        icon: Icons.pin_drop,
                                        label: 'Station',
                                        value: jobCard['station']?.toString() ?? '-',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Quantity Section with 3 columns
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricItem(
                                          label: 'Total Qty',
                                          value: jobCard['totQty']?.toString() ?? '0',
                                          icon: Icons.inventory,
                                        ),
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        child: _buildMetricItem(
                                          label: 'Total Pcs',
                                          value: jobCard['totPcs']?.toString() ?? '0',
                                          icon: Icons.shopping_bag,
                                        ),
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        child: _buildMetricItem(
                                          label: 'Waste',
                                          value: jobCard['wasteQty']?.toString() ?? '0',
                                          icon: Icons.delete_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Financial Summary - Compact
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:  AppColors.primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color:  AppColors.primaryColor.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFinancialItem(
                                              label: 'Net Amt',
                                              value: _formatCurrency(jobCard['netAmt'] ?? 0),
                                              icon: Icons.currency_rupee,
                                              highlight: true,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildFinancialItem(
                                              label: 'Job Amt',
                                              value: _formatCurrency(jobCard['jobAmt'] ?? 0),
                                              icon: Icons.work_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFinancialItem(
                                              label: 'Job Chg/Pc',
                                              value: '₹ ${jobCard['jobChgPc']?.toStringAsFixed(2) ?? '0.00'}',
                                              icon: Icons.price_change,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildFinancialItem(
                                              label: 'Other Proc',
                                              value: _formatCurrency(jobCard['otherProctAmt'] ?? 0),
                                              icon: Icons.build,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFinancialItem(
                                              label: 'Other Chg',
                                              value: _formatCurrency(jobCard['otherChargeAmt'] ?? 0),
                                              icon: Icons.add_chart,
                                            ),
                                          ),
                                          const Expanded(child: SizedBox.shrink()),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Audit Info - Compact Grid
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildAuditItem(
                                              label: 'Created By',
                                              value: jobCard['createdBy']?.toString() ?? '-',
                                              icon: Icons.person_add,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAuditItem(
                                              label: 'Created On',
                                              value: jobCard['createdOn']?.toString() ?? '-',
                                              icon: Icons.access_time,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildAuditItem(
                                              label: 'Updated By',
                                              value: jobCard['updatedBy']?.toString() ?? '-',
                                              icon: Icons.update,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAuditItem(
                                              label: 'Updated On',
                                              value: jobCard['updatedOn']?.toString() ?? '-',
                                              icon: Icons.update,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // View Details Button
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _navigateToJobCardDetail(jobCard),
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('VIEW DETAILS', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:  AppColors.primaryColor,
                                          side: const BorderSide(color: AppColors.primaryColor),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToJobCardDetail(null),
        backgroundColor:  AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text(
          'JOB CARD SHEET',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12,color: Colors.white),
        ),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({required String label, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialItem({required String label, required String value, required IconData icon, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ?  AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: highlight ?  AppColors.primaryColor : Colors.grey.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                    color: highlight ?  AppColors.primaryColor : Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditItem({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}