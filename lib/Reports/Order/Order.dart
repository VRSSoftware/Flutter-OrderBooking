import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class OrderAnalysis extends StatefulWidget {
  const OrderAnalysis({super.key});

  @override
  State<OrderAnalysis> createState() => _OrderAnalysisState();
}

class _OrderAnalysisState extends State<OrderAnalysis>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedPeriod = 'This Month';
  String selectedCategory = 'All';

  // Sales Performance Data
  final List<Map<String, dynamic>> salesData = [
    {'month': 'Jan', 'orders': 185, 'revenue': 425000, 'profit': 127500, 'margin': 30.0},
    {'month': 'Feb', 'orders': 210, 'revenue': 478000, 'profit': 143400, 'margin': 30.0},
    {'month': 'Mar', 'orders': 235, 'revenue': 525000, 'profit': 157500, 'margin': 30.0},
    {'month': 'Apr', 'orders': 258, 'revenue': 582000, 'profit': 174600, 'margin': 30.0},
    {'month': 'May', 'orders': 272, 'revenue': 618000, 'profit': 185400, 'margin': 30.0},
    {'month': 'Jun', 'orders': 295, 'revenue': 665000, 'profit': 199500, 'margin': 30.0},
  ];

  // Product Performance
  final List<Map<String, dynamic>> productPerformance = [
    {'product': 'T-Shirt White', 'orders': 1250, 'quantity': 4850, 'revenue': 1285250, 'cost': 898800, 'profit': 386450, 'margin': 30.1, 'status': 'Best Seller'},
    {'product': 'Polo Blue', 'orders': 980, 'quantity': 4620, 'revenue': 1293600, 'cost': 905520, 'profit': 388080, 'margin': 30.0, 'status': 'Best Seller'},
    {'product': 'Jeans Blue', 'orders': 850, 'quantity': 3750, 'revenue': 1687500, 'cost': 1181250, 'profit': 506250, 'margin': 30.0, 'status': 'High Value'},
    {'product': 'Dress Floral', 'orders': 720, 'quantity': 3350, 'revenue': 2345000, 'cost': 1641500, 'profit': 703500, 'margin': 30.0, 'status': 'High Margin'},
    {'product': 'Shirt Formal', 'orders': 680, 'quantity': 4100, 'revenue': 2255000, 'cost': 1578500, 'profit': 676500, 'margin': 30.0, 'status': 'Steady'},
    {'product': 'Jacket Leather', 'orders': 420, 'quantity': 2420, 'revenue': 1936000, 'cost': 1355200, 'profit': 580800, 'margin': 30.0, 'status': 'Seasonal'},
    {'product': 'Sweater Wool', 'orders': 280, 'quantity': 1200, 'revenue': 960000, 'cost': 720000, 'profit': 240000, 'margin': 25.0, 'status': 'Slow'},
  ];

  // Customer Behavior
  final List<Map<String, dynamic>> customerSegments = [
    {'segment': 'Premium', 'customers': 28, 'orders': 1850, 'avgValue': 12500, 'revenue': 23125000, 'percentage': 45},
    {'segment': 'Regular', 'customers': 42, 'orders': 2450, 'avgValue': 6800, 'revenue': 16660000, 'percentage': 32},
    {'segment': 'Economy', 'customers': 35, 'orders': 1850, 'avgValue': 3500, 'revenue': 6475000, 'percentage': 23},
  ];

  // Seasonal Trends
  final List<Map<String, dynamic>> seasonalTrends = [
    {'season': 'Summer', 'months': 'Mar-Jun', 'revenue': 2390000, 'topProduct': 'T-Shirt', 'growth': 28},
    {'season': 'Monsoon', 'months': 'Jul-Sep', 'revenue': 1850000, 'topProduct': 'Jacket', 'growth': 12},
    {'season': 'Winter', 'months': 'Oct-Feb', 'revenue': 2980000, 'topProduct': 'Sweater', 'growth': 35},
    {'season': 'Festival', 'months': 'Sep-Oct', 'revenue': 3420000, 'topProduct': 'Dress', 'growth': 42},
  ];

  // Supplier Performance
  final List<Map<String, dynamic>> supplierPerformance = [
    {'supplier': 'Fabric Hub Ltd', 'orders': 45, 'value': 1250000, 'onTime': 92, 'quality': 88, 'cost': 'Competitive', 'rating': 4.2},
    {'supplier': 'Garment Makers', 'orders': 38, 'value': 980000, 'onTime': 88, 'quality': 85, 'cost': 'Medium', 'rating': 4.0},
    {'supplier': 'Style Suppliers', 'orders': 52, 'value': 2100000, 'onTime': 95, 'quality': 92, 'cost': 'High', 'rating': 4.5},
    {'supplier': 'Fashion Imports', 'orders': 25, 'value': 890000, 'onTime': 82, 'quality': 78, 'cost': 'Low', 'rating': 3.5},
  ];

  // Profitability by Product Category
  final List<Map<String, dynamic>> profitabilityData = [
    {'category': 'T-Shirts', 'revenue': 3250000, 'cost': 2275000, 'profit': 975000, 'margin': 30},
    {'category': 'Shirts', 'revenue': 2850000, 'cost': 1995000, 'profit': 855000, 'margin': 30},
    {'category': 'Jeans', 'revenue': 2450000, 'cost': 1715000, 'profit': 735000, 'margin': 30},
    {'category': 'Dresses', 'revenue': 2980000, 'cost': 2086000, 'profit': 894000, 'margin': 30},
    {'category': 'Jackets', 'revenue': 1890000, 'cost': 1512000, 'profit': 378000, 'margin': 20},
    {'category': 'Sweaters', 'revenue': 1250000, 'cost': 1000000, 'profit': 250000, 'margin': 20},
  ];

  // Recent Orders
  final List<Map<String, dynamic>> recentOrders = [
    {'orderId': 'ORD-1001', 'customer': 'Fashion Hub Ltd', 'date': '2024-03-15', 'amount': 12500, 'items': 50, 'status': 'Delivered', 'profit': 3750},
    {'orderId': 'ORD-1002', 'customer': 'Style Mart Inc', 'date': '2024-03-14', 'amount': 8900, 'items': 32, 'status': 'Delivered', 'profit': 2670},
    {'orderId': 'ORD-1003', 'customer': 'Urban Threads', 'date': '2024-03-13', 'amount': 7200, 'items': 28, 'status': 'Processing', 'profit': 2160},
    {'orderId': 'ORD-1004', 'customer': 'Elite Fashion', 'date': '2024-03-12', 'amount': 15400, 'items': 62, 'status': 'Shipped', 'profit': 4620},
    {'orderId': 'ORD-1005', 'customer': 'Trendy Wear', 'date': '2024-03-11', 'amount': 4300, 'items': 18, 'status': 'Delivered', 'profit': 1290},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'Order Analysis',
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
            Tab(text: 'Sales & Profit', icon: Icon(Icons.trending_up)),
            Tab(text: 'Products & Customers', icon: Icon(Icons.shopping_bag)),
            Tab(text: 'Insights & Actions', icon: Icon(Icons.insights)),
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
                selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(value: 'This Quarter', child: Text('This Quarter')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
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
          _buildSalesProfitTab(),
          _buildProductsCustomersTab(),
          _buildInsightsActionsTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: SALES & PROFIT ====================
  Widget _buildSalesProfitTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildKeyMetricsCards(),
              const SizedBox(height: 20),
              _buildSalesRevenueChart(),
              const SizedBox(height: 20),
              _buildProfitabilityChart(),
              const SizedBox(height: 20),
              _buildProfitMarginAnalysis(),
              const SizedBox(height: 20),
              _buildRecentOrdersTable(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: PRODUCTS & CUSTOMERS ====================
  Widget _buildProductsCustomersTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProductPerformanceTable(),
              const SizedBox(height: 20),
              _buildCustomerSegments(),
              const SizedBox(height: 20),
              _buildSeasonalTrends(),
              const SizedBox(height: 20),
              _buildSupplierPerformance(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: INSIGHTS & ACTIONS ====================
  Widget _buildInsightsActionsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildOwnerInsights(),
              const SizedBox(height: 20),
              _buildActionableRecommendations(),
              const SizedBox(height: 20),
              _buildProfitOptimization(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== KEY METRICS CARDS ====================
  Widget _buildKeyMetricsCards() {
    int totalOrders = salesData.fold(0, (sum, item) => sum + (item['orders'] as int));
    double totalRevenue = salesData.fold(0.0, (sum, item) => sum + (item['revenue'] as int));
    double totalProfit = salesData.fold(0.0, (sum, item) => sum + (item['profit'] as int));
    double avgOrderValue = totalRevenue / totalOrders;
    double avgMargin = (totalProfit / totalRevenue) * 100;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              title: 'Total Orders',
              value: NumberFormat('#,###').format(totalOrders),
              subtitle: 'Orders',
              icon: FontAwesomeIcons.shoppingCart,
              color: AppColors.primaryColor,
              change: '+18% vs last period',
              detail: 'Total sales orders',
            ),
            _buildMetricCard(
              title: 'Total Revenue',
              value: '₹${(totalRevenue / 10000000).toStringAsFixed(2)}Cr',
              subtitle: 'Revenue',
              icon: FontAwesomeIcons.rupeeSign,
              color: AppColors.accentColor,
              change: '+22% growth',
              detail: 'Total sales value',
            ),
            _buildMetricCard(
              title: 'Total Profit',
              value: '₹${(totalProfit / 10000000).toStringAsFixed(2)}Cr',
              subtitle: 'Profit',
              icon: FontAwesomeIcons.chartLine,
              color: Colors.green,
              change: '${avgMargin.toStringAsFixed(1)}% margin',
              detail: 'Net profit earned',
            ),
            _buildMetricCard(
              title: 'Avg Order Value',
              value: '₹${(avgOrderValue).toStringAsFixed(0)}',
              subtitle: 'Per Order',
              icon: FontAwesomeIcons.wallet,
              color: Colors.orange,
              change: '+5% increase',
              detail: 'Average ticket size',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String change,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.slate600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: GoogleFonts.poppins(
              fontSize: 7,
              color: AppColors.slate600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== SALES REVENUE CHART ====================
  Widget _buildSalesRevenueChart() {
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
            'Sales Performance Trend',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.veryLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Revenue increased by 56% from Jan to Jun. Average order value: ₹2,250',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppColors.lightGray,
                      strokeWidth: 0.5,
                    );
                  },
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
                        if (value.toInt() >= 0 && value.toInt() < salesData.length) {
                          return Text(
                            salesData[value.toInt()]['month'],
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
                borderData: FlBorderData(show: true, border: Border.all(color: AppColors.lightGray)),
                minY: 0,
                maxY: 700000,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(salesData.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        (salesData[index]['revenue'] as int).toDouble(),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Revenue Trend', AppColors.accentColor),
              const SizedBox(width: 20),
              _buildLegend('Orders: ${salesData.last['orders']}', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PROFITABILITY CHART ====================
 // ==================== PROFITABILITY CHART ====================
Widget _buildProfitabilityChart() {
  // Find max profit to set appropriate chart height
  double maxProfit = profitabilityData.fold(0.0, (max, item) => 
    (item['profit'] as int) > max ? (item['profit'] as int).toDouble() : max);
  
  // Add 20% buffer above max profit for better visibility
  double chartMaxY = maxProfit * 1.2;
  
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
          'Profitability Analysis',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.veryLightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Expanded(
          child: Text(
  'Total Profit: ₹${(profitabilityData.fold(0.0, (sum, item) => sum + (item['profit'] as int)) / 100000).toStringAsFixed(1)}L | Highest: Dresses (₹${((profitabilityData[3]['profit'] as int) / 100000).toStringAsFixed(1)}L) | Lowest: Sweaters (₹${((profitabilityData[5]['profit'] as int) / 100000).toStringAsFixed(1)}L)',
  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600),
),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              minY: 0,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: chartMaxY / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${(value / 1000).toStringAsFixed(0)}k',
                        style: GoogleFonts.poppins(fontSize: 9),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < profitabilityData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            profitabilityData[value.toInt()]['category'],
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500),
                          ),
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
              borderData: FlBorderData(show: true, border: Border.all(color: AppColors.lightGray)),
              barGroups: List.generate(profitabilityData.length, (index) {
                int profit = profitabilityData[index]['profit'] as int;
                int margin = profitabilityData[index]['margin'] as int;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: profit.toDouble(),
                      color: margin >= 30 ? AppColors.accentColor : Colors.orange,
                      width: 30,
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: chartMaxY,
                        color: AppColors.lightGray.withOpacity(0.1),
                      ),
                    ),
                  ],
                );
              }),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                horizontalInterval: chartMaxY / 5,
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: AppColors.lightGray,
                    strokeWidth: 0.5,
                  );
                },
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.lightGray,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('High Margin (≥30%)', style: GoogleFonts.poppins(fontSize: 10)),
            const SizedBox(width: 20),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text('Low Margin (<30%)', style: GoogleFonts.poppins(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
             child: Text(
  'Dresses and Shirts contribute 48% of total profit. Focus on improving Jackets & Sweaters margin from 20% to 30% to add ₹${(((profitabilityData[4]['profit'] as int) * 0.5 + (profitabilityData[5]['profit'] as int) * 0.5) / 100000).toStringAsFixed(1)}L more profit.',
  style: GoogleFonts.poppins(fontSize: 10, color: Colors.green),
),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  // ==================== PROFIT MARGIN ANALYSIS ====================
  Widget _buildProfitMarginAnalysis() {
    double totalRevenue = salesData.fold(0.0, (sum, item) => sum + (item['revenue'] as int));
    double totalProfit = salesData.fold(0.0, (sum, item) => sum + (item['profit'] as int));
    double avgMargin = (totalProfit / totalRevenue) * 100;
    
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
            'Profit Margin Analysis',
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
                child: _buildMarginCard('Average Margin', '${avgMargin.toStringAsFixed(1)}%', Colors.green, 
                    'Industry average: 25-35%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMarginCard('Best Margin', '30.1%', AppColors.accentColor,
                    'T-Shirt White - 30.1% margin'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMarginCard('Lowest Margin', '20%', Colors.orange,
                    'Jackets & Sweaters - 20% margin'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: avgMargin / 35,
            backgroundColor: AppColors.lightGray,
            color: Colors.green,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Margin: ${avgMargin.toStringAsFixed(1)}%', 
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('Target: 35%', 
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarginCard(String title, String value, Color color, String detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 10, color: color)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(detail, style: GoogleFonts.poppins(fontSize: 8, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ==================== RECENT ORDERS TABLE ====================
  Widget _buildRecentOrdersTable() {
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
            'Recent Orders',
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
              headingTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              columns: const [
                DataColumn(label: Text('Order ID')),
                DataColumn(label: Text('Customer')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('Items'), numeric: true),
                DataColumn(label: Text('Profit'), numeric: true),
                DataColumn(label: Text('Status')),
              ],
              rows: recentOrders.map((order) {
                Color statusColor = order['status'] == 'Delivered' 
                    ? AppColors.accentColor
                    : order['status'] == 'Processing'
                        ? Colors.orange
                        : AppColors.primaryColor;
                return DataRow(
                  cells: [
                    DataCell(Text(order['orderId'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(order['customer'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(order['date'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('₹${(order['amount'] / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(order['items'].toString(), style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('₹${(order['profit'] / 1000).toStringAsFixed(0)}k', 
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.green))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(order['status'], style: GoogleFonts.poppins(fontSize: 9, color: statusColor)),
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

  // ==================== PRODUCT PERFORMANCE TABLE ====================
  Widget _buildProductPerformanceTable() {
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
            'Product Performance Analysis',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.veryLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Top 3 products contribute 45% of total revenue. Focus on high-margin items.',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateProperty.all(AppColors.veryLightGray),
              headingTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Orders'), numeric: true),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Revenue'), numeric: true),
                DataColumn(label: Text('Profit'), numeric: true),
                DataColumn(label: Text('Margin'), numeric: true),
                DataColumn(label: Text('Status')),
              ],
              rows: productPerformance.map((product) {
                Color marginColor = (product['margin'] as double) >= 30 ? Colors.green : Colors.orange;
                return DataRow(
                  cells: [
                    DataCell(Text(product['product'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(product['orders'].toString(), style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(product['quantity'].toString(), style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('₹${(product['revenue'] / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('₹${(product['profit'] / 1000).toStringAsFixed(0)}k', 
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.green))),
                    DataCell(Text('${product['margin']}%', 
                        style: GoogleFonts.poppins(fontSize: 11, color: marginColor, fontWeight: FontWeight.w500))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product['status'] == 'Best Seller' 
                              ? Colors.green.withOpacity(0.1)
                              : product['status'] == 'Slow'
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(product['status'], 
                            style: GoogleFonts.poppins(fontSize: 9, 
                                color: product['status'] == 'Best Seller' 
                                    ? Colors.green
                                    : product['status'] == 'Slow'
                                        ? Colors.red
                                        : Colors.blue)),
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

  // ==================== CUSTOMER SEGMENTS ====================
  Widget _buildCustomerSegments() {
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
            'Customer Segmentation',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ...customerSegments.map((segment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: segment['segment'] == 'Premium' 
                                  ? Colors.green
                                  : segment['segment'] == 'Regular'
                                      ? Colors.blue
                                      : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(segment['segment'], 
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Text('(${segment['customers']} customers)', 
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600)),
                        ],
                      ),
                      Text('${segment['percentage']}% revenue',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (segment['percentage'] as int) / 100,
                    backgroundColor: AppColors.lightGray,
                    color: segment['segment'] == 'Premium' ? Colors.green : Colors.blue,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Avg Order: ₹${(segment['avgValue'] / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600)),
                      Text('Orders: ${segment['orders']}',
                          style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600)),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==================== SEASONAL TRENDS ====================
  Widget _buildSeasonalTrends() {
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
            'Seasonal Trends Analysis',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemCount: seasonalTrends.length,
              itemBuilder: (context, index) {
                final season = seasonalTrends[index];
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.veryLightGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (season['growth'] as int) > 30 ? Colors.green : Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(season['season'], 
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(season['months'], 
                          style: GoogleFonts.poppins(fontSize: 9, color: AppColors.slate600)),
                      const SizedBox(height: 8),
                     Text('Revenue: ₹${((season['revenue'] as int) / 100000).toStringAsFixed(1)}L',
    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
                      Text('Top: ${season['topProduct']}',
                          style: GoogleFonts.poppins(fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (season['growth'] as int) > 30 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('+${season['growth']}% growth',
                            style: GoogleFonts.poppins(fontSize: 9, 
                                color: (season['growth'] as int) > 30 ? Colors.green : Colors.orange)),
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

  // ==================== SUPPLIER PERFORMANCE ====================
  Widget _buildSupplierPerformance() {
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
            'Supplier Performance',
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
              headingTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              columns: const [
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('Orders'), numeric: true),
                DataColumn(label: Text('Value'), numeric: true),
                DataColumn(label: Text('On-Time'), numeric: true),
                DataColumn(label: Text('Quality'), numeric: true),
                DataColumn(label: Text('Cost')),
                DataColumn(label: Text('Rating')),
              ],
              rows: supplierPerformance.map((supplier) {
                Color ratingColor = (supplier['rating'] as double) >= 4.0 ? Colors.green : Colors.orange;
                return DataRow(
                  cells: [
                    DataCell(Text(supplier['supplier'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(supplier['orders'].toString(), style: GoogleFonts.poppins(fontSize: 11))),
     DataCell(Text('₹${((supplier['value'] as int) / 100000).toStringAsFixed(1)}L', 
    style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('${supplier['onTime']}%', 
                        style: GoogleFonts.poppins(fontSize: 11, 
                            color: (supplier['onTime'] as int) >= 90 ? Colors.green : Colors.orange))),
                    DataCell(Text('${supplier['quality']}%', 
                        style: GoogleFonts.poppins(fontSize: 11,
                            color: (supplier['quality'] as int) >= 85 ? Colors.green : Colors.orange))),
                    DataCell(Text(supplier['cost'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(supplier['rating'].toString(), 
                        style: GoogleFonts.poppins(fontSize: 11, color: ratingColor, fontWeight: FontWeight.w500))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== OWNER INSIGHTS ====================
  Widget _buildOwnerInsights() {
    double totalRevenue = salesData.fold(0.0, (sum, item) => sum + (item['revenue'] as int));
    double totalProfit = salesData.fold(0.0, (sum, item) => sum + (item['profit'] as int));
    double avgMargin = (totalProfit / totalRevenue) * 100;
    int bestSellerCount = productPerformance.where((p) => p['status'] == 'Best Seller').length;
    int slowProductCount = productPerformance.where((p) => p['status'] == 'Slow').length;
    
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
              Icon(Icons.insights, color: AppColors.paleYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Owner\'s Business Insights',
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
            '💰 Revenue & Profit',
            'Total revenue: ₹${(totalRevenue / 10000000).toStringAsFixed(2)}Cr | Profit: ₹${(totalProfit / 10000000).toStringAsFixed(2)}Cr | Margin: ${avgMargin.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '⭐ Best Sellers',
            '$bestSellerCount products are top performers - T-Shirt White, Polo Blue, Jeans Blue contribute 35% of revenue',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '🐌 Slow Movers',
            '$slowProductCount products need attention - Sweater and Jacket have low turnover, consider discounts',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '👥 Customer Premium Segment',
            'Premium customers (28) generate 45% of revenue with avg order value ₹12,500',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '📈 Growth Opportunity',
            'Festival season shows 42% growth potential - Stock up on Dresses and Ethnic wear',
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONABLE RECOMMENDATIONS ====================
  Widget _buildActionableRecommendations() {
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
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Actionable Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            '🎯 What to Buy',
            'Increase stock of T-Shirts (+35%), Polos (+28%), Dresses (+42% for festival)',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            '📦 What to Clear',
            'Clear Sweater stock with 25% discount, Jacket with bundle offers (Buy 1 Get 1)',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            '💰 Pricing Strategy',
            'Increase margin on Premium products by 5%, offer bundle on slow movers',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            '📅 Seasonal Planning',
            'Start festival stock 45 days in advance, increase Dress category by 50%',
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            '🤝 Supplier Action',
            'Review Fashion Imports (78% quality), consider alternative for low-quality supplies',
            Colors.red,
          ),
        ],
      ),
    );
  }

  // ==================== PROFIT OPTIMIZATION ====================
  Widget _buildProfitOptimization() {
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
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Profit Optimization Opportunities',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOptimizationItem(
            'Increase Average Order Value',
            'Current: ₹2,250 | Target: ₹2,800',
            '+24% potential profit increase',
            65,
          ),
          const SizedBox(height: 12),
          _buildOptimizationItem(
            'Improve Margin on Jackets',
            'Current: 20% | Target: 28%',
            '+40% profit on jacket category',
            40,
          ),
          const SizedBox(height: 12),
          _buildOptimizationItem(
            'Customer Retention',
            'Current repeat rate: 45% | Target: 60%',
            'Additional ₹25L revenue potential',
            55,
          ),
          const SizedBox(height: 12),
          _buildOptimizationItem(
            'Reduce Slow Moving Stock',
            'Current dead stock value: ₹15L | Target: ₹5L',
            'Release ₹10L working capital',
            30,
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

  Widget _buildRecommendationCard(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                Text(description, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationItem(String title, String current, String potential, int progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(current, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: AppColors.lightGray,
          color: Colors.green,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Text(potential, style: GoogleFonts.poppins(fontSize: 10, color: Colors.green)),
      ],
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
        Text(label, style: GoogleFonts.poppins(fontSize: 10)),
      ],
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Report', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Export order analysis report as PDF?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order report exported successfully!', style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.accentColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }
}