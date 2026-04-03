import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';
import 'package:vrs_erp/production/Planning/Job_Work_Order/jobOrderScreenAdd.dart';
import 'package:vrs_erp/screens/drawer_screen.dart';
import 'package:vrs_erp/services/production_services.dart';

class JobWorkScreen extends StatefulWidget {
  const JobWorkScreen({super.key});

  @override
  State<JobWorkScreen> createState() => _JobWorkScreenState();
}

class _JobWorkScreenState extends State<JobWorkScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _jobWorks = [];
  List<Map<String, dynamic>> _filteredJobWorks = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterJobWorks);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _widthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty && _isSearching) {
        _toggleSearch();
      }
    });
    
    _loadJobWorks();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterJobWorks);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadJobWorks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final jobWorks = await ProductionService.getJobWorks();
    
    setState(() {
      _jobWorks = jobWorks;
      _filteredJobWorks = List.from(jobWorks);
      _isLoading = false;
      
      if (jobWorks.isEmpty) {
        _errorMessage = 'No job works found';
      }
    });
  }

  void _filterJobWorks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredJobWorks = List.from(_jobWorks);
      } else {
        _filteredJobWorks = _jobWorks.where((work) {
          return work['docNo'].toString().toLowerCase().contains(query) ||
              work['jobber'].toString().toLowerCase().contains(query) ||
              work['station'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    if (_isSearching) {
      _animationController.reverse();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _filterJobWorks();
          });
        }
      });
    } else {
      setState(() {
        _isSearching = true;
      });
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_searchFocusNode);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _filterJobWorks();
    FocusScope.of(context).unfocus();
    _toggleSearch();
  }

  Future<void> _navigateToJobWorkDetail(Map<String, dynamic>? jobWork) async {
    if (jobWork == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateJobOrderScreen(),
        ),
      );
      
      if (result != null && mounted) {
        await _loadJobWorks(); // Reload the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job Order Created Successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateJobOrderScreen(
            jobWork: jobWork,
          ),
        ),
      );
      
      if (result != null && mounted) {
        await _loadJobWorks(); // Reload the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job Order Updated Successfully!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
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
      case 'Active':
        return Colors.green.withOpacity(0.1);
      case 'In Progress':
        return AppColors.primaryColor.withOpacity(0.1);
      case 'Planned':
        return Colors.orange.withOpacity(0.1);
      case 'Completed':
        return Colors.green.withOpacity(0.1);
      case 'Delayed':
        return Colors.red.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  String _formatCurrency(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
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

  Widget _buildAuditItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:  DrawerScreen(),
      appBar: AppBar(
        title: !_isSearching
            ? const Text(
                'Job Works',
                style: TextStyle(fontWeight: FontWeight.w600),
              )
            : null,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        titleSpacing: _isSearching ? 0 : null,
        flexibleSpace: _isSearching
            ? AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scaleX: _widthAnimation.value,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search by Doc No, Jobber, Station...',
                              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : null,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: IconButton(
              key: ValueKey(_isSearching),
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: _isSearching ? _clearSearch : _toggleSearch,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToJobWorkDetail(null),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text(
          'JOB ORDER',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading job works...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (_errorMessage != null && _jobWorks.isEmpty) {
      return _buildEmptyState();
    }
    
    if (_filteredJobWorks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterJobWorks();
              },
              child: const Text('Clear search'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredJobWorks.length,
      itemBuilder: (context, index) {
        final jobWork = _filteredJobWorks[index];
        final status = jobWork['status']?.toString() ?? 'Active';
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
              side: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      status == 'Active'
                          ? Icons.check_circle_outline
                          : status == 'In Progress'
                              ? Icons.engineering_outlined
                              : status == 'Planned'
                                  ? Icons.schedule_outlined
                                  : Icons.warning_amber_outlined,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              jobWork['docNo']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  jobWork['docDt']?.toString() ?? 'N/A',
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
                                Icon(
                                  Icons.person,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  jobWork['createdBy']?.toString() ?? 'N/A',
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
                          top: BorderSide(
                            color: Colors.grey.shade200,
                          ),
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
                                  icon: Icons.business,
                                  label: 'Jobber',
                                  value: jobWork['jobber']?.toString() ?? '-',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDetailChip(
                                  icon: Icons.location_on,
                                  label: 'Station',
                                  value: jobWork['station']?.toString() ?? '-',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Quantity & Job Charge Section
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricItem(
                                        label: 'Total Pcs',
                                        value: jobWork['totPcs']?.toString() ?? '0',
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
                                        label: 'Job Charge/Pc',
                                        value: _formatCurrency(jobWork['jobChgPc'] ?? 0),
                                        icon: Icons.currency_rupee,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Audit Info
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildAuditItem(
                                        label: 'Created By',
                                        value: jobWork['createdBy']?.toString() ?? '-',
                                        icon: Icons.person_add,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildAuditItem(
                                        label: 'Created On',
                                        value: jobWork['createdOn']?.toString() ?? '-',
                                        icon: Icons.access_time,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((jobWork['updatedBy']?.toString() ?? '').isNotEmpty ||
                                    (jobWork['updatedOn']?.toString() ?? '').isNotEmpty)
                                  const SizedBox(height: 6),
                                if ((jobWork['updatedBy']?.toString() ?? '').isNotEmpty ||
                                    (jobWork['updatedOn']?.toString() ?? '').isNotEmpty)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildAuditItem(
                                          label: 'Updated By',
                                          value: jobWork['updatedBy']?.toString() ?? '-',
                                          icon: Icons.update,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildAuditItem(
                                          label: 'Updated On',
                                          value: jobWork['updatedOn']?.toString() ?? '-',
                                          icon: Icons.update,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _navigateToJobWorkDetail(jobWork),
                                  icon: const Icon(
                                    Icons.visibility,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'VIEW DETAILS',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryColor,
                                    side: const BorderSide(
                                      color: AppColors.primaryColor,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _navigateToJobWorkDetail(jobWork),
                                  icon: const Icon(
                                    Icons.edit,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'EDIT',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'No Job Works Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a new job order',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            ElevatedButton.icon(
              onPressed: _loadJobWorks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (_errorMessage == null)
            ElevatedButton.icon(
              onPressed: () => _navigateToJobWorkDetail(null),
              icon: const Icon(Icons.add),
              label: const Text('Create Job Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}