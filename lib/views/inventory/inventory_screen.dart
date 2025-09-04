import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import '../../database/app_database.dart';
import '../../services/auth_service.dart';
import '../../widgets/sidebar_navigation.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedFilter = 'all';
  String selectedRoute = '/inventory';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
                        'Inventory Management',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      
                      // Add Drug Button
                      ElevatedButton.icon(
                        onPressed: () => _showAddDrugDialog(context, db),
                        icon: const Icon(PhosphorIconsRegular.plus, size: 20),
                        label: const Text('Add Drug'),
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
                      Tab(text: 'All Drugs', icon: Icon(PhosphorIconsRegular.package)),
                      Tab(text: 'Low Stock', icon: Icon(PhosphorIconsRegular.warning)),
                      Tab(text: 'Expiring Soon', icon: Icon(PhosphorIconsRegular.clock)),
                    ],
                  ),
                ),
                
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.white,
                  child: Row(
                    children: [
                      // Search Field
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search drugs by name, batch number...',
                            prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppTheme.gray),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.lightGray),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Category Filter
                      StreamBuilder<List<DrugCategory>>(
                        stream: db.watchAllCategories(),
                        builder: (context, snapshot) {
                          final categories = ['All', ...(snapshot.data?.map((c) => c.name) ?? [])];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.lightGray),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              underline: const SizedBox(),
                              items: categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'All';
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Content Area
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All Drugs Tab
                      _buildDrugsTable(db, 'all'),
                      
                      // Low Stock Tab
                      _buildDrugsTable(db, 'low_stock'),
                      
                      // Expiring Soon Tab
                      _buildDrugsTable(db, 'expiring'),
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

  Widget _buildDrugsTable(AppDatabase db, String filter) {
    Stream<List<Drug>> drugsStream;
    
    switch (filter) {
      case 'low_stock':
        drugsStream = db.watchLowStockDrugs(AppConfig.lowStockThreshold);
        break;
      case 'expiring':
        drugsStream = db.watchExpiringDrugs(AppConfig.expiryWarningDays);
        break;
      default:
        drugsStream = db.watchAllDrugs();
    }

    return StreamBuilder<List<Drug>>(
      stream: drugsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var drugs = snapshot.data!;
        
        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          drugs = drugs.where((drug) {
            final searchLower = _searchController.text.toLowerCase();
            return drug.name.toLowerCase().contains(searchLower) ||
                   drug.batchNumber.toLowerCase().contains(searchLower) ||
                   (drug.genericName?.toLowerCase().contains(searchLower) ?? false);
          }).toList();
        }

        // Apply category filter
        if (_selectedCategory != 'All') {
          // You would need to join with categories here
        }

        if (drugs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filter == 'low_stock' 
                    ? PhosphorIconsRegular.warning
                    : filter == 'expiring'
                      ? PhosphorIconsRegular.clock
                      : PhosphorIconsRegular.package,
                  size: 64,
                  color: AppTheme.gray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  filter == 'low_stock'
                    ? 'No low stock items'
                    : filter == 'expiring'
                      ? 'No expiring drugs'
                      : 'No drugs found',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.gray,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 800,
            headingRowColor: MaterialStateColor.resolveWith((states) => AppTheme.offWhite),
            columns: const [
              DataColumn2(label: Text('Name'), size: ColumnSize.L),
              DataColumn(label: Text('Batch No.')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Buying Price')),
              DataColumn(label: Text('Selling Price')),
              DataColumn(label: Text('Expiry Date')),
              DataColumn(label: Text('Supplier')),
              DataColumn(label: Text('Actions')),
            ],
            rows: drugs.map((drug) {
              final isLowStock = drug.quantity <= drug.reorderLevel;
              final daysToExpiry = drug.expiryDate.difference(DateTime.now()).inDays;
              final isExpiring = daysToExpiry <= AppConfig.expiryWarningDays;
              
              return DataRow2(
                color: MaterialStateColor.resolveWith((states) {
                  if (isLowStock) return AppTheme.warning.withOpacity(0.05);
                  if (isExpiring) return AppTheme.error.withOpacity(0.05);
                  return AppTheme.white;
                }),
                cells: [
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drug.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (drug.genericName != null)
                          Text(
                            drug.genericName!,
                            style: TextStyle(fontSize: 12, color: AppTheme.gray),
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text(drug.batchNumber)),
                  DataCell(
                    Row(
                      children: [
                        Text(
                          drug.quantity.toString(),
                          style: TextStyle(
                            color: isLowStock ? AppTheme.error : AppTheme.black,
                            fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isLowStock) ...[
                          const SizedBox(width: 4),
                          Icon(
                            PhosphorIconsRegular.warning,
                            size: 16,
                            color: AppTheme.warning,
                          ),
                        ],
                      ],
                    ),
                  ),
                  DataCell(Text(drug.unit)),
                  DataCell(Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(drug.buyingPrice)}')),
                  DataCell(Text('${AppConfig.currencySymbol}${NumberFormat('#,###').format(drug.sellingPrice)}')),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(AppConfig.dateFormat).format(drug.expiryDate),
                          style: TextStyle(
                            color: isExpiring ? AppTheme.error : AppTheme.black,
                            fontWeight: isExpiring ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isExpiring)
                          Text(
                            '$daysToExpiry days',
                            style: TextStyle(fontSize: 11, color: AppTheme.error),
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text(drug.supplier)),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(PhosphorIconsRegular.pencil, size: 18, color: AppTheme.primaryBlue),
                          onPressed: () => _showEditDrugDialog(context, db, drug),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: Icon(PhosphorIconsRegular.trash, size: 18, color: AppTheme.error),
                          onPressed: () => _showDeleteConfirmation(context, db, drug),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAddDrugDialog(BuildContext context, AppDatabase db) {
    _showDrugDialog(context, db, null);
  }

  void _showEditDrugDialog(BuildContext context, AppDatabase db, Drug drug) {
    _showDrugDialog(context, db, drug);
  }

  void _showDrugDialog(BuildContext context, AppDatabase db, Drug? drug) {
    final isEdit = drug != null;
    final formKey = GlobalKey<FormState>();
    
    final nameController = TextEditingController(text: drug?.name);
    final genericNameController = TextEditingController(text: drug?.genericName);
    final batchController = TextEditingController(text: drug?.batchNumber);
    final quantityController = TextEditingController(text: drug?.quantity.toString());
    final unitController = TextEditingController(text: drug?.unit ?? 'piece');
    final buyingPriceController = TextEditingController(text: drug?.buyingPrice.toString());
    final sellingPriceController = TextEditingController(text: drug?.sellingPrice.toString());
    final reorderLevelController = TextEditingController(text: drug?.reorderLevel.toString() ?? '10');
    final supplierController = TextEditingController(text: drug?.supplier);
    final supplierContactController = TextEditingController(text: drug?.supplierContact);
    final barcodeController = TextEditingController(text: drug?.barcode);
    DateTime? expiryDate = drug?.expiryDate;
    int? selectedCategoryId = drug?.categoryId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Drug' : 'Add New Drug'),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Drug Name *',
                                  prefixIcon: Icon(PhosphorIconsRegular.pill),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter drug name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: genericNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Generic Name',
                                  prefixIcon: Icon(PhosphorIconsRegular.tag),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: StreamBuilder<List<DrugCategory>>(
                                stream: db.watchAllCategories(),
                                builder: (context, snapshot) {
                                  final categories = snapshot.data ?? [];
                                  return DropdownButtonFormField<int>(
                                    value: selectedCategoryId,
                                    decoration: const InputDecoration(
                                      labelText: 'Category *',
                                      prefixIcon: Icon(PhosphorIconsRegular.folder),
                                    ),
                                    items: categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCategoryId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a category';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: batchController,
                                decoration: const InputDecoration(
                                  labelText: 'Batch Number *',
                                  prefixIcon: Icon(PhosphorIconsRegular.hash),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter batch number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity *',
                                  prefixIcon: Icon(PhosphorIconsRegular.package),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter quantity';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: unitController.text,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  prefixIcon: Icon(PhosphorIconsRegular.cube),
                                ),
                                items: ['piece', 'bottle', 'box', 'strip', 'pack']
                                    .map((unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  unitController.text = value ?? 'piece';
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: reorderLevelController,
                                decoration: const InputDecoration(
                                  labelText: 'Reorder Level',
                                  prefixIcon: Icon(PhosphorIconsRegular.warning),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: buyingPriceController,
                                decoration: InputDecoration(
                                  labelText: 'Buying Price (${AppConfig.currency}) *',
                                  prefixIcon: const Icon(PhosphorIconsRegular.currencyCircleDollar),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter buying price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: sellingPriceController,
                                decoration: InputDecoration(
                                  labelText: 'Selling Price (${AppConfig.currency}) *',
                                  prefixIcon: const Icon(PhosphorIconsRegular.currencyCircleDollar),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter selling price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      expiryDate = picked;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Expiry Date *',
                                    prefixIcon: Icon(PhosphorIconsRegular.calendar),
                                  ),
                                  child: Text(
                                    expiryDate != null
                                        ? DateFormat(AppConfig.dateFormat).format(expiryDate!)
                                        : 'Select date',
                                    style: TextStyle(
                                      color: expiryDate != null ? AppTheme.black : AppTheme.gray,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: barcodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Barcode',
                                  prefixIcon: Icon(PhosphorIconsRegular.barcode),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: supplierController,
                                decoration: const InputDecoration(
                                  labelText: 'Supplier *',
                                  prefixIcon: Icon(PhosphorIconsRegular.truck),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter supplier name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: supplierContactController,
                                decoration: const InputDecoration(
                                  labelText: 'Supplier Contact',
                                  prefixIcon: Icon(PhosphorIconsRegular.phone),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (expiryDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select expiry date')),
                        );
                        return;
                      }

                      final drugData = DrugsCompanion(
                        name: drift.Value(nameController.text),
                        genericName: drift.Value(genericNameController.text.isEmpty ? null : genericNameController.text),
                        categoryId: drift.Value(selectedCategoryId!),
                        batchNumber: drift.Value(batchController.text),
                        quantity: drift.Value(int.parse(quantityController.text)),
                        unit: drift.Value(unitController.text),
                        reorderLevel: drift.Value(int.parse(reorderLevelController.text.isEmpty ? '10' : reorderLevelController.text)),
                        buyingPrice: drift.Value(double.parse(buyingPriceController.text)),
                        sellingPrice: drift.Value(double.parse(sellingPriceController.text)),
                        expiryDate: drift.Value(expiryDate!),
                        supplier: drift.Value(supplierController.text),
                        supplierContact: drift.Value(supplierContactController.text.isEmpty ? null : supplierContactController.text),
                        barcode: drift.Value(barcodeController.text.isEmpty ? null : barcodeController.text),
                      );

                      try {
                        if (isEdit) {
                          await db.updateDrug(drugData, drug!.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Drug updated successfully')),
                            );
                          }
                        } else {
                          await db.createDrug(drugData);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Drug added successfully')),
                            );
                          }
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.white,
                  ),
                  child: Text(isEdit ? 'Update' : 'Add Drug'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppDatabase db, Drug drug) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Drug'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to delete this drug?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drug: ${drug.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Batch: ${drug.batchNumber}'),
                    Text('Quantity: ${drug.quantity}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await db.deleteDrug(drug.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Drug deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting drug: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
