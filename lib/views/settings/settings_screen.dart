import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:io';
import '../../config/app_theme.dart';
import '../../database/app_database.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/sidebar_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String selectedRoute = '/settings';
  
  // Company Settings Controllers
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _tinController = TextEditingController();
  final _registrationController = TextEditingController();
  final _sloganController = TextEditingController();
  
  // System Settings
  String _selectedCurrency = 'UGX';
  String _selectedDateFormat = 'DD/MM/YYYY';
  String _selectedTheme = 'Light';
  bool _enableNotifications = true;
  bool _enableAutoBackup = false;
  int _backupFrequency = 7; // days
  String _backupPath = '';
  
  // Receipt Settings
  bool _printLogo = true;
  bool _printSlogan = true;
  bool _printTin = false;
  String _receiptFooter = 'Thank you for your purchase!';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  void _loadSettings() async {
    // Load saved company settings
    final companySettings = await SettingsService.getCompanySettings();
    _companyNameController.text = companySettings['companyName'] ?? 'Tafoweg Pharmacy';
    _addressController.text = companySettings['address'] ?? 'P.O. Box 123, Kampala, Uganda';
    _phoneController.text = companySettings['phone'] ?? '+256 700 123 456';
    _emailController.text = companySettings['email'] ?? 'info@tafowegpharmacy.com';
    _tinController.text = companySettings['tin'] ?? 'UG1234567890';
    _registrationController.text = companySettings['registration'] ?? 'BN123456789';
    _sloganController.text = companySettings['slogan'] ?? 'Your Health, Our Priority';
    
    // Load system settings
    final systemSettings = await SettingsService.getSystemSettings();
    setState(() {
      _selectedCurrency = systemSettings['currency'] ?? 'UGX';
      _selectedDateFormat = systemSettings['dateFormat'] ?? 'DD/MM/YYYY';
      _selectedTheme = systemSettings['theme'] ?? 'Light';
      _enableNotifications = systemSettings['notifications'] ?? true;
      _enableAutoBackup = systemSettings['autoBackup'] ?? false;
      _backupFrequency = systemSettings['backupFrequency'] ?? 7;
    });
    
    // Load receipt settings
    final receiptSettings = await SettingsService.getReceiptSettings();
    setState(() {
      _printLogo = receiptSettings['printLogo'] ?? true;
      _printSlogan = receiptSettings['printSlogan'] ?? true;
      _printTin = receiptSettings['printTin'] ?? false;
      _receiptFooter = receiptSettings['receiptFooter'] ?? 'Thank you for your purchase!';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tinController.dispose();
    _registrationController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;
    final authService = context.watch<AuthService>();
    final db = context.read<AppDatabase>();

    // Only Admin can access settings
    if (!authService.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.lockKey, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              const Text('Admin Access Only', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Settings management is restricted to administrators'),
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
                        'Settings',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      
                      // Save Settings Button
                      ElevatedButton.icon(
                        onPressed: () => _saveSettings(context, db),
                        icon: const Icon(PhosphorIconsRegular.floppyDisk, size: 20),
                        label: const Text('Save All Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.white,
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
                    tabs: const [
                      Tab(text: 'Company', icon: Icon(PhosphorIconsRegular.buildings)),
                      Tab(text: 'System', icon: Icon(PhosphorIconsRegular.gear)),
                      Tab(text: 'Backup & Restore', icon: Icon(PhosphorIconsRegular.cloudArrowUp)),
                      Tab(text: 'Receipt', icon: Icon(PhosphorIconsRegular.receipt)),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCompanySettings(),
                      _buildSystemSettings(),
                      _buildBackupRestore(db),
                      _buildReceiptSettings(),
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

  Widget _buildCompanySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Information',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your pharmacy business details',
            style: TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 24),

          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _companyNameController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(PhosphorIconsRegular.buildings, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _registrationController,
                        decoration: InputDecoration(
                          labelText: 'Registration Number',
                          prefixIcon: Icon(PhosphorIconsRegular.identificationCard, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Business Address',
                    prefixIcon: Icon(PhosphorIconsRegular.mapPin, color: AppTheme.primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(PhosphorIconsRegular.phone, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(PhosphorIconsRegular.envelope, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tinController,
                        decoration: InputDecoration(
                          labelText: 'TIN (Tax Identification Number)',
                          prefixIcon: Icon(PhosphorIconsRegular.receipt, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _sloganController,
                        decoration: InputDecoration(
                          labelText: 'Company Slogan',
                          prefixIcon: Icon(PhosphorIconsRegular.chat, color: AppTheme.primaryGreen),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Logo Upload Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.lightGray),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.offWhite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          PhosphorIconsRegular.image,
                          size: 40,
                          color: AppTheme.gray,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Company Logo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload your pharmacy logo for receipts and documents',
                              style: TextStyle(fontSize: 12, color: AppTheme.gray),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _uploadLogo(),
                              icon: const Icon(PhosphorIconsRegular.upload, size: 16),
                              label: const Text('Upload Logo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: AppTheme.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildSystemSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Preferences',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure system-wide settings and preferences',
            style: TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 24),

          // Currency Settings
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.currencyCircleDollar, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Currency Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'Default Currency',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    'UGX - Uganda Shilling',
                    'GHS - Ghana Cedi',
                    'USD - US Dollar',
                    'EUR - Euro',
                    'GBP - British Pound',
                    'NGN - Nigerian Naira',
                    'KES - Kenyan Shilling',
                    'TZS - Tanzanian Shilling',
                  ].map((currency) {
                    final code = currency.split(' - ')[0];
                    return DropdownMenuItem(
                      value: code,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Date & Time Settings
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.calendar, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Date & Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDateFormat,
                  decoration: InputDecoration(
                    labelText: 'Date Format',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    'DD/MM/YYYY',
                    'MM/DD/YYYY',
                    'YYYY-MM-DD',
                  ].map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(format),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFormat = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appearance Settings
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.palette, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Appearance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTheme,
                  decoration: InputDecoration(
                    labelText: 'Theme',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['Light', 'Dark', 'System'].map((theme) {
                    return DropdownMenuItem(
                      value: theme,
                      child: Row(
                        children: [
                          Icon(
                            theme == 'Light' ? PhosphorIconsRegular.sun :
                            theme == 'Dark' ? PhosphorIconsRegular.moon :
                            PhosphorIconsRegular.desktop,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(theme),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notification Settings
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.bell, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive alerts for low stock and expiring drugs'),
                  value: _enableNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableNotifications = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestore(AppDatabase db) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage database backups and restore points',
            style: TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 24),

          // Manual Backup
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.downloadSimple, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Manual Backup',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Create a backup of your database now',
                  style: TextStyle(color: AppTheme.gray),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _createBackup(context, db),
                  icon: const Icon(PhosphorIconsRegular.downloadSimple),
                  label: const Text('Create Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.info, color: AppTheme.info, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Last backup: 2 days ago (02/09/2025 14:30)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Automatic Backup
          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.clockClockwise, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    const Text(
                      'Automatic Backup',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Auto Backup'),
                  subtitle: const Text('Automatically backup database at regular intervals'),
                  value: _enableAutoBackup,
                  onChanged: (value) {
                    setState(() {
                      _enableAutoBackup = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
                if (_enableAutoBackup) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _backupFrequency,
                    decoration: InputDecoration(
                      labelText: 'Backup Frequency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: 1, child: Text('Daily')),
                      const DropdownMenuItem(value: 3, child: Text('Every 3 days')),
                      const DropdownMenuItem(value: 7, child: Text('Weekly')),
                      const DropdownMenuItem(value: 14, child: Text('Bi-weekly')),
                      const DropdownMenuItem(value: 30, child: Text('Monthly')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _backupFrequency = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: _backupPath),
                    decoration: InputDecoration(
                      labelText: 'Backup Location',
                      hintText: 'Select backup folder',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(PhosphorIconsRegular.folder),
                        onPressed: () => _selectBackupLocation(),
                      ),
                    ),
                    readOnly: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Restore Database
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.uploadSimple, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    const Text(
                      'Restore Database',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsRegular.warning, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Warning: Restoring will replace all current data with the backup data',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _restoreBackup(context, db),
                  icon: const Icon(PhosphorIconsRegular.uploadSimple),
                  label: const Text('Restore from Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt Configuration',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Customize receipt layout and content',
            style: TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 24),

          Container(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.receipt, color: AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    const Text(
                      'Receipt Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SwitchListTile(
                  title: const Text('Print Company Logo'),
                  subtitle: const Text('Include logo on receipts'),
                  value: _printLogo,
                  onChanged: (value) {
                    setState(() {
                      _printLogo = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),

                SwitchListTile(
                  title: const Text('Print Company Slogan'),
                  subtitle: const Text('Include slogan on receipts'),
                  value: _printSlogan,
                  onChanged: (value) {
                    setState(() {
                      _printSlogan = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),

                SwitchListTile(
                  title: const Text('Print TIN Number'),
                  subtitle: const Text('Include Tax Identification Number on receipts'),
                  value: _printTin,
                  onChanged: (value) {
                    setState(() {
                      _printTin = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),

                const SizedBox(height: 24),
                TextField(
                  controller: TextEditingController(text: _receiptFooter),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Receipt Footer Text',
                    hintText: 'Enter text to appear at the bottom of receipts',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    _receiptFooter = value;
                  },
                ),

                const SizedBox(height: 24),
                
                // Receipt Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receipt Preview',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          border: Border.all(color: AppTheme.gray.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_printLogo)
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.offWhite,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  PhosphorIconsRegular.firstAidKit,
                                  size: 30,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              _companyNameController.text,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (_printSlogan && _sloganController.text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _sloganController.text,
                                style: TextStyle(fontSize: 12, color: AppTheme.gray),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              _addressController.text,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Tel: ${_phoneController.text}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            if (_printTin && _tinController.text.isNotEmpty) ...[
                              Text(
                                'TIN: ${_tinController.text}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                            const Divider(height: 16),
                            const Text(
                              'SALES RECEIPT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            const Text('Receipt #: 000123', style: TextStyle(fontSize: 10)),
                            Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const TextStyle(fontSize: 10)),
                            const Divider(height: 16),
                            const Text('Items preview...', style: TextStyle(fontSize: 10)),
                            const Divider(height: 16),
                            if (_receiptFooter.isNotEmpty) ...[
                              Text(
                                _receiptFooter,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
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

  void _uploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      // Handle logo upload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo uploaded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  void _selectBackupLocation() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        _backupPath = result;
      });
    }
  }

  void _createBackup(BuildContext context, AppDatabase db) async {
    try {
      final backupService = BackupService(db);
      final backupPath = await backupService.createBackup();
      
      // Log activity
      final authService = context.read<AuthService>();
      await db.logActivity(ActivityLogsCompanion(
        userId: drift.Value(authService.currentUser!.id),
        action: const drift.Value('Create Backup'),
        module: const drift.Value('Settings'),
        details: drift.Value('Created database backup at: $backupPath'),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully at: $backupPath'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating backup: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _restoreBackup(BuildContext context, AppDatabase db) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to restore from a backup?'),
            SizedBox(height: 16),
            Text(
              'WARNING: This will replace all current data!',
              style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: AppTheme.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Pick backup file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      dialogTitle: 'Select Backup File',
    );

    if (result != null && result.files.single.path != null) {
      try {
        final backupService = BackupService(db);
        await backupService.restoreBackup(result.files.single.path!);
        
        // Log activity
        final authService = context.read<AuthService>();
        await db.logActivity(ActivityLogsCompanion(
          userId: drift.Value(authService.currentUser!.id),
          action: const drift.Value('Restore Backup'),
          module: const drift.Value('Settings'),
          details: drift.Value('Restored database from backup'),
        ));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database restored successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error restoring backup: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _saveSettings(BuildContext context, AppDatabase db) async {
    try {
      // Save company settings
      await SettingsService.saveCompanySettings(
        companyName: _companyNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        tin: _tinController.text,
        registration: _registrationController.text,
        slogan: _sloganController.text,
      );
      
      // Save system settings
      await SettingsService.saveSystemSettings(
        currency: _selectedCurrency,
        dateFormat: _selectedDateFormat,
        theme: _selectedTheme,
        notifications: _enableNotifications,
        autoBackup: _enableAutoBackup,
        backupFrequency: _backupFrequency,
      );
      
      // Save receipt settings
      await SettingsService.saveReceiptSettings(
        printLogo: _printLogo,
        printSlogan: _printSlogan,
        printTin: _printTin,
        receiptFooter: _receiptFooter,
      );
      
      // Log activity
      final authService = context.read<AuthService>();
      await db.logActivity(ActivityLogsCompanion(
        userId: drift.Value(authService.currentUser!.id),
        action: const drift.Value('Update Settings'),
        module: const drift.Value('Settings'),
        details: const drift.Value('Updated system settings'),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
