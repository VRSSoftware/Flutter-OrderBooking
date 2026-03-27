import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class SalesAnalysis extends StatefulWidget {
  const SalesAnalysis({Key? key}) : super(key: key);

  @override
  State<SalesAnalysis> createState() => _SalesAnalysisState();
}

class _SalesAnalysisState extends State<SalesAnalysis> with SingleTickerProviderStateMixin {
  // Garment-specific sales data
  final Map<String, dynamic> _salesData = {
    'totalRevenue': 4589250,
    'totalOrders': 2847,
    'averageOrderValue': 1612.50,
    'conversionRate': 4.28,
    'weeklyGrowth': 18.5,
    'targetRevenue': 6000000,
    'profitMargin': 32.5,
  };

  final List<Map<String, dynamic>> _recentOrders = [
    {'id': 'GAR-1001', 'customer': 'Radhika Sharma', 'amount': 12500, 'status': 'Delivered', 'date': '2024-03-27', 'items': 'Kurta Set', 'payment': 'Online'},
    {'id': 'GAR-1002', 'customer': 'Priya Mehta', 'amount': 8750, 'status': 'Processing', 'date': '2024-03-27', 'items': 'Saree', 'payment': 'COD'},
    {'id': 'GAR-1003', 'customer': 'Anjali Verma', 'amount': 24500, 'status': 'Delivered', 'date': '2024-03-26', 'items': 'Designer Lehenga', 'payment': 'Online'},
    {'id': 'GAR-1004', 'customer': 'Neha Gupta', 'amount': 3450, 'status': 'Shipped', 'date': '2024-03-26', 'items': 'Cotton Salwar', 'payment': 'Card'},
    {'id': 'GAR-1005', 'customer': 'Kavita Singh', 'amount': 18900, 'status': 'Delivered', 'date': '2024-03-25', 'items': 'Wedding Lehenga', 'payment': 'Online'},
  ];

  final List<Map<String, dynamic>> _topProducts = [
    {'name': 'Designer Lehenga', 'sales': 342, 'revenue': 8450000, 'trend': '+23%', 'category': 'Wedding Wear', 'stock': 45, 'color': 0xFFE91E63},
    {'name': 'Banarasi Saree', 'sales': 528, 'revenue': 6320000, 'trend': '+15%', 'category': 'Traditional', 'stock': 78, 'color': 0xFF9C27B0},
    {'name': 'Cotton Kurti Set', 'sales': 1245, 'revenue': 3720000, 'trend': '+32%', 'category': 'Casual Wear', 'stock': 234, 'color': 0xFF4CAF50},
    {'name': 'Silk Blouse', 'sales': 892, 'revenue': 2140000, 'trend': '+8%', 'category': 'Ethnic', 'stock': 156, 'color': 0xFFFF9800},
    {'name': 'Embroidered Dupatta', 'sales': 756, 'revenue': 1890000, 'trend': '+12%', 'category': 'Accessories', 'stock': 89, 'color': 0xFF2196F3},
    {'name': 'Party Wear Gown', 'sales': 234, 'revenue': 4680000, 'trend': '+45%', 'category': 'Western Wear', 'stock': 34, 'color': 0xFF00BCD4},
  ];

  final List<Map<String, dynamic>> _weeklySales = [
    {'day': 'Mon', 'sales': 425000, 'orders': 245},
    {'day': 'Tue', 'sales': 487000, 'orders': 278},
    {'day': 'Wed', 'sales': 512000, 'orders': 298},
    {'day': 'Thu', 'sales': 598000, 'orders': 324},
    {'day': 'Fri', 'sales': 745000, 'orders': 412},
    {'day': 'Sat', 'sales': 892000, 'orders': 523},
    {'day': 'Sun', 'sales': 678000, 'orders': 389},
  ];

  final List<Map<String, dynamic>> _categorySales = [
    {'category': 'Wedding Wear', 'sales': 2450000, 'percentage': 28, 'color': 0xFFE91E63},
    {'category': 'Traditional', 'sales': 1850000, 'percentage': 21, 'color': 0xFF9C27B0},
    {'category': 'Casual Wear', 'sales': 2100000, 'percentage': 24, 'color': 0xFF4CAF50},
    {'category': 'Accessories', 'sales': 1250000, 'percentage': 14, 'color': 0xFFFF9800},
    {'category': 'Western Wear', 'sales': 1150000, 'percentage': 13, 'color': 0xFF2196F3},
  ];

