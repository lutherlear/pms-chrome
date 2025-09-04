import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';
import '../../database/app_database.dart';
import '../../services/auth_service.dart';
import '../../widgets/sidebar_navigation.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final String selectedRoute = '/sales';
  final _searchController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  
  List<CartItem> _cartItems = [];
  String _selectedPaymentMethod = 'Cash';
  double _totalAmount = 0.0;
  double _discount = 0.0;
  double _finalAmount = 0.0;
  
  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    _totalAmount = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    _discount = double.tryParse(_discountController.text) ?? 0.0;
    _finalAmount = _totalAmount - _discount;
    setState(() {});
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
                        'Point of Sale',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      
                      // New Sale Button
                      ElevatedButton.icon(
                        onPressed: _clearCart,
                        icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 20),
                        label: const Text('New Sale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.info,
                          foregroundColor: AppTheme.white,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Sales History Button
                      OutlinedButton.icon(
                        onPressed: () => _showSalesHistory(context, db),
                        icon: const Icon(PhosphorIconsRegular.clockCounterClockwise, size: 20),
                        label: const Text('Sales History'),
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Row(
                    children: [
                      // Left Side - Product Search and Cart
                      Expanded(
                        flex: 3,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search Bar
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search drugs by name, barcode, or batch...',
                                  prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppTheme.gray),
                                  suffixIcon: IconButton(
                                    icon: Icon(PhosphorIconsRegular.barcode, color: AppTheme.primaryGreen),
                                    onPressed: () {
                                      // Barcode scanner functionality
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppTheme.lightGray),
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Drug Search Results
                              if (_searchController.text.isNotEmpty)
                                Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.lightGray),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: StreamBuilder<List<Drug>>(
                                    stream: db.watchAllDrugs(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      
                                      final drugs = snapshot.data!.where((drug) {
                                        final searchLower = _searchController.text.toLowerCase();
                                        return drug.name.toLowerCase().contains(searchLower) ||
                                               drug.batchNumber.toLowerCase().contains(searchLower) ||
                                               (drug.barcode?.toLowerCase().contains(searchLower) ?? false);
                                      }).toList();
                                      
                                      if (drugs.isEmpty) {
                                        return Center(
                                          child: Text(
                                            'No drugs found',
                                            style: TextStyle(color: AppTheme.gray),
                                          ),
                                        );
                                      }
                                      
                                      return ListView.builder(
                                        itemCount: drugs.length,
                                        itemBuilder: (context, index) {
                                          final drug = drugs[index];
                                          return ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                PhosphorIconsRegular.pill,
                                                size: 20,
                                                color: AppTheme.primaryGreen,
                                              ),
                                            ),
                                            title: Text(drug.name),
                                            subtitle: Text(
                                              'Batch: ${drug.batchNumber} | Stock: ${drug.quantity} | ${AppConfig.currencySymbol}${drug.sellingPrice}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(PhosphorIconsRegular.plus, color: AppTheme.primaryGreen),
                                              onPressed: drug.quantity > 0
                                                  ? () => _addToCart(drug)
                                                  : null,
                                            ),
                                            enabled: drug.quantity > 0,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              
                              const SizedBox(height: 20),
                              
                              // Cart Items Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(PhosphorIconsBold.shoppingCart, color: AppTheme.primaryGreen),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cart Items (${_cartItems.length})',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                    ],
                                  ),
                                  if (_cartItems.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: _clearCart,
                                      icon: Icon(PhosphorIconsRegular.trash, size: 18),
                                      label: const Text('Clear Cart'),
                                      style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Cart Items List
                              Expanded(
                                child: _cartItems.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              PhosphorIconsRegular.shoppingCartSimple,
                                              size: 64,
                                              color: AppTheme.gray.withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Cart is empty',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: AppTheme.gray,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Search and add drugs to start a sale',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.gray.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _cartItems.length,
                                        itemBuilder: (context, index) {
                                          final item = _cartItems[index];
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: ListTile(
                                              leading: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  PhosphorIconsRegular.pill,
                                                  size: 20,
                                                  color: AppTheme.primaryBlue,
                                                ),
                                              ),
                                              title: Text(item.drugName),
                                              subtitle: Text(
                                                'Unit Price: ${AppConfig.currencySymbol}${NumberFormat('#,###').format(item.unitPrice)} | Total: ${AppConfig.currencySymbol}${NumberFormat('#,###').format(item.totalPrice)}',
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(PhosphorIconsRegular.minus, size: 18),
                                                    onPressed: () => _updateQuantity(index, item.quantity - 1),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.offWhite,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      item.quantity.toString(),
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(PhosphorIconsRegular.plus, size: 18),
                                                    onPressed: item.quantity < item.availableStock
                                                        ? () => _updateQuantity(index, item.quantity + 1)
                                                        : null,
                                                  ),
                                                  IconButton(
                                                    icon: Icon(PhosphorIconsRegular.x, size: 18, color: AppTheme.error),
                                                    onPressed: () => _removeFromCart(index),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Right Side - Checkout Panel
                      Container(
                        width: 400,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checkout',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            
                            // Customer Information
                            TextField(
                              controller: _customerNameController,
                              decoration: InputDecoration(
                                labelText: 'Customer Name (Optional)',
                                prefixIcon: Icon(PhosphorIconsRegular.user),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _customerPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Customer Phone (Optional)',
                                prefixIcon: Icon(PhosphorIconsRegular.phone),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Payment Method
                            Text('Payment Method', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'Cash', label: Text('Cash'), icon: Icon(PhosphorIconsRegular.money)),
                                ButtonSegment(value: 'Mobile Money', label: Text('Mobile'), icon: Icon(PhosphorIconsRegular.deviceMobile)),
                                ButtonSegment(value: 'Card', label: Text('Card'), icon: Icon(PhosphorIconsRegular.creditCard)),
                              ],
                              selected: {_selectedPaymentMethod},
                              onSelectionChanged: (Set<String> selection) {
                                setState(() {
                                  _selectedPaymentMethod = selection.first;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Discount
                            TextField(
                              controller: _discountController,
                              decoration: InputDecoration(
                                labelText: 'Discount (${AppConfig.currency})',
                                prefixIcon: Icon(PhosphorIconsRegular.percent),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) => _calculateTotals(),
                            ),
                            
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                            
                            // Totals
                            _buildTotalRow('Subtotal', _totalAmount),
                            const SizedBox(height: 8),
                            _buildTotalRow('Discount', -_discount, isDiscount: true),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  Text(
                                    '${AppConfig.currencySymbol}${NumberFormat('#,###.##').format(_finalAmount)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _cartItems.isNotEmpty ? () => _processSale(context, db, authService) : null,
                                    icon: const Icon(PhosphorIconsRegular.checkCircle),
                                    label: const Text('Complete Sale'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      foregroundColor: AppTheme.white,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _cartItems.isNotEmpty ? () => _printReceipt(null) : null,
                                    icon: const Icon(PhosphorIconsRegular.printer),
                                    label: const Text('Print'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildTotalRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDiscount ? AppTheme.warning : AppTheme.gray,
          ),
        ),
        Text(
          '${AppConfig.currencySymbol}${NumberFormat('#,###.##').format(amount.abs())}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppTheme.warning : AppTheme.black,
          ),
        ),
      ],
    );
  }

  void _addToCart(Drug drug) {
    final existingIndex = _cartItems.indexWhere((item) => 
        item.drugId == drug.id && item.batchNumber == drug.batchNumber);
    
    if (existingIndex != -1) {
      if (_cartItems[existingIndex].quantity < drug.quantity) {
        _cartItems[existingIndex].quantity++;
        _cartItems[existingIndex].totalPrice = 
            _cartItems[existingIndex].quantity * _cartItems[existingIndex].unitPrice;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough stock available')),
        );
      }
    } else {
      _cartItems.add(CartItem(
        drugId: drug.id,
        drugName: drug.name,
        batchNumber: drug.batchNumber,
        quantity: 1,
        unitPrice: drug.sellingPrice,
        totalPrice: drug.sellingPrice,
        availableStock: drug.quantity,
      ));
    }
    
    _searchController.clear();
    _calculateTotals();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(index);
    } else if (newQuantity <= _cartItems[index].availableStock) {
      _cartItems[index].quantity = newQuantity;
      _cartItems[index].totalPrice = newQuantity * _cartItems[index].unitPrice;
      _calculateTotals();
    }
  }

  void _removeFromCart(int index) {
    _cartItems.removeAt(index);
    _calculateTotals();
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _discountController.text = '0';
      _selectedPaymentMethod = 'Cash';
      _calculateTotals();
    });
  }

  Future<void> _processSale(BuildContext context, AppDatabase db, AuthService authService) async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    try {
      // Generate receipt number
      final receiptNumber = 'RCP${DateTime.now().millisecondsSinceEpoch}';
      
      // Create sale record
      final sale = await db.createSale(SalesCompanion(
        receiptNumber: drift.Value(receiptNumber),
        totalAmount: drift.Value(_totalAmount),
        discount: drift.Value(_discount),
        finalAmount: drift.Value(_finalAmount),
        paymentMethod: drift.Value(_selectedPaymentMethod),
        customerName: drift.Value(_customerNameController.text.isNotEmpty ? _customerNameController.text : null),
        customerPhone: drift.Value(_customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : null),
        cashierId: drift.Value(authService.currentUser!.id),
      ));
      
      // Create sale items
      final saleItems = _cartItems.map((item) => SaleItemsCompanion(
        saleId: drift.Value(sale.id),
        drugId: drift.Value(item.drugId),
        drugName: drift.Value(item.drugName),
        batchNumber: drift.Value(item.batchNumber),
        quantity: drift.Value(item.quantity),
        unitPrice: drift.Value(item.unitPrice),
        totalPrice: drift.Value(item.totalPrice),
      )).toList();
      
      // Complete sale and update stock
      await db.completeSale(sale.id, saleItems);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale completed successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Print receipt
        await _printReceipt(sale);
        
        // Clear cart
        _clearCart();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing sale: $e')),
        );
      }
    }
  }

  Future<void> _printReceipt(Sale? sale) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      AppConfig.companyName,
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(AppConfig.companyAddress),
                    pw.Text('Tel: ${AppConfig.companyPhone}'),
                    pw.Text(AppConfig.companyEmail),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'SALES RECEIPT',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Receipt Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Receipt #: ${sale?.receiptNumber ?? 'PREVIEW'}'),
                      pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(sale?.saleDate ?? DateTime.now())}'),
                      if (_customerNameController.text.isNotEmpty)
                        pw.Text('Customer: ${_customerNameController.text}'),
                      if (_customerPhoneController.text.isNotEmpty)
                        pw.Text('Phone: ${_customerPhoneController.text}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Payment: $_selectedPaymentMethod'),
                      pw.Text('Served by: ${Provider.of<AuthService>(context, listen: false).currentUser?.fullName ?? 'Cashier'}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ..._cartItems.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.drugName)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.quantity.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${AppConfig.currencySymbol}${item.unitPrice}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${AppConfig.currencySymbol}${item.totalPrice}')),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${AppConfig.currencySymbol}${NumberFormat('#,###.##').format(_totalAmount)}'),
                    pw.Text('Discount: ${AppConfig.currencySymbol}${NumberFormat('#,###.##').format(_discount)}'),
                    pw.Divider(),
                    pw.Text(
                      'Total: ${AppConfig.currencySymbol}${NumberFormat('#,###.##').format(_finalAmount)}',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(AppConfig.receiptFooter),
                    pw.SizedBox(height: 10),
                    pw.Text('Powered by Tafoweg Pharmacy Management System', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${sale?.receiptNumber ?? 'Preview'}',
    );
  }

  void _showSalesHistory(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Today\'s Sales'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: StreamBuilder<List<Sale>>(
              stream: db.watchTodaySales(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final sales = snapshot.data!;
                
                if (sales.isEmpty) {
                  return const Center(child: Text('No sales today'));
                }
                
                return ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsRegular.receipt,
                          color: AppTheme.success,
                        ),
                      ),
                      title: Text('Receipt #${sale.receiptNumber}'),
                      subtitle: Text(
                        '${DateFormat('HH:mm').format(sale.saleDate)} | ${sale.paymentMethod} | ${sale.customerName ?? 'Walk-in Customer'}',
                      ),
                      trailing: Text(
                        '${AppConfig.currencySymbol}${NumberFormat('#,###').format(sale.finalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class CartItem {
  final int drugId;
  final String drugName;
  final String batchNumber;
  int quantity;
  final double unitPrice;
  double totalPrice;
  final int availableStock;

  CartItem({
    required this.drugId,
    required this.drugName,
    required this.batchNumber,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.availableStock,
  });
}
