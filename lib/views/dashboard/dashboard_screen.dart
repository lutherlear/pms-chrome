import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import '../../database/app_database.dart';
import '../../services/auth_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/sidebar_navigation.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedRoute = '/dashboard';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    final authService = context.watch<AuthService>();
    final db = context.read<AppDatabase>();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Row(
        children: [
          // Sidebar Navigation
          if (isDesktop)
            SidebarNavigation(
              selectedRoute: selectedRoute,
              onRouteSelected: (route) {
                setState(() {
                  selectedRoute = route;
                });
                if (route != '/dashboard') {
                  Navigator.pushNamed(context, route);
                }
              },
            ),

          // Main Content
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
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      
                      const Spacer(),
                      
                      // User Info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PhosphorIconsRegular.user,
                                size: 20,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authService.currentUser?.fullName ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  authService.currentUser?.role ?? 'Role',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: Icon(
                                PhosphorIconsRegular.signOut,
                                color: AppTheme.error,
                              ),
                              onPressed: () async {
                                await authService.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Message
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen,
                                AppTheme.lightGreen,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back, ${authService.currentUser?.fullName ?? 'User'}!',
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                PhosphorIconsBold.heartbeat,
                                size: 64,
                                color: AppTheme.white.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Statistics Cards
                        StreamBuilder<double>(
                          stream: Stream.fromFuture(db.getTodayTotalSales()),
                          builder: (context, salesSnapshot) {
                            return StreamBuilder<List<Drug>>(
                              stream: db.watchLowStockDrugs(AppConfig.lowStockThreshold),
                              builder: (context, lowStockSnapshot) {
                                return StreamBuilder<List<Drug>>(
                                  stream: db.watchExpiringDrugs(AppConfig.expiryWarningDays),
                                  builder: (context, expiringSnapshot) {
                                    return StreamBuilder<List<Drug>>(
                                      stream: db.watchAllDrugs(),
                                      builder: (context, drugsSnapshot) {
                                        final todaySales = salesSnapshot.data ?? 0.0;
                                        final lowStockCount = lowStockSnapshot.data?.length ?? 0;
                                        final expiringCount = expiringSnapshot.data?.length ?? 0;
                                        final totalDrugs = drugsSnapshot.data?.length ?? 0;
                                        
                                        return GridView.count(
                                          crossAxisCount: isDesktop ? 4 : 2,
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          childAspectRatio: isDesktop ? 1.5 : 1.2,
                                          children: [
                                            StatCard(
                                              title: 'Today\'s Sales',
                                              value: '${AppConfig.currencySymbol}${NumberFormat('#,###').format(todaySales)}',
                                              icon: PhosphorIconsBold.money,
                                              color: AppTheme.success,
                                              trend: '+12%',
                                              trendUp: true,
                                            ),
                                            StatCard(
                                              title: 'Total Drugs',
                                              value: totalDrugs.toString(),
                                              icon: PhosphorIconsBold.pill,
                                              color: AppTheme.primaryBlue,
                                            ),
                                            StatCard(
                                              title: 'Low Stock',
                                              value: lowStockCount.toString(),
                                              icon: PhosphorIconsBold.warning,
                                              color: AppTheme.warning,
                                              showWarning: lowStockCount > 0,
                                            ),
                                            StatCard(
                                              title: 'Expiring Soon',
                                              value: expiringCount.toString(),
                                              icon: PhosphorIconsBold.clock,
                                              color: AppTheme.error,
                                              showWarning: expiringCount > 0,
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Charts Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sales Chart
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
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
                                          'Sales Overview',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'This Week',
                                            style: TextStyle(
                                              color: AppTheme.primaryGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 200,
                                      child: LineChart(
                                        LineChartData(
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            getDrawingHorizontalLine: (value) {
                                              return FlLine(
                                                color: AppTheme.lightGray,
                                                strokeWidth: 1,
                                              );
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  return Text(
                                                    '${value.toInt()}k',
                                                    style: TextStyle(
                                                      color: AppTheme.gray,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                },
                                                reservedSize: 40,
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, meta) {
                                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                                  return Text(
                                                    days[value.toInt()],
                                                    style: TextStyle(
                                                      color: AppTheme.gray,
                                                      fontSize: 12,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            rightTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            topTitles: AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: [
                                                const FlSpot(0, 45),
                                                const FlSpot(1, 52),
                                                const FlSpot(2, 48),
                                                const FlSpot(3, 65),
                                                const FlSpot(4, 58),
                                                const FlSpot(5, 72),
                                                const FlSpot(6, 68),
                                              ],
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
                            ),
                            
                            if (isDesktop) ...[
                              const SizedBox(width: 24),
                              
                              // Quick Actions
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Quick Actions',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildQuickAction(
                                        context,
                                        'New Sale',
                                        PhosphorIconsRegular.shoppingCart,
                                        AppTheme.primaryGreen,
                                        () => Navigator.pushNamed(context, '/sales'),
                                      ),
                                      _buildQuickAction(
                                        context,
                                        'Add Drug',
                                        PhosphorIconsRegular.plus,
                                        AppTheme.primaryBlue,
                                        () => Navigator.pushNamed(context, '/inventory'),
                                      ),
                                      _buildQuickAction(
                                        context,
                                        'View Reports',
                                        PhosphorIconsRegular.chartBar,
                                        AppTheme.warning,
                                        () => Navigator.pushNamed(context, '/reports'),
                                      ),
                                      _buildQuickAction(
                                        context,
                                        'Manage Users',
                                        PhosphorIconsRegular.users,
                                        AppTheme.info,
                                        () => Navigator.pushNamed(context, '/users'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
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
                  setState(() {
                    selectedRoute = route;
                  });
                  if (route != '/dashboard') {
                    Navigator.pushNamed(context, route);
                  }
                },
              ),
            )
          : null,
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIconsRegular.arrowRight,
                size: 14,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
