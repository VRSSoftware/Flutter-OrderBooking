import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/jobCardDetailScreen.dart';
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
        return Colors.green;
      case 'Planned':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      case 'Delayed':
        return Colors.red;
      default:
        return Colors.grey;
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

  Widget _buildDetailRow(String label1, String value1, String label2, String value2) {
    final isValue1Big = (value1.length > 15 || (double.tryParse(value1) != null && value1.replaceAll('.', '').length > 5));
    final isValue2Big = (value2.length > 15 || (double.tryParse(value2) != null && value2.replaceAll('.', '').length > 5));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 100, // Increased width to fit "Other Chg Amt: "
                  child: Text(
                    '$label1: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value1.isNotEmpty ? value1 : '-',
                    style: TextStyle(
                      fontSize: isValue1Big ? 12 : 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 100, // Increased width to fit "Other Chg Amt: "
                  child: Text(
                    '$label2: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value2.isNotEmpty ? value2 : '-',
                    style: TextStyle(
                      fontSize: isValue2Big ? 12 : 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       drawer: DrawerScreen(),
      appBar: AppBar(
        title: const Text('Job Cards'),
        backgroundColor: const Color(0xFF4A90E2),
        foregroundColor: Colors.white,
        elevation: 0,
            leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.white),
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
      body: ListView.builder(
        itemCount: _jobCards.length,
        itemBuilder: (context, index) {
          final jobCard = _jobCards[index];
          return Card(
            margin: const EdgeInsets.all(8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ExpansionTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(jobCard['status']?.toString() ?? 'Unknown'),
                    shape: BoxShape.circle,
                  ),
                ),
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        jobCard['docNo']?.toString() ?? 'JC00000',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90E2),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dt: ${jobCard['docDt']?.toString() ?? '01/12/1999'}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SO: ${jobCard['soNo']?.toString() ?? 'SO0001'}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down, size: 24, color: Color(0xFF4A90E2)),
                backgroundColor: Colors.grey.shade50,
                collapsedBackgroundColor: Colors.white,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Jobber',
                          jobCard['jobber']?.toString() ?? '-',
                          'Station',
                          jobCard['station']?.toString() ?? '-',
                        ),
                        _buildDetailRow(
                          'Total Qty',
                          jobCard['totQty']?.toString() ?? '0',
                          'Total Pcs',
                          jobCard['totPcs']?.toString() ?? '0',
                        ),
                        _buildDetailRow(
                          'Waste Qty',
                          jobCard['wasteQty']?.toString() ?? '0',
                          'Job Chg/Pc',
                          jobCard['jobChgPc']?.toStringAsFixed(2) ?? '0.00',
                        ),
                        _buildDetailRow(
                          'Job Amt',
                          jobCard['jobAmt']?.toStringAsFixed(2) ?? '0.00',
                          'Other Proc Amt',
                          jobCard['otherProctAmt']?.toStringAsFixed(2) ?? '0.00',
                        ),
                        _buildDetailRow(
                          'Other Chg Amt',
                          jobCard['otherChargeAmt']?.toStringAsFixed(2) ?? '0.00',
                          'Net Amt',
                          jobCard['netAmt']?.toStringAsFixed(2) ?? '0.00',
                        ),
                        _buildDetailRow(
                          'Created By',
                          jobCard['createdBy']?.toString() ?? '-',
                          'Created On',
                          jobCard['createdOn']?.toString() ?? '-',
                        ),
                        _buildDetailRow(
                          'Updated By',
                          jobCard['updatedBy']?.toString() ?? '-',
                          'Updated On',
                          jobCard['updatedOn']?.toString() ?? '-',
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _navigateToJobCardDetail(jobCard),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                color: Color(0xFF4A90E2),
                                fontWeight: FontWeight.bold,
                              ),
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToJobCardDetail(null),
        backgroundColor: const Color(0xFF4A90E2),
        tooltip: 'Add New Job Card',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}