import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';

class SidebarNavigation extends StatelessWidget {
  final String selectedRoute;
  final Function(String) onRouteSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedRoute,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    return Container(
      width: 260,
      color: AppTheme.white,
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.lightGray,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    PhosphorIconsBold.heartbeat,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tafoweg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.black,
                        ),
                      ),
                      Text(
                        'Pharmacy System',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavigationItem(
                  context,
                  icon: PhosphorIconsRegular.house,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isSelected: selectedRoute == '/dashboard',
                  onTap: () => onRouteSelected('/dashboard'),
                ),
                
                if (authService.hasPermission('inventory'))
                  _buildNavigationItem(
                    context,
                    icon: PhosphorIconsRegular.package,
                    label: 'Inventory',
                    route: '/inventory',
                    isSelected: selectedRoute == '/inventory',
                    onTap: () => onRouteSelected('/inventory'),
                  ),
                
                if (authService.hasPermission('sales'))
                  _buildNavigationItem(
                    context,
                    icon: PhosphorIconsRegular.shoppingCart,
                    label: 'Sales',
                    route: '/sales',
                    isSelected: selectedRoute == '/sales',
                    onTap: () => onRouteSelected('/sales'),
                  ),
                
                // Reports - accessible by all but with limited views for non-admins
                _buildNavigationItem(
                  context,
                  icon: PhosphorIconsRegular.chartBar,
                  label: 'Reports',
                  route: '/reports',
                  isSelected: selectedRoute == '/reports',
                  onTap: () => onRouteSelected('/reports'),
                ),
                
                if (authService.isAdmin)
                  _buildNavigationItem(
                    context,
                    icon: PhosphorIconsRegular.users,
                    label: 'Users',
                    route: '/users',
                    isSelected: selectedRoute == '/users',
                    onTap: () => onRouteSelected('/users'),
                  ),
                
                if (authService.isAdmin) ...[                
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Divider(),
                  ),
                  
                  _buildNavigationItem(
                    context,
                    icon: PhosphorIconsRegular.gear,
                    label: 'Settings',
                    route: '/settings',
                    isSelected: selectedRoute == '/settings',
                    onTap: () => onRouteSelected('/settings'),
                  ),
                ],
              ],
            ),
          ),
          
          // User Section at Bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightGray,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(12),
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
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authService.currentUser?.fullName ?? 'User',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              authService.currentUser?.role ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.gray,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.darkGray,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
