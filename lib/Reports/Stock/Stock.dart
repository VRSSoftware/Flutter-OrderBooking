import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class StockAnalysis extends StatefulWidget {
  const StockAnalysis({super.key});

  @override
  State<StockAnalysis> createState() => _StockAnalysisState();
}

class _StockAnalysisState extends State<StockAnalysis>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'All';
  String selectedState = 'All';

  // Stock by Style with detailed calculations
  final List<Map<String, dynamic>> styleWiseStock = [
    {
      'style': 'T-Shirt', 
      'opening': 2500, 
      'received': 5000, 
      'sold': 4850, 
      'closing': 2650, 
      'avgPrice': 265, // Average selling price per unit
      'value': 1325000, // 2650 * 500
      'turnover': 1.83, // 4850 / 2650
      'color': Colors.blue,
      'explanation': 'Sold 4850 units, closing stock 2650 units'
    },
    {
      'style': 'Polo', 
      'opening': 1800, 
      'received': 4500, 
      'sold': 4620, 
      'closing': 1680, 
      'avgPrice': 280,
      'value': 1008000, 
      'turnover': 2.75, 
      'color': Colors.green,
      'explanation': 'High turnover - selling well'
    },
    {
      'style': 'Jeans', 
      'opening': 2200, 
      'received': 3800, 
      'sold': 3750, 
      'closing': 2250, 
      'avgPrice': 450,
      'value': 1687500, 
      'turnover': 1.67, 
      'color': Colors.orange,
      'explanation': 'Moderate turnover - needs attention'
    },
    {
      'style': 'Jacket', 
      'opening': 1200, 
      'received': 2500, 
      'sold': 2420, 
      'closing': 1280, 
      'avgPrice': 800,
      'value': 1024000, 
      'turnover': 1.89, 
      'color': Colors.purple,
      'explanation': 'Seasonal product - slow movement'
    },
    {
      'style': 'Dress', 
      'opening': 1500, 
      'received': 3200, 
      'sold': 3350, 
      'closing': 1350, 
      'avgPrice': 700,
      'value': 945000, 
      'turnover': 2.23, 
      'color': Colors.pink,
      'explanation': 'Good performance'
    },
    {
      'style': 'Shirt', 
      'opening': 2000, 
      'received': 4200, 
      'sold': 4100, 
      'closing': 2100, 
      'avgPrice': 550,
      'value': 1155000, 
      'turnover': 1.95, 
      'color': Colors.teal,
      'explanation': 'Stable demand'
    },
    {
      'style': 'Trousers', 
      'opening': 1700, 
      'received': 3500, 
      'sold': 3400, 
      'closing': 1800, 
      'avgPrice': 600,
      'value': 1080000, 
      'turnover': 1.89, 
      'color': Colors.brown,
      'explanation': 'Needs promotion'
    },
    {
      'style': 'Sweater', 
      'opening': 800, 
      'received': 1800, 
      'sold': 1200, 
      'closing': 1400, 
      'avgPrice': 800,
      'value': 1120000, 
      'turnover': 0.86, 
      'color': Colors.indigo,
      'explanation': 'Very slow - seasonal product'
    },
  ];

  // State wise stock distribution
  final List<Map<String, dynamic>> stateWiseStock = [
    {'state': 'Maharashtra', 'stock': 12500, 'value': 6250000, 'percentage': 28, 'warehouses': 3, 'color': Colors.blue},
    {'state': 'Tamil Nadu', 'stock': 9800, 'value': 4900000, 'percentage': 22, 'warehouses': 2, 'color': Colors.green},
    {'state': 'Gujarat', 'stock': 7500, 'value': 3750000, 'percentage': 17, 'warehouses': 2, 'color': Colors.orange},
    {'state': 'Karnataka', 'stock': 6800, 'value': 3400000, 'percentage': 15, 'warehouses': 2, 'color': Colors.purple},
    {'state': 'Delhi NCR', 'stock': 5200, 'value': 2600000, 'percentage': 12, 'warehouses': 1, 'color': Colors.pink},
    {'state': 'West Bengal', 'stock': 2800, 'value': 1400000, 'percentage': 6, 'warehouses': 1, 'color': Colors.teal},
  ];

  // Fast Moving Products
  final List<Map<String, dynamic>> fastMovingProducts = [
    {'product': 'T-Shirt White', 'style': 'T-Shirt', 'monthlySales': 1250, 'stockTurnover': 4.2, 'daysInStock': 15, 'reorderLevel': 500, 'status': 'Critical'},
    {'product': 'Polo Blue', 'style': 'Polo', 'monthlySales': 980, 'stockTurnover': 3.8, 'daysInStock': 18, 'reorderLevel': 400, 'status': 'Critical'},
    {'product': 'Jeans Blue', 'style': 'Jeans', 'monthlySales': 850, 'stockTurnover': 3.5, 'daysInStock': 20, 'reorderLevel': 350, 'status': 'Low'},
    {'product': 'Dress Floral', 'style': 'Dress', 'monthlySales': 720, 'stockTurnover': 3.2, 'daysInStock': 22, 'reorderLevel': 300, 'status': 'Low'},
    {'product': 'Shirt Formal', 'style': 'Shirt', 'monthlySales': 680, 'stockTurnover': 3.0, 'daysInStock': 25, 'reorderLevel': 280, 'status': 'Normal'},
  ];

  // Slow Moving Products
  final List<Map<String, dynamic>> slowMovingProducts = [
    {'product': 'Sweater Wool', 'style': 'Sweater', 'monthlySales': 180, 'stockTurnover': 0.9, 'daysInStock': 120, 'excessStock': 800, 'action': 'Promote'},
    {'product': 'Jacket Leather', 'style': 'Jacket', 'monthlySales': 220, 'stockTurnover': 1.1, 'daysInStock': 95, 'excessStock': 450, 'action': 'Discount'},
    {'product': 'Trousers Cotton', 'style': 'Trousers', 'monthlySales': 250, 'stockTurnover': 1.3, 'daysInStock': 85, 'excessStock': 300, 'action': 'Bundle'},
    {'product': 'Jeans Black', 'style': 'Jeans', 'monthlySales': 280, 'stockTurnover': 1.4, 'daysInStock': 78, 'excessStock': 250, 'action': 'Promote'},
  ];

  // Dead Stock (No movement for >90 days)
  final List<Map<String, dynamic>> deadStock = [
    {'product': 'Winter Jacket Old', 'style': 'Jacket', 'quantity': 450, 'value': 315000, 'daysIdle': 180, 'reason': 'Seasonal', 'suggestedAction': 'Clearance Sale'},
    {'product': 'Sweater Red', 'style': 'Sweater', 'quantity': 320, 'value': 256000, 'daysIdle': 150, 'reason': 'Color not trending', 'suggestedAction': 'Discount'},
    {'product': 'T-Shirt Yellow', 'style': 'T-Shirt', 'quantity': 280, 'value': 140000, 'daysIdle': 120, 'reason': 'Unpopular color', 'suggestedAction': 'Bundle Offer'},
    {'product': 'Formal Pant', 'style': 'Trousers', 'quantity': 200, 'value': 160000, 'daysIdle': 100, 'reason': 'Size issue', 'suggestedAction': 'Return to vendor'},
    {'product': 'Polo Maroon', 'style': 'Polo', 'quantity': 150, 'value': 105000, 'daysIdle': 95, 'reason': 'Seasonal', 'suggestedAction': 'Promotion'},
  ];

  // Stock Aging Analysis
  final List<Map<String, dynamic>> stockAging = [
    {'period': '0-30 days', 'quantity': 18500, 'percentage': 42, 'color': Colors.green, 'explanation': 'Fresh stock - good'},
    {'period': '31-60 days', 'quantity': 12500, 'percentage': 28, 'color': Colors.lightGreen, 'explanation': 'Normal aging'},
    {'period': '61-90 days', 'quantity': 7800, 'percentage': 18, 'color': Colors.orange, 'explanation': 'Aging - needs monitoring'},
    {'period': '91-180 days', 'quantity': 3500, 'percentage': 8, 'color': Colors.deepOrange, 'explanation': 'Old stock - risk'},
    {'period': '180+ days', 'quantity': 1800, 'percentage': 4, 'color': Colors.red, 'explanation': 'Dead stock - urgent action'},
  ];

  // Monthly Stock Movement
  final List<Map<String, dynamic>> monthlyStockMovement = [
    {'month': 'Jan', 'inward': 18500, 'outward': 17200, 'closing': 44200},
    {'month': 'Feb', 'inward': 19200, 'outward': 18500, 'closing': 44900},
    {'month': 'Mar', 'inward': 21000, 'outward': 19800, 'closing': 46100},
    {'month': 'Apr', 'inward': 20500, 'outward': 21200, 'closing': 45400},
    {'month': 'May', 'inward': 22800, 'outward': 23500, 'closing': 44700},
    {'month': 'Jun', 'inward': 24500, 'outward': 23800, 'closing': 45400},
  ];

  // Reorder Recommendations
  final List<Map<String, dynamic>> reorderRecommendations = [
    {'product': 'T-Shirt White', 'currentStock': 350, 'reorderLevel': 500, 'urgent': true, 'recommendedQty': 2000},
    {'product': 'Polo Blue', 'currentStock': 280, 'reorderLevel': 400, 'urgent': true, 'recommendedQty': 1500},
    {'product': 'Jeans Blue', 'currentStock': 420, 'reorderLevel': 350, 'urgent': false, 'recommendedQty': 1200},
    {'product': 'Shirt White', 'currentStock': 180, 'reorderLevel': 280, 'urgent': true, 'recommendedQty': 1000},
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
          'Stock Analysis',
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
            Tab(text: 'Stock Overview', icon: Icon(Icons.inventory)),
            Tab(text: 'Movement Analysis', icon: Icon(Icons.trending_up)),
            Tab(text: 'Actionable Insights', icon: Icon(Icons.insights)),
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
                  selectedCategory = 'All';
                } else {
                  selectedCategory = value;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Products')),
              const PopupMenuItem(value: 'T-Shirt', child: Text('T-Shirt')),
              const PopupMenuItem(value: 'Polo', child: Text('Polo')),
              const PopupMenuItem(value: 'Jeans', child: Text('Jeans')),
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
          _buildStockOverviewTab(),
          _buildMovementAnalysisTab(),
          _buildActionableInsightsTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: STOCK OVERVIEW ====================
  Widget _buildStockOverviewTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStockMetricsCards(),
              const SizedBox(height: 20),
              _buildStyleWiseStockTable(),
              const SizedBox(height: 20),
              _buildStateWiseStock(),
              const SizedBox(height: 20),
              _buildStockAgingChart(),
              const SizedBox(height: 20),
              _buildDeadStockAnalysis(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: MOVEMENT ANALYSIS ====================
  Widget _buildMovementAnalysisTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStockMovementChart(),
              const SizedBox(height: 20),
              _buildFastMovingProducts(),
              const SizedBox(height: 20),
              _buildSlowMovingProducts(),
              const SizedBox(height: 20),
              _buildTurnoverAnalysis(),
              const SizedBox(height: 20),
              _buildTurnoverExplanation(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: ACTIONABLE INSIGHTS ====================
  Widget _buildActionableInsightsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildReorderRecommendations(),
              const SizedBox(height: 20),
              _buildStockHealthCards(),
              const SizedBox(height: 20),
              _buildActionableInsights(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== STOCK METRICS CARDS ====================
// ==================== STOCK METRICS CARDS ====================
Widget _buildStockMetricsCards() {
  int totalStock = styleWiseStock.fold(0, (sum, item) => sum + (item['closing'] as int));
  double totalValue = styleWiseStock.fold(0.0, (sum, item) => sum + (item['value'] as int));
  int deadStockQty = deadStock.fold(0, (sum, item) => sum + (item['quantity'] as int));
  double avgTurnover = styleWiseStock.fold(0.0, (sum, item) => sum + (item['turnover'] as double)) / styleWiseStock.length;
  
  return LayoutBuilder(
    builder: (context, constraints) {
      // Make cards responsive based on screen width
      int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
      double childAspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.3;
      
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
        children: [
          _buildMetricCard(
            title: 'Total Stock',
            value: NumberFormat('#,###').format(totalStock),
            subtitle: 'Units',
            icon: FontAwesomeIcons.boxes,
            color: AppColors.primaryColor,
            change: '+8% vs last month',
            detail: 'Total closing stock',
          ),
          _buildMetricCard(
            title: 'Stock Value',
            value: '₹${(totalValue / 10000000).toStringAsFixed(2)}Cr',
            subtitle: 'Total Value',
            icon: FontAwesomeIcons.rupeeSign,
            color: AppColors.accentColor,
            change: '+5.2% increase',
            detail: 'Inventory value',
          ),
          _buildMetricCard(
            title: 'Dead Stock',
            value: deadStockQty.toString(),
            subtitle: 'Units',
            icon: FontAwesomeIcons.skull,
            color: Colors.red,
            change: '₹${((deadStockQty * 700) / 1000).toStringAsFixed(0)}k risk',
            detail: 'No movement >90 days',
          ),
          _buildMetricCard(
            title: 'Avg Turnover',
            value: avgTurnover.toStringAsFixed(1),
            subtitle: 'Ratio',
            icon: FontAwesomeIcons.rotateLeft,
            color: Colors.orange,
            change: avgTurnover > 2 ? 'Healthy' : 'Needs improvement',
            detail: 'Stock rotation rate',
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
                  fontSize: 18,
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

  // ==================== STYLE WISE STOCK TABLE ====================
  Widget _buildStyleWiseStockTable() {
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
            'Style-wise Stock Analysis',
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
                    'Turnover = Units Sold ÷ Closing Stock. Higher turnover means faster selling. Target: >2.0',
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              horizontalMargin: 12,
              headingRowColor: MaterialStateProperty.all(AppColors.veryLightGray),
              headingTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(8),
              ),
              columns: const [
                DataColumn(label: Text('Style')),
                DataColumn(label: Text('Opening'), numeric: true),
                DataColumn(label: Text('Received'), numeric: true),
                DataColumn(label: Text('Sold'), numeric: true),
                DataColumn(label: Text('Closing'), numeric: true),
                DataColumn(label: Text('Avg Price'), numeric: true),
                DataColumn(label: Text('Value (₹)'), numeric: true),
                DataColumn(label: Text('Turnover'), numeric: true),
              ],
              rows: styleWiseStock.map((style) {
                double turnoverValue = style['turnover'] as double;
                Color turnoverColor = turnoverValue >= 2 ? AppColors.accentColor : Colors.orange;
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: style['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(style['style'], style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                    DataCell(Text(NumberFormat('#,###').format(style['opening']), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(style['received']), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(style['sold']), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(style['closing']), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text('₹${style['avgPrice']}', style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text('₹${((style['value'] as int) / 100000).toStringAsFixed(1)}L', style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(
                      Tooltip(
                        message: '${style['explanation']}\nCalculation: ${style['sold']} ÷ ${style['closing']} = ${turnoverValue.toStringAsFixed(2)}',
                        child: Text(
                          turnoverValue.toStringAsFixed(2),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: turnoverColor,
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

  // ==================== STATE WISE STOCK ====================
  Widget _buildStateWiseStock() {
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
            'State-wise Stock Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ...stateWiseStock.map((state) {
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
                              color: state['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state['state'],
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${state['warehouses']} warehouses)',
                            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600),
                          ),
                        ],
                      ),
                      Text(
                        '${state['percentage']}%',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: state['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (state['percentage'] as int) / 100,
                    backgroundColor: AppColors.lightGray,
                    color: state['color'] as Color,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${NumberFormat('#,###').format(state['stock'])} units',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600),
                      ),
                      Text(
                        '₹${((state['value'] as int) / 10000000).toStringAsFixed(2)} Cr',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600),
                      ),
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

  // ==================== STOCK AGING CHART ====================
  Widget _buildStockAgingChart() {
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
            'Stock Aging Analysis',
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
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stock aging >90 days is a concern. Total ₹${((stockAging.where((a) => a['period'] == '91-180 days' || a['period'] == '180+ days').fold(0, (sum, a) => sum + (a['quantity'] as int)) * 700) / 100000).toStringAsFixed(1)}L value at risk',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: stockAging.map((aging) {
                  return PieChartSectionData(
                    value: (aging['percentage'] as int).toDouble(),
                    title: '${aging['period']}\n${aging['percentage']}%',
                    radius: 80,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    color: aging['color'] as Color,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: stockAging.map((aging) {
              return Tooltip(
                message: aging['explanation'],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: aging['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      aging['period'],
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== DEAD STOCK ANALYSIS ====================
  Widget _buildDeadStockAnalysis() {
    int totalDeadStockValue = deadStock.fold(0, (sum, item) => sum + (item['value'] as int));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Dead Stock Alert',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total dead stock value: ₹${(totalDeadStockValue / 100000).toStringAsFixed(1)}L. Immediate action required to recover value.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 12,
              horizontalMargin: 12,
              headingRowColor: MaterialStateProperty.all(Colors.red.withOpacity(0.1)),
              headingTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.red,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Quantity'), numeric: true),
                DataColumn(label: Text('Value'), numeric: true),
                DataColumn(label: Text('Days Idle'), numeric: true),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Suggested Action')),
              ],
              rows: deadStock.map((stock) {
                return DataRow(
                  cells: [
                    DataCell(Text(stock['product'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(stock['quantity'].toString(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red))),
                    DataCell(Text('₹${((stock['value'] as int) / 1000).toStringAsFixed(0)}k', style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text('${stock['daysIdle']} days', style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(Text(stock['reason'], style: GoogleFonts.poppins(fontSize: 11))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stock['suggestedAction'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.orange,
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

  // ==================== STOCK MOVEMENT CHART ====================
  Widget _buildStockMovementChart() {
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
            'Stock Movement Trend',
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
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthlyStockMovement.length) {
                          return Text(
                            monthlyStockMovement[value.toInt()]['month'],
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
                borderData: FlBorderData(show: true, border: Border.all(color: AppColors.lightGray, width: 1)),
                minY: 0,
                maxY: 50000,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(monthlyStockMovement.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        (monthlyStockMovement[index]['inward'] as int).toDouble(),
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
                    spots: List.generate(monthlyStockMovement.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        (monthlyStockMovement[index]['outward'] as int).toDouble(),
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
              _buildLegend('Stock Inward (Purchase)', AppColors.accentColor),
              const SizedBox(width: 20),
              _buildLegend('Stock Outward (Sales)', Colors.orange),
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

  // ==================== FAST MOVING PRODUCTS ====================
  Widget _buildFastMovingProducts() {
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
              Icon(Icons.speed, color: AppColors.accentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Fast Moving Products',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'These products have high sales velocity. Stock turnover >3.0 means stock sells quickly.',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.accentColor),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: fastMovingProducts.length,
            itemBuilder: (context, index) {
              final product = fastMovingProducts[index];
              String status = product['status'] as String;
              Color statusColor = status == 'Critical' 
                  ? Colors.red
                  : status == 'Low'
                      ? Colors.orange
                      : AppColors.primaryColor;
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
                        Icons.trending_up,
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
                            product['product'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Turnover: ${product['stockTurnover']}x | Sells every ${product['daysInStock']} days',
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
                          '${product['monthlySales']} units/mo',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.accentColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status == 'Critical' ? 'REORDER NOW' : status,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
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

  // ==================== SLOW MOVING PRODUCTS ====================
  Widget _buildSlowMovingProducts() {
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
              Icon(Icons.trending_down, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Slow Moving Products',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Turnover <1.5 indicates slow sales. These products are tying up capital.',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: slowMovingProducts.length,
            itemBuilder: (context, index) {
              final product = slowMovingProducts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['product'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Turnover: ${product['stockTurnover']}x | Idle for ${product['daysInStock']} days',
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
                          '${product['monthlySales']} units/mo',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product['action'],
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
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

  // ==================== TURNOVER ANALYSIS ====================
  Widget _buildTurnoverAnalysis() {
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
            'Stock Turnover Analysis',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 4,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < styleWiseStock.length) {
                          return Text(
                            styleWiseStock[value.toInt()]['style'],
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
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
                barGroups: List.generate(styleWiseStock.length, (index) {
                  double turnoverValue = styleWiseStock[index]['turnover'] as double;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: turnoverValue,
                        color: turnoverValue >= 2 ? AppColors.accentColor : Colors.orange,
                        width: 25,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Target Turnover Ratio: 2.0 | Green = Good, Orange = Needs Improvement',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TURNOVER EXPLANATION ====================
  Widget _buildTurnoverExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.veryLightGray,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Understanding Stock Turnover',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'What is Stock Turnover?',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock Turnover = Units Sold ÷ Closing Stock',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Example: T-Shirt sold 4,850 units, closing stock 2,650 units',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600),
          ),
          Text(
            'Turnover = 4,850 ÷ 2,650 = 1.83',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.slate600),
          ),
          const SizedBox(height: 8),
          Text(
            'What it means:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Turnover > 2.0: Fast selling, good inventory management',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.green),
          ),
          Text(
            '• Turnover 1.5 - 2.0: Moderate, needs monitoring',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange),
          ),
          Text(
            '• Turnover < 1.5: Slow moving, capital blocked',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            'Target for Garment Industry: 2.0 - 4.0',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REORDER RECOMMENDATIONS ====================
  Widget _buildReorderRecommendations() {
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
              Icon(Icons.shopping_cart, color: AppColors.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Reorder Recommendations',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.veryLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Products below reorder level need immediate attention to avoid stockouts.',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.slate600),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: reorderRecommendations.length,
            itemBuilder: (context, index) {
              final rec = reorderRecommendations[index];
              bool isUrgent = rec['urgent'] as bool;
              int reorderQty = rec['recommendedQty'] as int;
              int currentStock = rec['currentStock'] as int;
              int reorderLevel = rec['reorderLevel'] as int;
              int shortfall = reorderLevel - currentStock;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: isUrgent 
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isUrgent ? Icons.priority_high : Icons.check_circle,
                        color: isUrgent ? Colors.red : AppColors.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec['product'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Current: $currentStock | Reorder Level: $reorderLevel | Shortfall: $shortfall units',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isUrgent ? Colors.red : AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Order: $reorderQty units',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isUrgent ? Colors.red : AppColors.accentColor,
                          ),
                        ),
                        Text(
                          'Value: ₹${((reorderQty * 500) / 1000).toStringAsFixed(0)}k',
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

  // ==================== STOCK HEALTH CARDS ====================
  Widget _buildStockHealthCards() {
    int healthyStock = styleWiseStock.where((s) => (s['turnover'] as double) >= 2).length;
    int criticalStock = fastMovingProducts.where((p) => p['status'] == 'Critical').length;
    int deadStockCount = deadStock.length;
    
    return Row(
      children: [
        Expanded(
          child: _buildHealthCard('Healthy SKUs', healthyStock.toString(), AppColors.accentColor, Icons.check_circle, 
              'Styles with turnover >2.0'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHealthCard('Critical Stock', criticalStock.toString(), Colors.red, Icons.warning,
              'Need immediate reordering'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHealthCard('Dead Stock', deadStockCount.toString(), Colors.orange, Icons.inventory_2,
              'No movement >90 days'),
        ),
      ],
    );
  }

  Widget _buildHealthCard(String title, String value, Color color, IconData icon, String detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== ACTIONABLE INSIGHTS ====================
  Widget _buildActionableInsights() {
    int deadStockValue = deadStock.fold(0, (sum, item) => sum + (item['value'] as int));
    double avgTurnover = styleWiseStock.fold(0.0, (sum, item) => sum + (item['turnover'] as double)) / styleWiseStock.length;
    
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
                'Actionable Insights',
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
            '📦 Fast Moving Alert',
            'T-Shirt White and Polo Blue are selling fast. Current stock will last only ${fastMovingProducts[0]['daysInStock']} days. Immediate reorder of ${fastMovingProducts[0]['reorderLevel']}+ units recommended.',
          ),
          const SizedBox(height: 12),
       _buildInsightItem(
  '🐌 Slow Moving Products',
  'Sweater (Turnover 0.9) and Leather Jacket (Turnover 1.1) are slow. Consider 20-30% discount or bundle offers to clear ₹${(((slowMovingProducts[0]['excessStock'] as int) * 800) / 100000).toStringAsFixed(1)}L worth stock.',
),
          const SizedBox(height: 12),
          _buildInsightItem(
            '⚠️ Dead Stock Risk',
            '₹${(deadStockValue / 100000).toStringAsFixed(1)}L value at risk from ${deadStock.length} products idle for >90 days. Immediate clearance sale recommended to recover at least 50% value.',
          ),
          const SizedBox(height: 12),
    _buildInsightItem(
  '📊 Stock Optimization',
  'Maharashtra holds 28% of total stock (₹${((stateWiseStock[0]['value'] as int) / 10000000).toStringAsFixed(2)}Cr). Consider redistributing to high-demand regions like Gujarat and Karnataka.',
),
          const SizedBox(height: 12),
         _buildInsightItem(
  '🎯 Turnover Improvement',
  'Current average turnover is ${avgTurnover.toStringAsFixed(1)} (target 2.0). Focus on Jacket (1.89) and Trousers (1.89) - improve by 15% to save ₹${(((styleWiseStock[3]['value'] as int) * 0.15) / 100000).toStringAsFixed(1)}L in carrying cost.',
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
          'Export stock analysis report as PDF?',
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
                    'Stock report exported successfully!',
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