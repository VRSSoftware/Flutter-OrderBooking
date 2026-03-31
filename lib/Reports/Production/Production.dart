import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class GarmentProductionAnalysis extends StatefulWidget {
  const GarmentProductionAnalysis({super.key});

  @override
  State<GarmentProductionAnalysis> createState() => _GarmentProductionAnalysisState();
}

class _GarmentProductionAnalysisState extends State<GarmentProductionAnalysis>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedPeriod = 0; // 0: Weekly, 1: Monthly

  // Static production data for garment industry
  final List<Map<String, dynamic>> weeklyData = [
    {'day': 'Mon', 'target': 1250, 'actual': 1180, 'defect': 45, 'efficiency': 94.4, 'style': 'T-Shirt', 'line': 'Line A'},
    {'day': 'Tue', 'target': 1250, 'actual': 1240, 'defect': 28, 'efficiency': 99.2, 'style': 'T-Shirt', 'line': 'Line A'},
    {'day': 'Wed', 'target': 1250, 'actual': 1280, 'defect': 12, 'efficiency': 102.4, 'style': 'Polo', 'line': 'Line B'},
    {'day': 'Thu', 'target': 1250, 'actual': 1210, 'defect': 35, 'efficiency': 96.8, 'style': 'Polo', 'line': 'Line B'},
    {'day': 'Fri', 'target': 1250, 'actual': 1310, 'defect': 18, 'efficiency': 104.8, 'style': 'Jeans', 'line': 'Line C'},
    {'day': 'Sat', 'target': 1250, 'actual': 1220, 'defect': 42, 'efficiency': 97.6, 'style': 'Jeans', 'line': 'Line C'},
    {'day': 'Sun', 'target': 1000, 'actual': 950, 'defect': 25, 'efficiency': 95.0, 'style': 'Jacket', 'line': 'Line D'},
  ];

  final List<Map<String, dynamic>> monthlyData = [
    {'month': 'Jan', 'production': 28500, 'target': 30000, 'defect': 850, 'efficiency': 95.0},
    {'month': 'Feb', 'production': 29200, 'target': 30000, 'defect': 720, 'efficiency': 97.3},
    {'month': 'Mar', 'production': 30500, 'target': 31000, 'defect': 680, 'efficiency': 98.4},
    {'month': 'Apr', 'production': 29800, 'target': 31000, 'defect': 790, 'efficiency': 96.1},
    {'month': 'May', 'production': 31500, 'target': 31000, 'defect': 650, 'efficiency': 101.6},
    {'month': 'Jun', 'production': 32300, 'target': 32000, 'defect': 710, 'efficiency': 100.9},
  ];

  final List<Map<String, dynamic>> garmentStyles = [
    {'style': 'T-Shirt', 'target': 5000, 'actual': 4850, 'defect': 85, 'efficiency': 97.0, 'color': Colors.blue},
    {'style': 'Polo', 'target': 4500, 'actual': 4620, 'defect': 62, 'efficiency': 102.7, 'color': Colors.green},
    {'style': 'Jeans', 'target': 3800, 'actual': 3750, 'defect': 110, 'efficiency': 98.7, 'color': Colors.orange},
    {'style': 'Jacket', 'target': 2500, 'actual': 2420, 'defect': 45, 'efficiency': 96.8, 'color': Colors.purple},
    {'style': 'Dress', 'target': 3200, 'actual': 3350, 'defect': 58, 'efficiency': 104.7, 'color': Colors.pink},
  ];

  final List<Map<String, dynamic>> productionLines = [
    {'line': 'Line A', 'status': 'Running', 'output': 2420, 'efficiency': 96.8, 'style': 'T-Shirt', 'operators': 25},
    {'line': 'Line B', 'status': 'Running', 'output': 2490, 'efficiency': 99.6, 'style': 'Polo', 'operators': 24},
    {'line': 'Line C', 'status': 'Running', 'output': 2530, 'efficiency': 101.2, 'style': 'Jeans', 'operators': 26},
    {'line': 'Line D', 'status': 'Idle', 'output': 0, 'efficiency': 0, 'style': 'Maintenance', 'operators': 0},
    {'line': 'Line E', 'status': 'Running', 'output': 1950, 'efficiency': 97.5, 'style': 'Dress', 'operators': 22},
  ];

  final List<Map<String, dynamic>> qualityMetrics = [
    {'metric': 'Defect Rate', 'value': 2.4, 'target': 2.5, 'unit': '%', 'status': 'Good', 'icon': Icons.warning_amber_rounded},
    {'metric': 'First Pass Yield', 'value': 96.8, 'target': 95.0, 'unit': '%', 'status': 'Excellent', 'icon': Icons.verified},
    {'metric': 'OEE', 'value': 87.5, 'target': 85.0, 'unit': '%', 'status': 'Excellent', 'icon': Icons.speed},
    {'metric': 'Operator Efficiency', 'value': 92.3, 'target': 90.0, 'unit': '%', 'status': 'Good', 'icon': Icons.people},
    {'metric': 'Downtime', 'value': 3.2, 'target': 4.0, 'unit': 'hrs', 'status': 'Good', 'icon': Icons.timer},
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.veryLightGray,
      appBar: AppBar(
        title: Text(
          'Garment Production Analysis',
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
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
          tabs: const [
            Tab(text: 'Production Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Analytics & Insights', icon: Icon(Icons.analytics)),
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
                selectedPeriod = value == 'Weekly' ? 0 : 1;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Weekly', child: Text('Weekly View')),
              const PopupMenuItem(value: 'Monthly', child: Text('Monthly View')),
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
          _buildProductionOverviewTab(),
          _buildAnalyticsInsightsTab(),
        ],
      ),
    );
  }

  // ==================== TAB 1: PRODUCTION OVERVIEW ====================
  Widget _buildProductionOverviewTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildKeyMetricsCards(),
              const SizedBox(height: 20),
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              _buildProductionChart(),
              const SizedBox(height: 20),
              _buildMultiLineChart(),
              const SizedBox(height: 20),
              _buildProductionLinesStatus(),
              const SizedBox(height: 20),
              _buildProductionHeatmap(),
              const SizedBox(height: 20),
              _buildStyleDonutChart(),
              const SizedBox(height: 20),
              _buildDailyProductionSummary(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== TAB 2: ANALYTICS & INSIGHTS ====================
  Widget _buildAnalyticsInsightsTab() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildEfficiencyAreaChart(),
              const SizedBox(height: 20),
              _buildQualityGaugeChart(),
              const SizedBox(height: 20),
              _buildDefectAnalysisChart(),
              const SizedBox(height: 20),
              _buildStylePerformanceChart(),
              const SizedBox(height: 20),
              _buildComparisonRadarChart(),
              const SizedBox(height: 20),
              _buildForecastingChart(),
              const SizedBox(height: 20),
              _buildKeyInsights(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  // ==================== COMMON WIDGETS ====================
  Widget _buildKeyMetricsCards() {
    int totalTarget = weeklyData.fold(0, (sum, item) => sum + (item['target'] as int));
    int totalActual = weeklyData.fold(0, (sum, item) => sum + (item['actual'] as int));
    int totalDefect = weeklyData.fold(0, (sum, item) => sum + (item['defect'] as int));
    double avgEfficiency = weeklyData.fold(0.0, (sum, item) => sum + (item['efficiency'] as double)) / weeklyData.length;
    double defectRate = (totalDefect / totalActual * 100);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          title: 'Total Production',
          value: NumberFormat('#,###').format(totalActual),
          subtitle: 'Garments',
          icon: FontAwesomeIcons.shirt,
          color: AppColors.primaryColor,
          change: '${((totalActual - totalTarget) / totalTarget * 100).toStringAsFixed(1)}% vs target',
        ),
        _buildMetricCard(
          title: 'Target Achievement',
          value: '${((totalActual / totalTarget) * 100).toStringAsFixed(1)}%',
          subtitle: 'of target',
          icon: FontAwesomeIcons.chartLine,
          color: AppColors.accentColor,
          change: '${(totalActual - totalTarget).toStringAsFixed(0)} units',
        ),
        _buildMetricCard(
          title: 'Avg Efficiency',
          value: avgEfficiency.toStringAsFixed(1),
          subtitle: '%',
          icon: FontAwesomeIcons.gaugeHigh,
          color: AppColors.orange,
          change: '${(avgEfficiency - 100).toStringAsFixed(1)}% vs target',
        ),
        _buildMetricCard(
          title: 'Defect Rate',
          value: defectRate.toStringAsFixed(1),
          subtitle: '%',
          icon: FontAwesomeIcons.triangleExclamation,
          color: AppColors.maroon,
          change: defectRate <= 2.5 ? 'Below target' : 'Above target',
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
              color: change.contains('above') ? AppColors.maroon : AppColors.accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Weekly', 0),
          ),
          Expanded(
            child: _buildPeriodButton('Monthly', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String text, int index) {
    bool isSelected = selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPeriod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: isSelected ? AppColors.white : AppColors.slate600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductionChart() {
    final data = selectedPeriod == 0 ? weeklyData : monthlyData;
    final isWeekly = selectedPeriod == 0;
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Production Overview',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Actual', style: GoogleFonts.poppins(fontSize: 10)),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.slateBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Target', style: GoogleFonts.poppins(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: isWeekly ? 1400 : 35000,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          isWeekly ? value.toInt().toString() : (value.toInt() / 1000).toString() + 'k',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.length) {
                          return Text(
                            isWeekly ? data[value.toInt()]['day'] : data[value.toInt()]['month'],
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
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: isWeekly 
                            ? data[index]['actual'].toDouble() 
                            : data[index]['production'].toDouble(),
                        color: AppColors.primaryColor,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: isWeekly 
                            ? data[index]['target'].toDouble() 
                            : data[index]['target'].toDouble(),
                        color: AppColors.slateBorder,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: isWeekly ? 200 : 5000,
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
        ],
      ),
    );
  }

  Widget _buildMultiLineChart() {
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
            'Production vs Efficiency Trend',
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
                        if (value > 1000) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        }
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
                        if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                          return Text(
                            weeklyData[value.toInt()]['day'],
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 1400,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(weeklyData.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        weeklyData[index]['actual'].toDouble(),
                      );
                    }),
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

  Widget _buildProductionLinesStatus() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Production Lines Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${productionLines.where((l) => l['status'] == 'Running').length} Active',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...productionLines.map((line) {
            Color statusColor = line['status'] == 'Running' 
                ? AppColors.accentColor 
                : line['status'] == 'Idle' 
                    ? Colors.orange 
                    : AppColors.maroon;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      line['status'] == 'Running'
                          ? FontAwesomeIcons.play
                          : line['status'] == 'Idle'
                              ? FontAwesomeIcons.pause
                              : FontAwesomeIcons.screwdriverWrench,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              line['line'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                line['status'],
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Style: ${line['style']} | Operators: ${line['operators']}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (line['status'] == 'Running') ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(line['output'])}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${line['efficiency']}% eff.',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: line['efficiency'] >= 100 ? AppColors.accentColor : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductionHeatmap() {
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
            'Production Efficiency Heatmap',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                double efficiency = 90 + (index % 15);
                Color color = _getHeatmapColor(efficiency);
                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${efficiency.toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: efficiency > 95 ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeatmapLegend('Low', Colors.red),
              _buildHeatmapLegend('Medium', Colors.orange),
              _buildHeatmapLegend('Good', Colors.green),
              _buildHeatmapLegend('Excellent', AppColors.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHeatmapColor(double efficiency) {
    if (efficiency >= 100) return AppColors.primaryColor;
    if (efficiency >= 95) return Colors.green;
    if (efficiency >= 90) return Colors.lightGreen;
    if (efficiency >= 85) return Colors.orange;
    return Colors.red;
  }

  Widget _buildHeatmapLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
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

  Widget _buildStyleDonutChart() {
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
            'Production by Garment Style',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: garmentStyles.map((style) {
                  return PieChartSectionData(
                    value: style['actual'].toDouble(),
                    title: '${style['style']}\n${((style['actual'] / garmentStyles.fold(0, (sum, s) => sum + (s['actual'] as int)) * 100).toStringAsFixed(1))}%',
                    radius: 80,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    color: style['color'],
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
            children: garmentStyles.map((style) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: style['color'],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    style['style'],
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProductionSummary() {
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
            'Daily Production Summary',
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
                DataColumn(label: Text('Day')),
                DataColumn(label: Text('Style')),
                DataColumn(label: Text('Line')),
                DataColumn(label: Text('Target'), numeric: true),
                DataColumn(label: Text('Actual'), numeric: true),
                DataColumn(label: Text('Defect'), numeric: true),
                DataColumn(label: Text('Efficiency'), numeric: true),
              ],
              rows: weeklyData.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['day'], style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(data['style'], style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(data['line'], style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(data['target']), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(NumberFormat('#,###').format(data['actual']), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(Text(data['defect'].toString(), style: GoogleFonts.poppins(fontSize: 12))),
                    DataCell(
                      Text(
                        '${data['efficiency']}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: data['efficiency'] >= 100 ? AppColors.accentColor : Colors.orange,
                          fontWeight: FontWeight.w500,
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

  // ==================== TAB 2 WIDGETS ====================
  Widget _buildEfficiencyAreaChart() {
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
            'Efficiency Trend Analysis',
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
                          '${value.toInt()}%',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                          return Text(
                            weeklyData[value.toInt()]['day'],
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
                minY: 90,
                maxY: 110,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(weeklyData.length, (index) {
                      return FlSpot(
                        index.toDouble(),
                        weeklyData[index]['efficiency'],
                      );
                    }),
                    isCurved: true,
                    color: AppColors.primaryColor,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryColor.withOpacity(0.2),
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

Widget _buildQualityGaugeChart() {
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
          'Quality Metrics Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        // Horizontal scrollable cards
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: qualityMetrics.length,
            itemBuilder: (context, index) {
              final metric = qualityMetrics[index];
              double value = metric['value'];
              double target = metric['target'];
              double percentage = (value / target) * 100;
              
              return Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.veryLightGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: percentage >= 100 ? AppColors.accentColor : AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(metric['icon'], color: AppColors.primaryColor, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      metric['metric'],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 5,
                            backgroundColor: AppColors.lightGray,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentage >= 100 ? AppColors.accentColor : AppColors.primaryColor,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              metric['value'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              metric['unit'],
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Target: ${metric['target']}${metric['unit']}',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: AppColors.slate600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
  Widget _buildDefectAnalysisChart() {
    final defectData = garmentStyles.map((style) {
      return {
        'style': style['style'],
        'defects': style['defect'],
        'color': style['color'],
      };
    }).toList();

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
            'Defect Analysis by Style',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: defectData.map((defect) {
                  return PieChartSectionData(
                    value: defect['defects'].toDouble(),
                    title: '${defect['style']}\n${defect['defects']}',
                    radius: 80,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    color: defect['color'],
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePerformanceChart() {
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
            'Style Performance Comparison',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 120,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < garmentStyles.length) {
                          return Text(
                            garmentStyles[value.toInt()]['style'],
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
                borderData: FlBorderData(show: false),
                barGroups: List.generate(garmentStyles.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: garmentStyles[index]['efficiency'].toDouble(),
                        color: garmentStyles[index]['color'],
                        width: 30,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
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
        ],
      ),
    );
  }

  Widget _buildComparisonRadarChart() {
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
            'Performance Metrics Comparison',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Quality', 'Efficiency', 'Productivity', 'OEE', 'Defect Control'];
                        if (value.toInt() >= 0 && value.toInt() < titles.length) {
                          return Text(
                            titles[value.toInt()],
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
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 94,
                        color: AppColors.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 88,
                        color: AppColors.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 92,
                        color: AppColors.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: 85,
                        color: AppColors.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 4,
                    barRods: [
                      BarChartRodData(
                        toY: 96,
                        color: AppColors.primaryColor,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
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
              'Performance Score (0-100)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForecastingChart() {
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
            'Production Forecast (Next 6 Months)',
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
                        const months = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
                minY: 30000,
                maxY: 38000,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 32500),
                      FlSpot(1, 33500),
                      FlSpot(2, 34500),
                      FlSpot(3, 35500),
                      FlSpot(4, 36500),
                      FlSpot(5, 37500),
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

  Widget _buildKeyInsights() {
    int totalActual = weeklyData.fold(0, (sum, item) => sum + (item['actual'] as int));
    int totalDefect = weeklyData.fold(0, (sum, item) => sum + (item['defect'] as int));
    double avgEfficiency = weeklyData.fold(0.0, (sum, item) => sum + (item['efficiency'] as double)) / weeklyData.length;
    
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
                'Key Business Insights',
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
            '📊 Production Achievement',
            '${((totalActual / 8500) * 100).toStringAsFixed(1)}% of weekly target achieved',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '✅ Quality Performance',
            'Defect rate at ${((totalDefect / totalActual) * 100).toStringAsFixed(1)}% - ${((totalDefect / totalActual) * 100) <= 2.5 ? "Excellent" : "Needs improvement"}',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '⚡ Efficiency Status',
            'Average efficiency ${avgEfficiency.toStringAsFixed(1)}% - ${avgEfficiency >= 95 ? "Exceeding target" : "Below target"}',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '🏆 Top Performer',
            'Line C with ${productionLines[2]['efficiency']}% efficiency and 0 defects',
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            '📈 Growth Forecast',
            'Projected 15% growth in next quarter with current efficiency trends',
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
          'Export production analysis report as PDF?',
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
                    'Production report exported successfully!',
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