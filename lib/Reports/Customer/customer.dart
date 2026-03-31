import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class CustomerAnalysis extends StatefulWidget {
  const CustomerAnalysis({super.key});

  @override
  State<CustomerAnalysis> createState() => _CustomerAnalysisState();
}

class _CustomerAnalysisState extends State<CustomerAnalysis>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedSegment = 'All';
  String selectedRegion = 'All';
  String selectedPaymentStatus = 'All';

  // Customer data for garment industry
  final List<Map<String, dynamic>> topCustomers = [
    {'name': 'Fashion Hub Ltd', 'orders': 1250, 'revenue': 425000, 'growth': 15.5, 'segment': 'Premium', 'region': 'North', 'lastOrder': '2024-03-15'},
    {'name': 'Style Mart Inc', 'orders': 980, 'revenue': 328000, 'growth': 12.3, 'segment': 'Premium', 'region': 'South', 'lastOrder': '2024-03-14'},
    {'name': 'Urban Threads', 'orders': 850, 'revenue': 256000, 'growth': 8.7, 'segment': 'Regular', 'region': 'East', 'lastOrder': '2024-03-13'},
    {'name': 'Garment Gallery', 'orders': 720, 'revenue': 198000, 'growth': -2.1, 'segment': 'Regular', 'region': 'West', 'lastOrder': '2024-03-10'},
    {'name': 'Elite Fashion', 'orders': 680, 'revenue': 245000, 'growth': 22.4, 'segment': 'Premium', 'region': 'North', 'lastOrder': '2024-03-12'},
    {'name': 'Trendy Wear', 'orders': 560, 'revenue': 167000, 'growth': 5.8, 'segment': 'Regular', 'region': 'South', 'lastOrder': '2024-03-11'},
    {'name': 'Classic Apparel', 'orders': 490, 'revenue': 134000, 'growth': -5.2, 'segment': 'Economy', 'region': 'East', 'lastOrder': '2024-03-09'},
    {'name': 'Modern Stitch', 'orders': 420, 'revenue': 112000, 'growth': 18.6, 'segment': 'Premium', 'region': 'West', 'lastOrder': '2024-03-08'},
  ];

  // Payment data
  final List<Map<String, dynamic>> paymentData = [
    {'customer': 'Fashion Hub Ltd', 'totalDue': 125000, 'paid': 98000, 'pending': 27000, 'dueDate': '2024-04-15', 'status': 'Partial', 'paymentTerms': 'Net 30'},
    {'customer': 'Style Mart Inc', 'totalDue': 89000, 'paid': 89000, 'pending': 0, 'dueDate': '2024-04-10', 'status': 'Paid', 'paymentTerms': 'Net 15'},
    {'customer': 'Urban Threads', 'totalDue': 72000, 'paid': 50000, 'pending': 22000, 'dueDate': '2024-04-20', 'status': 'Partial', 'paymentTerms': 'Net 45'},
    {'customer': 'Garment Gallery', 'totalDue': 45000, 'paid': 20000, 'pending': 25000, 'dueDate': '2024-04-05', 'status': 'Overdue', 'paymentTerms': 'Net 30'},
    {'customer': 'Elite Fashion', 'totalDue': 154000, 'paid': 154000, 'pending': 0, 'dueDate': '2024-04-18', 'status': 'Paid', 'paymentTerms': 'Net 60'},
    {'customer': 'Trendy Wear', 'totalDue': 43000, 'paid': 30000, 'pending': 13000, 'dueDate': '2024-04-25', 'status': 'Partial', 'paymentTerms': 'Net 30'},
    {'customer': 'Classic Apparel', 'totalDue': 38000, 'paid': 15000, 'pending': 23000, 'dueDate': '2024-04-08', 'status': 'Overdue', 'paymentTerms': 'Net 30'},
    {'customer': 'Modern Stitch', 'totalDue': 67000, 'paid': 67000, 'pending': 0, 'dueDate': '2024-04-22', 'status': 'Paid', 'paymentTerms': 'Net 15'},
  ];

  // Payment history
  final List<Map<String, dynamic>> paymentHistory = [
    {'date': '2024-03-01', 'customer': 'Fashion Hub Ltd', 'amount': 25000, 'method': 'Bank Transfer', 'reference': 'INV-001'},
    {'date': '2024-03-05', 'customer': 'Style Mart Inc', 'amount': 45000, 'method': 'Credit Card', 'reference': 'INV-002'},
    {'date': '2024-03-08', 'customer': 'Urban Threads', 'amount': 25000, 'method': 'Cash', 'reference': 'INV-003'},
    {'date': '2024-03-12', 'customer': 'Elite Fashion', 'amount': 80000, 'method': 'Bank Transfer', 'reference': 'INV-004'},
    {'date': '2024-03-15', 'customer': 'Trendy Wear', 'amount': 15000, 'method': 'Cheque', 'reference': 'INV-005'},
    {'date': '2024-03-18', 'customer': 'Modern Stitch', 'amount': 35000, 'method': 'Bank Transfer', 'reference': 'INV-006'},
    {'date': '2024-03-20', 'customer': 'Fashion Hub Ltd', 'amount': 48000, 'method': 'Credit Card', 'reference': 'INV-007'},
    {'date': '2024-03-22', 'customer': 'Garment Gallery', 'amount': 10000, 'method': 'Cash', 'reference': 'INV-008'},
  ];

  // Monthly payment trends
  final List<Map<String, dynamic>> monthlyPayments = [
    {'month': 'Jan', 'received': 185000, 'pending': 45000, 'overdue': 12000},
    {'month': 'Feb', 'received': 210000, 'pending': 38000, 'overdue': 15000},
    {'month': 'Mar', 'received': 245000, 'pending': 52000, 'overdue': 18000},
    {'month': 'Apr', 'received': 198000, 'pending': 61000, 'overdue': 22000},
    {'month': 'May', 'received': 278000, 'pending': 48000, 'overdue': 16000},
    {'month': 'Jun', 'received': 312000, 'pending': 55000, 'overdue': 20000},
  ];

  // Customer purchase history
  final List<Map<String, dynamic>> customerHistory = [
    {'customer': 'Fashion Hub Ltd', 'date': '2024-03-15', 'orderId': 'ORD-001', 'amount': 12500, 'items': 1250, 'status': 'Delivered', 'paymentStatus': 'Paid'},
    {'customer': 'Fashion Hub Ltd', 'date': '2024-03-01', 'orderId': 'ORD-008', 'amount': 9800, 'items': 980, 'status': 'Delivered', 'paymentStatus': 'Paid'},
    {'customer': 'Fashion Hub Ltd', 'date': '2024-02-15', 'orderId': 'ORD-015', 'amount': 11200, 'items': 1120, 'status': 'Delivered', 'paymentStatus': 'Paid'},
    {'customer': 'Style Mart Inc', 'date': '2024-03-14', 'orderId': 'ORD-002', 'amount': 8900, 'items': 890, 'status': 'Delivered', 'paymentStatus': 'Paid'},
    {'customer': 'Style Mart Inc', 'date': '2024-03-05', 'orderId': 'ORD-009', 'amount': 7600, 'items': 760, 'status': 'Delivered', 'paymentStatus': 'Paid'},
    {'customer': 'Urban Threads', 'date': '2024-03-13', 'orderId': 'ORD-003', 'amount': 7200, 'items': 720, 'status': 'Delivered', 'paymentStatus': 'Partial'},
    {'customer': 'Garment Gallery', 'date': '2024-03-10', 'orderId': 'ORD-006', 'amount': 4500, 'items': 450, 'status': 'Delivered', 'paymentStatus': 'Overdue'},
    {'customer': 'Garment Gallery', 'date': '2024-02-28', 'orderId': 'ORD-012', 'amount': 5200, 'items': 520, 'status': 'Delivered', 'paymentStatus': 'Overdue'},
    {'customer': 'Elite Fashion', 'date': '2024-03-12', 'orderId': 'ORD-004', 'amount': 15400, 'items': 1540, 'status': 'Delivered', 'paymentStatus': 'Paid'},
    {'customer': 'Trendy Wear', 'date': '2024-03-11', 'orderId': 'ORD-005', 'amount': 4300, 'items': 430, 'status': 'Processing', 'paymentStatus': 'Partial'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      appBar: AppBar(
        title: Text(
          'Customer Analysis',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.people)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: () => setState(() {}),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.white),
            onSelected: (value) {
              setState(() {
                if (value == 'All') {
                  selectedPaymentStatus = 'All';
                } else {
                  selectedPaymentStatus = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Payments')),
              const PopupMenuItem(value: 'Paid', child: Text('Paid Only')),
              const PopupMenuItem(value: 'Partial', child: Text('Partial Only')),
              const PopupMenuItem(value: 'Overdue', child: Text('Overdue Only')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.white),
            onPressed: () => _showExportDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerOverviewTab(),
          _buildCustomerPaymentsTab(),
          _buildCustomerHistoryTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: CUSTOMER OVERVIEW ====================
  Widget _buildCustomerOverviewTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildKeyMetricsCards(),
              const SizedBox(height: 20),
              _buildCustomerGrowthChart(),
              const SizedBox(height: 20),
              _buildSegmentAndRegionCards(),
              const SizedBox(height: 20),
              _buildTopCustomersTable(),
              const SizedBox(height: 20),
              _buildCustomerInsights(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: CUSTOMER PAYMENTS ====================
  Widget _buildCustomerPaymentsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildPaymentMetricsCards(),
              const SizedBox(height: 20),
              _buildPaymentTrendChart(),
              const SizedBox(height: 20),
              _buildPaymentStatusChart(),
              const SizedBox(height: 20),
              _buildCustomerPaymentStatus(),
              const SizedBox(height: 20),
              _buildRecentPayments(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: CUSTOMER HISTORY ====================
  Widget _buildCustomerHistoryTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCustomerPurchaseHistory(),
              const SizedBox(height: 20),
              _buildCustomerOrderFrequency(),
              const SizedBox(height: 20),
              _buildCustomerTimeline(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== KEY METRICS CARDS ====================
  Widget _buildKeyMetricsCards() {
    int totalCustomers = topCustomers.length;
    double totalRevenue = topCustomers.fold(0.0, (sum, item) => sum + (item['revenue'] as int));
    double avgOrderValue = totalRevenue / topCustomers.fold(0, (sum, item) => sum + (item['orders'] as int));
    double avgGrowth = topCustomers.fold(0.0, (sum, item) => sum + (item['growth'] as double)) / topCustomers.length;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          title: 'Total Customers',
          value: totalCustomers.toString(),
          subtitle: 'Active',
          icon: FontAwesomeIcons.users,
          color: AppColors.primaryColor,
          change: '+12 this month',
        ),
        _buildMetricCard(
          title: 'Total Revenue',
          value: '₹${(totalRevenue / 100000).toStringAsFixed(1)}L',
          subtitle: 'Lakhs',
          icon: FontAwesomeIcons.rupeeSign,
          color: AppColors.accentColor,
          change: '+18% vs last month',
        ),
        _buildMetricCard(
          title: 'Avg Order Value',
          value: '₹${(avgOrderValue).toStringAsFixed(0)}',
          subtitle: 'per order',
          icon: FontAwesomeIcons.shoppingCart,
          color: Colors.orange,
          change: '+5.2% increase',
        ),
        _buildMetricCard(
          title: 'Customer Growth',
          value: '${avgGrowth.toStringAsFixed(1)}%',
          subtitle: 'average',
          icon: FontAwesomeIcons.chartLine,
          color: Colors.purple,
          change: '${avgGrowth > 0 ? "Positive" : "Negative"} trend',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String change,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            change,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER GROWTH CHART ====================
  Widget _buildCustomerGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Growth Trend',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.lightGray,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 500,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 320),
                      FlSpot(1, 345),
                      FlSpot(2, 368),
                      FlSpot(3, 392),
                      FlSpot(4, 415),
                      FlSpot(5, 438),
                    ],
                    isCurved: true,
                    color: AppColors.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryColor.withOpacity(0.1),
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

  // ==================== SEGMENT AND REGION CARDS ====================
  Widget _buildSegmentAndRegionCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Segments',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSegmentBar('Premium', 42, AppColors.primaryColor),
                const SizedBox(height: 12),
                _buildSegmentBar('Regular', 33, Colors.green),
                const SizedBox(height: 12),
                _buildSegmentBar('Economy', 25, Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Region Distribution',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSegmentBar('North', 33, Colors.blue),
                const SizedBox(height: 12),
                _buildSegmentBar('South', 29, Colors.green),
                const SizedBox(height: 12),
                _buildSegmentBar('East', 21, Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentBar(String label, int percentage, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.lightGray,
          color: color,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  // ==================== TOP CUSTOMERS TABLE ====================
  Widget _buildTopCustomersTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Customers',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateProperty.all(AppColors.veryLightGray),
              headingTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('Customer Name')),
                DataColumn(label: Text('Orders'), numeric: true),
                DataColumn(label: Text('Revenue'), numeric: true),
                DataColumn(label: Text('Growth'), numeric: true),
                DataColumn(label: Text('Segment')),
              ],
              rows: topCustomers.take(5).map((customer) {
                return DataRow(
                  cells: [
                    DataCell(Text(customer['name'], style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(customer['orders'].toString(), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text('₹${(customer['revenue'] / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(
                      Text(
                        '${customer['growth'] > 0 ? '+' : ''}${customer['growth']}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: customer['growth'] > 0 ? AppColors.accentColor : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: customer['segment'] == 'Premium' 
                              ? AppColors.primaryColor.withOpacity(0.1)
                              : customer['segment'] == 'Regular'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          customer['segment'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: customer['segment'] == 'Premium' 
                                ? AppColors.primaryColor
                                : customer['segment'] == 'Regular'
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PAYMENT METRICS CARDS ====================
  Widget _buildPaymentMetricsCards() {
    double totalDue = paymentData.fold(0.0, (sum, item) => sum + (item['totalDue'] as int));
    double totalPaid = paymentData.fold(0.0, (sum, item) => sum + (item['paid'] as int));
    double totalPending = paymentData.fold(0.0, (sum, item) => sum + (item['pending'] as int));
    int overdueCount = paymentData.where((p) => p['status'] == 'Overdue').length;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          title: 'Total Receivable',
          value: '₹${(totalDue / 1000).toStringAsFixed(0)}k',
          subtitle: 'Total Due',
          icon: FontAwesomeIcons.rupeeSign,
          color: AppColors.primaryColor,
          change: '+8% from last month',
        ),
        _buildMetricCard(
          title: 'Amount Received',
          value: '₹${(totalPaid / 1000).toStringAsFixed(0)}k',
          subtitle: 'Total Paid',
          icon: FontAwesomeIcons.checkCircle,
          color: AppColors.accentColor,
          change: '${((totalPaid / totalDue) * 100).toStringAsFixed(1)}% collection rate',
        ),
        _buildMetricCard(
          title: 'Pending Amount',
          value: '₹${(totalPending / 1000).toStringAsFixed(0)}k',
          subtitle: 'To be collected',
          icon: FontAwesomeIcons.clock,
          color: Colors.orange,
          change: '${((totalPending / totalDue) * 100).toStringAsFixed(1)}% pending',
        ),
        _buildMetricCard(
          title: 'Overdue Accounts',
          value: overdueCount.toString(),
          subtitle: 'Customers',
          icon: FontAwesomeIcons.exclamationTriangle,
          color: Colors.red,
          change: 'Needs immediate attention',
        ),
      ],
    );
  }

  // ==================== PAYMENT TREND CHART ====================
  Widget _buildPaymentTrendChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Trends',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.lightGray,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthlyPayments.length) {
                          return Text(
                            monthlyPayments[value.toInt()]['month'],
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 350000,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(monthlyPayments.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        monthlyPayments[index]['received'].toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: AppColors.accentColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accentColor.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(monthlyPayments.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        monthlyPayments[index]['pending'].toDouble(),
                      );
                    }),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Amount Received', AppColors.accentColor),
              const SizedBox(width: 20),
              _buildLegend('Pending Amount', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10),
        ),
      ],
    );
  }

  // ==================== PAYMENT STATUS CHART ====================
  Widget _buildPaymentStatusChart() {
    int paid = paymentData.where((p) => p['status'] == 'Paid').length;
    int partial = paymentData.where((p) => p['status'] == 'Partial').length;
    int overdue = paymentData.where((p) => p['status'] == 'Overdue').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Status Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard('Paid', paid, AppColors.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard('Partial', partial, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusCard('Overdue', overdue, Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: paid.toDouble(),
                    title: 'Paid\n$paid',
                    color: AppColors.accentColor,
                    radius: 70,
                    titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: partial.toDouble(),
                    title: 'Partial\n$partial',
                    color: Colors.orange,
                    radius: 70,
                    titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: overdue.toDouble(),
                    title: 'Overdue\n$overdue',
                    color: Colors.red,
                    radius: 70,
                    titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER PAYMENT STATUS ====================
  Widget _buildCustomerPaymentStatus() {
    List<Map<String, dynamic>> filteredData = paymentData;
    if (selectedPaymentStatus != 'All') {
      filteredData = paymentData.where((p) => p['status'] == selectedPaymentStatus).toList();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Payment Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateProperty.all(AppColors.veryLightGray),
              headingTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Total Due'), numeric: true),
                DataColumn(label: Text('Paid'), numeric: true),
                DataColumn(label: Text('Pending'), numeric: true),
                DataColumn(label: Text('Due Date')),
                DataColumn(label: Text('Status')),
              ],
              rows: filteredData.map((payment) {
                Color statusColor = payment['status'] == 'Paid' 
                    ? AppColors.accentColor
                    : payment['status'] == 'Partial'
                        ? Colors.orange
                        : Colors.red;
                return DataRow(
                  cells: [
                    DataCell(Text(payment['customer'], style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text('₹${(payment['totalDue'] / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text('₹${(payment['paid'] / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text('₹${(payment['pending'] / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(payment['dueDate'], style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          payment['status'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RECENT PAYMENTS ====================
  Widget _buildRecentPayments() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Payments',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: paymentHistory.length,
            itemBuilder: (context, index) {
              final payment = paymentHistory[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: AppColors.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment['customer'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Ref: ${payment['reference']} | ${payment['method']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${(payment['amount'] / 1000).toStringAsFixed(1)}k',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.accentColor,
                          ),
                        ),
                        Text(
                          payment['date'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER PURCHASE HISTORY ====================
  Widget _buildCustomerPurchaseHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Purchase History',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateProperty.all(AppColors.veryLightGray),
              headingTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('Items'), numeric: true),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Payment')),
              ],
              rows: customerHistory.map((history) {
                Color statusColor = history['status'] == 'Delivered' 
                    ? AppColors.accentColor
                    : Colors.orange;
                Color paymentColor = history['paymentStatus'] == 'Paid' 
                    ? AppColors.accentColor
                    : history['paymentStatus'] == 'Partial'
                        ? Colors.orange
                        : Colors.red;
                return DataRow(
                  cells: [
                    DataCell(Text(history['date'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(history['customer'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(history['orderId'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('₹${(history['amount'] / 1000).toStringAsFixed(1)}k', style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(history['items'].toString(), style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          history['status'],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: paymentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          history['paymentStatus'],
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: paymentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER ORDER FREQUENCY ====================
  Widget _buildCustomerOrderFrequency() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Frequency Analysis',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildFrequencyBar('High Frequency (10+ orders)', 35, Colors.green),
          const SizedBox(height: 16),
          _buildFrequencyBar('Medium Frequency (5-9 orders)', 42, Colors.orange),
          const SizedBox(height: 16),
          _buildFrequencyBar('Low Frequency (1-4 orders)', 23, AppColors.primaryColor),
        ],
      ),
    );
  }

  Widget _buildFrequencyBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.lightGray,
          color: color,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // ==================== CUSTOMER TIMELINE ====================
  Widget _buildCustomerTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Activity Timeline',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemCount: customerHistory.take(6).length,
              itemBuilder: (context, index) {
                final history = customerHistory[index];
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        history['date'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        history['customer'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order: ${history['orderId']}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Amount: ₹${(history['amount'] / 1000).toStringAsFixed(1)}k',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOMER INSIGHTS ====================
  Widget _buildCustomerInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.paleYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Customer Insights',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            '👥 Top Customer',
            'Fashion Hub Ltd contributes 14% of total revenue',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '📈 Growth Leader',
            'Elite Fashion shows 22.4% growth this quarter',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '🎯 Premium Segment',
            'Premium customers generate 42% of total revenue',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '💰 Payment Collection',
            '82% of payments received on time this month',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '⚠️ Overdue Alert',
            '3 customers have overdue payments >30 days',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, color: AppColors.paleYellow, size: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Export Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Export customer analysis report as PDF?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Customer report exported successfully!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.accentColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text('Export', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}