  String _selectedFilter = 'This Week';
  final List<String> _filterOptions = ['Today', 'This Week', 'This Month', 'This Year'];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper function to format large numbers in compact form
  String formatCompactNumber(num number) {
    if (number >= 10000000) {
      return '₹${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '₹${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '₹${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${NumberFormat('#,##0').format(number)}';
    }
  }

  String formatCompactNumberWithoutSymbol(num number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return NumberFormat('#,##0').format(number);
    }
  }

  // Calculate total sales for the week
  num get _totalWeeklySales {
    return _weeklySales.fold<num>(0, (sum, item) => sum + (item['sales'] as num));
  }

  // Calculate max sales for chart scaling
  num get _maxWeeklySales {
    return _weeklySales.map((e) => e['sales'] as num).reduce((a, b) => a > b ? a : b);
  }

  // Calculate total products sold
  int get _totalProductsSold {
    return _topProducts.fold<int>(0, (sum, item) => sum + (item['sales'] as int));
  }

  // Calculate average rating
  double get _averageRating => 4.7;

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
     appBar: AppBar(
  systemOverlayStyle: SystemUiOverlayStyle.light,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: AppColors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    'Sales Analysis',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: AppColors.white,
    ),
  ),
  backgroundColor: AppColors.primaryColor,
  elevation: 0,
  toolbarHeight: 56, // Reduced height
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(45),
    child: TabBar(
      controller: _tabController,
      indicatorColor: AppColors.white,
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.white.withOpacity(0.7),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
      ),
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Products'),
      ],
    ),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications_outlined, size: 20),
      onPressed: () {},
      color: AppColors.white,
    ),
    IconButton(
      icon: const Icon(Icons.download_outlined, size: 20),
      onPressed: () {},
      color: AppColors.white,
    ),
  ],
),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildProductsTab(),
                  ],
                ),
              ),
      ),
     
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          _buildFilterChips(),
          const SizedBox(height: 12),

          // Key Metrics Cards - Horizontal Scroll for Mobile
          _buildHorizontalMetrics(),
          const SizedBox(height: 12),

          // Sales Chart
          _buildSalesChart(),
          const SizedBox(height: 12),

          // Category Distribution with Pie Chart
          _buildCategorySection(),
          const SizedBox(height: 12),

          // Recent Orders
          _buildRecentOrders(),
          const SizedBox(height: 12),

          // Additional Stats
          _buildAdditionalStats(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Products List
          _buildTopProductsFull(),
          const SizedBox(height: 12),
          
          // Stock Alerts
          _buildStockAlerts(),
          const SizedBox(height: 12),
          
          // Category Performance
          _buildCategoryPerformance(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == _filterOptions[index];
          return FilterChip(
            label: Text(_filterOptions[index]),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = _filterOptions[index];
              });
            },
            backgroundColor: AppColors.white,
            selectedColor: AppColors.primaryColor,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.white : AppColors.slate600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 11,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? AppColors.primaryColor : AppColors.slateBorder,
                width: 1,
              ),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalMetrics() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final metrics = [
            {
              'title': 'Revenue',
              'value': formatCompactNumber(_salesData['totalRevenue'] as num),
              'icon': Icons.currency_rupee,
              'color': AppColors.primaryColor,
              'trend': '+${_salesData['weeklyGrowth']}%',
            },
            {
              'title': 'Orders',
              'value': formatCompactNumberWithoutSymbol(_salesData['totalOrders'] as num),
              'icon': Icons.shopping_bag,
              'color': AppColors.primaryBlue,
              'trend': '+12.3%',
            },
            {
              'title': 'Avg Order',
              'value': '₹${NumberFormat('#,##0').format(_salesData['averageOrderValue'] as num)}',
              'icon': Icons.trending_up,
              'color': AppColors.accentColor,
              'trend': '+5.8%',
            },
            {
              'title': 'Profit',
              'value': '${_salesData['profitMargin']}%',
              'icon': Icons.percent,
              'color': AppColors.maroon,
              'trend': '+2.3%',
            },
          ];
          
          final metric = metrics[index];
          return Container(
            width: MediaQuery.of(context).size.width * 0.42,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (metric['color'] as Color).withOpacity(0.1),
                  (metric['color'] as Color).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (metric['color'] as Color).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (metric['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(metric['icon'] as IconData, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        metric['title'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        metric['value'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 10,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            metric['trend'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📈 Daily Sales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '↑ +${_salesData['weeklyGrowth']}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(_maxWeeklySales / 1000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 8)),
                    Text('${(_maxWeeklySales / 2000).toStringAsFixed(0)}K', style: const TextStyle(fontSize: 8)),
                    const Text('0', style: TextStyle(fontSize: 8)),
                  ],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _weeklySales.map((day) {
                      final sales = day['sales'] as num;
                      final height = (sales / _maxWeeklySales) * 110;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              height: height.toDouble(),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.primaryColor.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day['day'] as String,
                              style: TextStyle(fontSize: 9, color: AppColors.slate600),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.veryLightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${formatCompactNumber(_totalWeeklySales)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Orders: ${_weeklySales.fold<int>(0, (sum, item) => sum + (item['orders'] as int))}',
                  style: TextStyle(fontSize: 10, color: AppColors.slate600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '👗 Category Sales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Pie Chart Representation
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: PieChartPainter(_categorySales),
                    size: const Size(120, 120),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  children: _categorySales.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(category['color'] as int),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              category['category'] as String,
                              style: TextStyle(fontSize: 10, color: AppColors.slate600),
                            ),
                          ),
                          Text(
                            '${category['percentage']}%',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🛍️ Recent Orders',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('View All', style: TextStyle(fontSize: 10, color: AppColors.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => Divider(color: AppColors.slateBorder, height: 1),
            itemBuilder: (context, index) {
              final order = _recentOrders[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColors.softPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.shopping_bag, size: 18, color: AppColors.primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['id'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text(order['customer'], style: TextStyle(fontSize: 9, color: AppColors.slate600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatCompactNumber(order['amount'] as num), 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(order['status'], 
                              style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.w600)),
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

  Widget _buildAdditionalStats() {
    final totalRevenue = _salesData['totalRevenue'] as num;
    final targetRevenue = _salesData['targetRevenue'] as num;
    final progressTowardsTarget = (totalRevenue / targetRevenue * 100);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Target', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
              Text('${progressTowardsTarget.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: AppColors.white)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progressTowardsTarget / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            color: Colors.white,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatCompactNumberWithoutSymbol(totalRevenue)} / ${formatCompactNumberWithoutSymbol(targetRevenue)}',
            style: TextStyle(fontSize: 10, color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsFull() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 Top Selling Products', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topProducts.length,
            separatorBuilder: (context, index) => Divider(color: AppColors.slateBorder),
            itemBuilder: (context, index) {
              final product = _topProducts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(product['color'] as int).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('${index + 1}', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(product['color'] as int))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'], 
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${product['sales']} units • ${product['category']}', 
                              style: TextStyle(fontSize: 10, color: AppColors.slate600)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatCompactNumber(product['revenue'] as num), 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(product['trend'], 
                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
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

  Widget _buildStockAlerts() {
    final lowStock = _topProducts.where((p) => p['stock'] < 50).toList();
    if (lowStock.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text('Low Stock Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          ...lowStock.map((product) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product['name'], style: TextStyle(fontSize: 11)),
                  Text('Only ${product['stock']} left', 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBrown,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Category Performance', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          const SizedBox(height: 12),
          ..._categorySales.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(category['color'] as int),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(category['category'], 
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      Text('${category['percentage']}%', 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (category['percentage'] as int) / 100,
                    backgroundColor: AppColors.veryLightGray,
                    color: Color(category['color'] as int),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  
  PieChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (sum, item) => sum + (item['sales'] as num).toDouble());
    double startAngle = -90 * (3.14159 / 180);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    for (var item in data) {
      final angle = (item['sales'] as num).toDouble() / total * 360 * (3.14159 / 180);
      final paint = Paint()
        ..color = Color(item['color'] as int)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        angle,
        true,
        paint,
      );
      startAngle += angle;
    }
    
    // Draw inner circle for donut effect
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, innerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}