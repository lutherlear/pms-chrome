import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import '../../database/app_database.dart';
import '../../services/auth_service.dart';
import '../../widgets/sidebar_navigation.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String selectedRoute = '/reports';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    // Set tab count based on user role (Admin gets all 5 tabs, others get 4)
    final authService = context.read<AuthService>();
    final tabCount = authService.isAdmin ? 5 : 4;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    final authService = context.watch<AuthService>();
    final db = context.read<AppDatabase>();

    // Check permissions
    if (!authService.hasPermission('view_reports')) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.lockKey, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              const Text('Access Denied', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('You do not have permission to view reports'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Row(
        children: [
          if (isDesktop)
            SidebarNavigation(
              selectedRoute: selectedRoute,
              onRouteSelected: (route) {
                if (route != selectedRoute) {
                  Navigator.pushReplacementNamed(context, route);
                }
              },
            ),

          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.list),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      Text(
                        'Reports & Analytics',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      
                      // Date Range Selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.offWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.calendar, size: 20, color: AppTheme.gray),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: Icon(PhosphorIconsRegular.caretDown, size: 16),
                              onSelected: _selectDateRange,
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'Today', child: Text('Today')),
                                const PopupMenuItem(value: 'This Week', child: Text('This Week')),
                                const PopupMenuItem(value: 'This Month', child: Text('This Month')),
                                const PopupMenuItem(value: 'Last Month', child: Text('Last Month')),
                                const PopupMenuItem(value: 'This Year', child: Text('This Year')),
                                const PopupMenuItem(value: 'Custom', child: Text('Custom Range')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  color: AppTheme.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryGreen,
                    unselectedLabelColor: AppTheme.gray,
                    indicatorColor: AppTheme.primaryGreen,
                    isScrollable: isDesktop,
                    tabs: [
                      const Tab(text: 'Sales Overview', icon: Icon(PhosphorIconsRegular.chartBar)),
                      if (authService.isAdmin)
                        const Tab(text: 'Profit & Loss', icon: Icon(PhosphorIconsRegular.currencyCircleDollar)),
                      const Tab(text: 'Stock Analysis', icon: Icon(PhosphorIconsRegular.package)),
                      const Tab(text: 'Best Sellers', icon: Icon(PhosphorIconsRegular.trophy)),
                      const Tab(text: 'Activity Logs', icon: Icon(PhosphorIconsRegular.clockCounterClockwise)),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesOverview(db),
                      if (authService.isAdmin)
                        _buildProfitLoss(db),
                      _buildStockAnalysis(db),
                      _buildBestSellers(db),
                      _buildActivityLogs(db),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: !isDesktop
          ? Drawer(
              child: SidebarNavigation(
                selectedRoute: selectedRoute,
                onRouteSelected: (route) {
                  Navigator.pop(context);
                  if (route != selectedRoute) {
                    Navigator.pushReplacementNamed(context, route);
                  }
                },
              ),
            )
          : null,
    );
  }

  Widget _buildSalesOverview(AppDatabase db) {
    return StreamBuilder<List<Sale>>(
      stream: _getSalesStream(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sales = snapshot.data!;
        final totalSales = sales.fold<double>(0, (sum, sale) => sum + sale.finalAmount);
        final totalTransactions = sales.length;
        final averageTransaction = totalTransactions > 0 ? totalSales / totalTransactions : 0;

        // Group sales by date for chart
        final salesByDate = <DateTime, double>{};
        for (var sale in sales) {
          final date = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
          salesByDate[date] = (salesByDate[date] ?? 0) + sale.finalAmount;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Sales',
                      '${AppConfig.currencySymbol}${NumberFormat('#,###').format(totalSales)}',
                      PhosphorIconsBold.money,
                      AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Transactions',
                      totalTransactions.toString(),
                      PhosphorIconsBold.receipt,
                      AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Average Sale',
                      '${AppConfig.currencySymbol}${NumberFormat('#,###').format(averageTransaction)}',
                      PhosphorIconsBold.chartLine,
                      AppTheme.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sales Chart
              Container(
                height: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                        Text('Sales Trend', style: Theme.of(context).textTheme.titleLarge),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.filePdf, color: AppTheme.error),
                              onPressed: () => _exportPDF('Sales Report', sales),
                              tooltip: 'Export PDF',
                            ),
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.fileXls, color: AppTheme.success),
                              onPressed: () => _exportExcel('Sales Report', sales),
                              tooltip: 'Export Excel',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${(value / 1000).toStringAsFixed(0)}k',
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                  return Text(
                                    DateFormat('dd/MM').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: salesByDate.entries.map((entry) {
                                return FlSpot(
                                  entry.key.millisecondsSinceEpoch.toDouble(),
                                  entry.value,
                                );
                              }).toList()..sort((a, b) => a.x.compareTo(b.x)),
                              isCurved: true,
                              color: AppTheme.primaryGreen,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Transactions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Receipt #')),
                          DataColumn(label: Text('Date & Time')),
                          DataColumn(label: Text('Customer')),
                          DataColumn(label: Text('Payment')),
                          DataColumn(label: Text('Amount')),
                        ],
                        rows: sales.take(10).map((sale) {
                          return DataRow(cells: [
                            DataCell(Text(sale.receiptNumber)),
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate))),
                            DataCell(Text(sale.customerName ?? 'Walk-in')),
                            DataCell(Text(sale.paymentMethod)),
                            DataCell(Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(sale.finalAmount)}')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfitLoss(AppDatabase db) {
    return StreamBuilder<List<Sale>>(
      stream: _getSalesStream(db),
      builder: (context, salesSnapshot) {
        if (!salesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<SaleItem>>(
          stream: db.select(db.saleItems).watch(),
          builder: (context, itemsSnapshot) {
            if (!itemsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Calculate profit/loss
            double totalRevenue = 0;
            double totalCost = 0;
            final saleItems = itemsSnapshot.data!;
            
            // For each sale item, we need to get the buying price
            return FutureBuilder<Map<String, double>>(
              future: _calculateProfitData(db, saleItems),
              builder: (context, profitSnapshot) {
                if (!profitSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final profitData = profitSnapshot.data!;
                totalRevenue = profitData['revenue'] ?? 0;
                totalCost = profitData['cost'] ?? 0;
                final totalProfit = totalRevenue - totalCost;
                final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profit Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Revenue',
                              '${AppConfig.currencySymbol}${NumberFormat('#,###').format(totalRevenue)}',
                              PhosphorIconsBold.trendUp,
                              AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Cost',
                              '${AppConfig.currencySymbol}${NumberFormat('#,###').format(totalCost)}',
                              PhosphorIconsBold.trendDown,
                              AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Net Profit',
                              '${AppConfig.currencySymbol}${NumberFormat('#,###').format(totalProfit)}',
                              PhosphorIconsBold.currencyCircleDollar,
                              totalProfit >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Profit Margin',
                              '${profitMargin.toStringAsFixed(1)}%',
                              PhosphorIconsBold.percent,
                              AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Profit Chart
                      Container(
                        height: 400,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                Text('Profit & Loss Analysis', style: Theme.of(context).textTheme.titleLarge),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(PhosphorIconsRegular.filePdf, color: AppTheme.error),
                                      onPressed: () => _exportProfitLossPDF(totalRevenue, totalCost, totalProfit, profitMargin.toDouble()),
                                      tooltip: 'Export PDF',
                                    ),
                                    IconButton(
                                      icon: Icon(PhosphorIconsRegular.fileXls, color: AppTheme.success),
                                      onPressed: () => _exportProfitLossExcel(totalRevenue, totalCost, totalProfit, profitMargin.toDouble()),
                                      tooltip: 'Export Excel',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups: [
                                    BarChartGroupData(
                                      x: 0,
                                      barRods: [
                                        BarChartRodData(
                                          toY: totalRevenue,
                                          color: AppTheme.success,
                                          width: 60,
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 1,
                                      barRods: [
                                        BarChartRodData(
                                          toY: totalCost,
                                          color: AppTheme.warning,
                                          width: 60,
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 2,
                                      barRods: [
                                        BarChartRodData(
                                          toY: totalProfit.abs(),
                                          color: totalProfit >= 0 ? AppTheme.primaryGreen : AppTheme.error,
                                          width: 60,
                                        ),
                                      ],
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          switch (value.toInt()) {
                                            case 0:
                                              return const Text('Revenue');
                                            case 1:
                                              return const Text('Cost');
                                            case 2:
                                              return const Text('Profit');
                                            default:
                                              return const Text('');
                                          }
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text('${(value / 1000).toStringAsFixed(0)}k');
                                        },
                                        reservedSize: 40,
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(show: true, drawVerticalLine: false),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStockAnalysis(AppDatabase db) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Stock Status Cards
          StreamBuilder<List<Drug>>(
            stream: db.watchAllDrugs(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final drugs = snapshot.data!;
              final totalItems = drugs.length;
              final totalValue = drugs.fold<double>(0, (sum, drug) => sum + (drug.quantity * drug.sellingPrice));
              final lowStockCount = drugs.where((d) => d.quantity <= d.reorderLevel).length;
              final expiringCount = drugs.where((d) {
                final daysToExpiry = d.expiryDate.difference(DateTime.now()).inDays;
                return daysToExpiry <= AppConfig.expiryWarningDays;
              }).length;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Items',
                          totalItems.toString(),
                          PhosphorIconsBold.package,
                          AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Stock Value',
                          '${AppConfig.currencySymbol}${NumberFormat('#,###').format(totalValue)}',
                          PhosphorIconsBold.currencyCircleDollar,
                          AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Low Stock',
                          lowStockCount.toString(),
                          PhosphorIconsBold.warning,
                          AppTheme.warning,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Expiring Soon',
                          expiringCount.toString(),
                          PhosphorIconsBold.clock,
                          AppTheme.error,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stock Categories Distribution
                  StreamBuilder<List<DrugCategory>>(
                    stream: db.watchAllCategories(),
                    builder: (context, catSnapshot) {
                      if (!catSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final categories = catSnapshot.data!;
                      
                      return Container(
                        height: 400,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stock by Category', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 20),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sections: categories.map((category) {
                                    final categoryDrugs = drugs.where((d) => d.categoryId == category.id).toList();
                                    final percentage = totalItems > 0 ? (categoryDrugs.length / totalItems * 100) : 0;
                                    
                                    return PieChartSectionData(
                                      color: _getCategoryColor(categories.indexOf(category)),
                                      value: categoryDrugs.length.toDouble(),
                                      title: '${percentage.toStringAsFixed(1)}%',
                                      radius: 100,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Legend
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: categories.map((category) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(categories.indexOf(category)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(category.name, style: const TextStyle(fontSize: 12)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Critical Stock Items
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                            Text('Critical Stock Items', style: Theme.of(context).textTheme.titleLarge),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(PhosphorIconsRegular.filePdf, color: AppTheme.error),
                                  onPressed: () => _exportStockReportPDF(drugs),
                                  tooltip: 'Export PDF',
                                ),
                                IconButton(
                                  icon: Icon(PhosphorIconsRegular.fileXls, color: AppTheme.success),
                                  onPressed: () => _exportStockReportExcel(drugs),
                                  tooltip: 'Export Excel',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Drug Name')),
                              DataColumn(label: Text('Batch No.')),
                              DataColumn(label: Text('Current Stock')),
                              DataColumn(label: Text('Reorder Level')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: drugs
                                .where((d) => d.quantity <= d.reorderLevel)
                                .take(10)
                                .map((drug) {
                              return DataRow(cells: [
                                DataCell(Text(drug.name)),
                                DataCell(Text(drug.batchNumber)),
                                DataCell(Text(drug.quantity.toString())),
                                DataCell(Text(drug.reorderLevel.toString())),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: drug.quantity == 0 ? AppTheme.error.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      drug.quantity == 0 ? 'Out of Stock' : 'Low Stock',
                                      style: TextStyle(
                                        color: drug.quantity == 0 ? AppTheme.error : AppTheme.warning,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellers(AppDatabase db) {
    return StreamBuilder<List<SaleItem>>(
      stream: db.select(db.saleItems).watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Group by drug and calculate totals
        final drugSales = <String, Map<String, dynamic>>{};
        for (var item in snapshot.data!) {
          if (drugSales.containsKey(item.drugName)) {
            drugSales[item.drugName]!['quantity'] += item.quantity;
            drugSales[item.drugName]!['revenue'] += item.totalPrice;
          } else {
            drugSales[item.drugName] = {
              'quantity': item.quantity,
              'revenue': item.totalPrice,
            };
          }
        }

        // Sort by revenue
        final sortedDrugs = drugSales.entries.toList()
          ..sort((a, b) => b.value['revenue'].compareTo(a.value['revenue']));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Top Performers Cards
              if (sortedDrugs.isNotEmpty)
                Row(
                  children: [
                    if (sortedDrugs.isNotEmpty)
                      Expanded(
                        child: _buildTopPerformerCard(
                          '🥇 Top Seller',
                          sortedDrugs[0].key,
                          '${AppConfig.currencySymbol}${NumberFormat('#,###').format(sortedDrugs[0].value['revenue'])}',
                          AppTheme.warning,
                        ),
                      ),
                    if (sortedDrugs.length > 1) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTopPerformerCard(
                          '🥈 Runner Up',
                          sortedDrugs[1].key,
                          '${AppConfig.currencySymbol}${NumberFormat('#,###').format(sortedDrugs[1].value['revenue'])}',
                          AppTheme.gray,
                        ),
                      ),
                    ],
                    if (sortedDrugs.length > 2) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTopPerformerCard(
                          '🥉 Third Place',
                          sortedDrugs[2].key,
                          '${AppConfig.currencySymbol}${NumberFormat('#,###').format(sortedDrugs[2].value['revenue'])}',
                          Color(0xFFCD7F32),
                        ),
                      ),
                    ],
                  ],
                ),

              const SizedBox(height: 24),

              // Best Sellers Table
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                        Text('Best Selling Drugs', style: Theme.of(context).textTheme.titleLarge),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.filePdf, color: AppTheme.error),
                              onPressed: () => _exportBestSellersPDF(sortedDrugs),
                              tooltip: 'Export PDF',
                            ),
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.fileXls, color: AppTheme.success),
                              onPressed: () => _exportBestSellersExcel(sortedDrugs),
                              tooltip: 'Export Excel',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Rank')),
                          DataColumn(label: Text('Drug Name')),
                          DataColumn(label: Text('Units Sold')),
                          DataColumn(label: Text('Revenue')),
                          DataColumn(label: Text('% of Total')),
                        ],
                        rows: sortedDrugs.take(20).toList().asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final drug = entry.value;
                          final totalRevenue = sortedDrugs.fold<double>(
                            0, (sum, item) => sum + item.value['revenue']);
                          final percentage = totalRevenue > 0 ? 
                            (drug.value['revenue'] / totalRevenue * 100) : 0;

                          return DataRow(cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: rank <= 3 ? AppTheme.warning.withOpacity(0.1) : null,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  rank.toString(),
                                  style: TextStyle(
                                    fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                                    color: rank <= 3 ? AppTheme.warning : AppTheme.black,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(drug.key)),
                            DataCell(Text(drug.value['quantity'].toString())),
                            DataCell(Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(drug.value['revenue'])}')),
                            DataCell(Text('${percentage.toStringAsFixed(1)}%')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityLogs(AppDatabase db) {
    final authService = context.read<AuthService>();
    
    // Only show activity logs to admin
    if (!authService.isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIconsRegular.lockKey, size: 64, color: AppTheme.gray.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Activity Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.gray),
            ),
            const SizedBox(height: 8),
            Text(
              'This section is restricted to administrators only',
              style: TextStyle(color: AppTheme.gray),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ActivityLog>>(
      stream: db.watchActivityLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Activity Logs', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Module')),
                      DataColumn(label: Text('Details')),
                    ],
                    rows: logs.take(50).map((log) {
                      return DataRow(cells: [
                        DataCell(Text(DateFormat('dd/MM HH:mm').format(log.timestamp))),
                        DataCell(
                          FutureBuilder<User?>(
                            future: (db.select(db.users)..where((u) => u.id.equals(log.userId)))
                              .getSingleOrNull(),
                            builder: (context, userSnapshot) {
                              return Text(userSnapshot.data?.username ?? 'Unknown');
                            },
                          ),
                        ),
                        DataCell(Text(log.action)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getModuleColor(log.module).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log.module,
                              style: TextStyle(
                                color: _getModuleColor(log.module),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(log.details ?? '-')),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.gray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformerCard(String rank, String name, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rank, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateRange(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'This Week':
          _startDate = now.subtract(Duration(days: now.weekday - 1));
          _endDate = now;
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case 'Last Month':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
          break;
        case 'Custom':
          _showDateRangePicker();
          break;
      }
    });
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Stream<List<Sale>> _getSalesStream(AppDatabase db) {
    return (db.select(db.sales)
      ..where((s) => s.saleDate.isBetween(
        Variable<DateTime>(_startDate), 
        Variable<DateTime>(_endDate)
      ) & s.isCancelled.equals(false)))
      .watch();
  }

  Future<Map<String, double>> _calculateProfitData(AppDatabase db, List<SaleItem> saleItems) async {
    double totalRevenue = 0;
    double totalCost = 0;

    for (var item in saleItems) {
      totalRevenue += item.totalPrice;
      
      // Get the drug to find buying price
      final drug = await db.getDrugById(item.drugId);
      if (drug != null) {
        totalCost += drug.buyingPrice * item.quantity;
      }
    }

    return {
      'revenue': totalRevenue,
      'cost': totalCost,
    };
  }

  Color _getCategoryColor(int index) {
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.primaryBlue,
      AppTheme.warning,
      AppTheme.error,
      AppTheme.info,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Color _getModuleColor(String module) {
    switch (module) {
      case 'Sales':
        return AppTheme.success;
      case 'Inventory':
        return AppTheme.primaryBlue;
      case 'Authentication':
        return AppTheme.warning;
      case 'Users':
        return AppTheme.info;
      default:
        return AppTheme.gray;
    }
  }

  Future<void> _exportPDF(String title, List<Sale> sales) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(text: 'Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Receipt #', 'Date', 'Customer', 'Payment', 'Amount'],
            data: sales.map((sale) => [
              sale.receiptNumber,
              DateFormat('dd/MM/yyyy').format(sale.saleDate),
              sale.customerName ?? 'Walk-in',
              sale.paymentMethod,
              '${AppConfig.currencySymbol}${NumberFormat('#,###').format(sale.finalAmount)}',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${title}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  Future<void> _exportExcel(String title, List<Sale> sales) async {
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Sales Report'];

    // Headers
    sheet.appendRow([
      excel.TextCellValue('Receipt #'),
      excel.TextCellValue('Date'),
      excel.TextCellValue('Customer'),
      excel.TextCellValue('Payment'),
      excel.TextCellValue('Amount (UGX)'),
    ]);

    // Data
    for (var sale in sales) {
      sheet.appendRow([
        excel.TextCellValue(sale.receiptNumber),
        excel.TextCellValue(DateFormat('dd/MM/yyyy').format(sale.saleDate)),
        excel.TextCellValue(sale.customerName ?? 'Walk-in'),
        excel.TextCellValue(sale.paymentMethod),
        excel.DoubleCellValue(sale.finalAmount),
      ]);
    }

    // Save file
    final bytes = excelFile.save();
    if (bytes != null) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel Report',
        fileName: '${title}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report saved to $result')),
          );
        }
      }
    }
  }

  Future<void> _exportProfitLossPDF(double revenue, double cost, double profit, double margin) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Profit & Loss Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
            pw.SizedBox(height: 20),
            pw.Table(
              children: [
                pw.TableRow(children: [
                  pw.Text('Revenue:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(revenue)}'),
                ]),
                pw.TableRow(children: [
                  pw.Text('Cost:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(cost)}'),
                ]),
                pw.TableRow(children: [
                  pw.Text('Net Profit:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(profit)}'),
                ]),
                pw.TableRow(children: [
                  pw.Text('Profit Margin:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${margin.toStringAsFixed(1)}%'),
                ]),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'ProfitLoss_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  Future<void> _exportProfitLossExcel(double revenue, double cost, double profit, double margin) async {
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Profit & Loss'];

    sheet.appendRow([excel.TextCellValue('Metric'), excel.TextCellValue('Value (UGX)')]);
    sheet.appendRow([excel.TextCellValue('Revenue'), excel.DoubleCellValue(revenue)]);
    sheet.appendRow([excel.TextCellValue('Cost'), excel.DoubleCellValue(cost)]);
    sheet.appendRow([excel.TextCellValue('Net Profit'), excel.DoubleCellValue(profit)]);
    sheet.appendRow([excel.TextCellValue('Profit Margin (%)'), excel.DoubleCellValue(margin)]);

    final bytes = excelFile.save();
    if (bytes != null) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Profit & Loss Report',
        fileName: 'ProfitLoss_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report saved to $result')),
          );
        }
      }
    }
  }

  Future<void> _exportStockReportPDF(List<Drug> drugs) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Stock Analysis Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(text: 'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Drug Name', 'Batch', 'Quantity', 'Value', 'Expiry Date', 'Status'],
            data: drugs.map((drug) {
              final daysToExpiry = drug.expiryDate.difference(DateTime.now()).inDays;
              String status = 'OK';
              if (drug.quantity == 0) status = 'Out of Stock';
              else if (drug.quantity <= drug.reorderLevel) status = 'Low Stock';
              if (daysToExpiry <= AppConfig.expiryWarningDays) status += ' | Expiring';
              
              return [
                drug.name,
                drug.batchNumber,
                drug.quantity.toString(),
                '${AppConfig.currencySymbol}${NumberFormat('#,###').format(drug.quantity * drug.sellingPrice)}',
                DateFormat('dd/MM/yyyy').format(drug.expiryDate),
                status,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'StockReport_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  Future<void> _exportStockReportExcel(List<Drug> drugs) async {
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Stock Report'];

    sheet.appendRow([
      excel.TextCellValue('Drug Name'),
      excel.TextCellValue('Batch'),
      excel.TextCellValue('Quantity'),
      excel.TextCellValue('Value (UGX)'),
      excel.TextCellValue('Expiry Date'),
      excel.TextCellValue('Status'),
    ]);

    for (var drug in drugs) {
      final daysToExpiry = drug.expiryDate.difference(DateTime.now()).inDays;
      String status = 'OK';
      if (drug.quantity == 0) status = 'Out of Stock';
      else if (drug.quantity <= drug.reorderLevel) status = 'Low Stock';
      if (daysToExpiry <= AppConfig.expiryWarningDays) status += ' | Expiring';

      sheet.appendRow([
        excel.TextCellValue(drug.name),
        excel.TextCellValue(drug.batchNumber),
        excel.IntCellValue(drug.quantity),
        excel.DoubleCellValue(drug.quantity * drug.sellingPrice),
        excel.TextCellValue(DateFormat('dd/MM/yyyy').format(drug.expiryDate)),
        excel.TextCellValue(status),
      ]);
    }

    final bytes = excelFile.save();
    if (bytes != null) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Stock Report',
        fileName: 'StockReport_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report saved to $result')),
          );
        }
      }
    }
  }

  Future<void> _exportBestSellersPDF(List<MapEntry<String, Map<String, dynamic>>> drugs) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Best Sellers Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Paragraph(text: 'Period: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Rank', 'Drug Name', 'Units Sold', 'Revenue (UGX)'],
            data: drugs.take(20).toList().asMap().entries.map((entry) => [
              (entry.key + 1).toString(),
              entry.value.key,
              entry.value.value['quantity'].toString(),
              '${AppConfig.currencySymbol}${NumberFormat('#,###').format(entry.value.value['revenue'])}',
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'BestSellers_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  Future<void> _exportBestSellersExcel(List<MapEntry<String, Map<String, dynamic>>> drugs) async {
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Best Sellers'];

    sheet.appendRow([
      excel.TextCellValue('Rank'),
      excel.TextCellValue('Drug Name'),
      excel.TextCellValue('Units Sold'),
      excel.TextCellValue('Revenue (UGX)'),
    ]);

    drugs.take(20).toList().asMap().entries.forEach((entry) {
      sheet.appendRow([
        excel.IntCellValue(entry.key + 1),
        excel.TextCellValue(entry.value.key),
        excel.IntCellValue(entry.value.value['quantity']),
        excel.DoubleCellValue(entry.value.value['revenue']),
      ]);
    });

    final bytes = excelFile.save();
    if (bytes != null) {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Best Sellers Report',
        fileName: 'BestSellers_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Report saved to $result')),
          );
        }
      }
    }
  }
}
