import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';

part 'app_database.g.dart';

// Users table
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get password => text()(); // Hashed password
  TextColumn get fullName => text().withLength(min: 2, max: 100)();
  TextColumn get email => text().withLength(min: 5, max: 100)();
  TextColumn get phone => text().withLength(min: 10, max: 20)();
  TextColumn get role => text().withLength(min: 1, max: 20)(); // Admin, Cashier, Stock Manager
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastLogin => dateTime().nullable()();
}

// Drug categories table
class DrugCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 100).unique()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Drugs table
class Drugs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 200)();
  TextColumn get genericName => text().nullable()();
  IntColumn get categoryId => integer().references(DrugCategories, #id)();
  TextColumn get batchNumber => text().withLength(min: 1, max: 50)();
  RealColumn get buyingPrice => real()();
  RealColumn get sellingPrice => real()();
  IntColumn get quantity => integer()();
  IntColumn get reorderLevel => integer().withDefault(const Constant(10))();
  DateTimeColumn get expiryDate => dateTime()();
  TextColumn get supplier => text().withLength(min: 2, max: 200)();
  TextColumn get supplierContact => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('piece'))(); // piece, bottle, box, etc.
  TextColumn get barcode => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Sales table
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiptNumber => text().unique()();
  RealColumn get totalAmount => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get finalAmount => real()();
  TextColumn get paymentMethod => text()(); // Cash, Mobile Money, Card
  TextColumn get customerName => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  IntColumn get cashierId => integer().references(Users, #id)();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();
}

// Sale items table
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get drugId => integer().references(Drugs, #id)();
  TextColumn get drugName => text()();
  TextColumn get batchNumber => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Stock movements table
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get drugId => integer().references(Drugs, #id)();
  TextColumn get movementType => text()(); // IN, OUT, ADJUSTMENT, EXPIRED
  IntColumn get quantity => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  TextColumn get reason => text().nullable()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get movementDate => dateTime().withDefault(currentDateAndTime)();
}

// Activity logs table
class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get module => text()(); // Sales, Inventory, Reports, Users, etc.
  TextColumn get details => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

// Settings table
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
  TextColumn get type => text()(); // string, int, double, bool, json
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [
  Users,
  DrugCategories,
  Drugs,
  Sales,
  SaleItems,
  StockMovements,
  ActivityLogs,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Helper method to hash passwords
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User operations
  Future<User> createUser(UsersCompanion user) {
    return into(users).insertReturning(user);
  }

  Future<User?> getUserByUsername(String username) {
    return (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();
  }

  Future<User?> authenticateUser(String username, String password) async {
    final hashedPassword = hashPassword(password);
    final user = await (select(users)
      ..where((u) => u.username.equals(username) & u.password.equals(hashedPassword) & u.isActive.equals(true)))
      .getSingleOrNull();
    
    if (user != null) {
      // Update last login
      await (update(users)..where((u) => u.id.equals(user.id)))
        .write(UsersCompanion(lastLogin: Value(DateTime.now())));
    }
    
    return user;
  }

  Stream<List<User>> watchAllUsers() {
    return select(users).watch();
  }

  // Drug operations
  Future<Drug> createDrug(DrugsCompanion drug) {
    return into(drugs).insertReturning(drug);
  }

  Future<bool> updateDrug(DrugsCompanion drug, int id) async {
    final result = await (update(drugs)..where((d) => d.id.equals(id)))
      .write(drug.copyWith(updatedAt: Value(DateTime.now())));
    return result > 0;
  }

  Future<int> deleteDrug(int id) {
    return (delete(drugs)..where((d) => d.id.equals(id))).go();
  }

  Stream<List<Drug>> watchAllDrugs() {
    return select(drugs).watch();
  }

  Stream<List<Drug>> watchLowStockDrugs(int threshold) {
    return (select(drugs)..where((d) => d.quantity.isSmallerOrEqualValue(threshold)))
      .watch();
  }

  Stream<List<Drug>> watchExpiringDrugs(int days) {
    final expiryDate = DateTime.now().add(Duration(days: days));
    return (select(drugs)..where((d) => d.expiryDate.isSmallerOrEqualValue(expiryDate)))
      .watch();
  }

  Future<Drug?> getDrugById(int id) {
    return (select(drugs)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  // Category operations
  Future<DrugCategory> createCategory(DrugCategoriesCompanion category) {
    return into(drugCategories).insertReturning(category);
  }

  Stream<List<DrugCategory>> watchAllCategories() {
    return select(drugCategories).watch();
  }

  // Sales operations
  Future<Sale> createSale(SalesCompanion sale) {
    return into(sales).insertReturning(sale);
  }

  Future<SaleItem> addSaleItem(SaleItemsCompanion item) {
    return into(saleItems).insertReturning(item);
  }

  Future<void> completeSale(int saleId, List<SaleItemsCompanion> items) async {
    await transaction(() async {
      // Add sale items
      for (var item in items) {
        await into(saleItems).insert(item);
        
        // Update drug stock
        final drug = await getDrugById(item.drugId.value);
        if (drug != null) {
          final newQuantity = drug.quantity - item.quantity.value;
          await (update(drugs)..where((d) => d.id.equals(drug.id)))
            .write(DrugsCompanion(
              quantity: Value(newQuantity),
              updatedAt: Value(DateTime.now()),
            ));
          
          // Record stock movement
          await into(stockMovements).insert(StockMovementsCompanion(
            drugId: Value(drug.id),
            movementType: const Value('OUT'),
            quantity: Value(item.quantity.value),
            previousStock: Value(drug.quantity),
            newStock: Value(newQuantity),
            reason: Value('Sale #$saleId'),
            userId: const Value(1), // This should be the current user ID
          ));
        }
      }
    });
  }

  Stream<List<Sale>> watchTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return (select(sales)
      ..where((s) => s.saleDate.isBetweenValues(startOfDay, endOfDay) & s.isCancelled.equals(false)))
      .watch();
  }

  Future<double> getTodayTotalSales() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await (select(sales)
      ..where((s) => s.saleDate.isBetweenValues(startOfDay, endOfDay) & s.isCancelled.equals(false)))
      .get();
    
    double total = 0;
    for (var sale in result) {
      total += sale.finalAmount;
    }
    return total;
  }

  // Stock movement operations
  Future<void> recordStockMovement(StockMovementsCompanion movement) {
    return into(stockMovements).insert(movement);
  }

  Stream<List<StockMovement>> watchStockMovements() {
    return (select(stockMovements)..orderBy([(t) => OrderingTerm.desc(t.movementDate)]))
      .watch();
  }

  // Activity log operations
  Future<void> logActivity(ActivityLogsCompanion log) {
    return into(activityLogs).insert(log);
  }

  Stream<List<ActivityLog>> watchActivityLogs() {
    return (select(activityLogs)..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
      .watch();
  }

  // Settings operations
  Future<void> setSetting(String key, String value, String type) async {
    final existing = await getSetting(key);
    if (existing != null) {
      await (update(settings)..where((s) => s.key.equals(key)))
        .write(SettingsCompanion(
          value: Value(value),
          type: Value(type),
          updatedAt: Value(DateTime.now()),
        ));
    } else {
      await into(settings).insert(SettingsCompanion(
        key: Value(key),
        value: Value(value),
        type: Value(type),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<Setting?> getSetting(String key) {
    return (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
  }

  // Initialize default data
  Future<void> initializeDefaultData() async {
    // Check if admin user exists
    final adminExists = await getUserByUsername('admin');
    if (adminExists == null) {
      // Create default admin user
      await createUser(UsersCompanion(
        username: const Value('admin'),
        password: Value(hashPassword('admin123')),
        fullName: const Value('System Administrator'),
        email: const Value('admin@tafowegpharmacy.com'),
        phone: const Value('+256700000000'),
        role: const Value('Admin'),
        isActive: const Value(true),
      ));
    }

    // Create default categories
    final categories = [
      'Antibiotics',
      'Analgesics',
      'Chronic Care',
      'Hormonal',
      'Vitamins & Supplements',
      'First Aid',
      'Skin Care',
      'Respiratory',
      'Digestive',
      'Cardiovascular',
    ];

    for (var categoryName in categories) {
      final exists = await (select(drugCategories)..where((c) => c.name.equals(categoryName))).getSingleOrNull();
      if (exists == null) {
        await createCategory(DrugCategoriesCompanion(
          name: Value(categoryName),
          description: Value('$categoryName medicines'),
        ));
      }
    }

    // Initialize default settings
    await setSetting('currency', 'UGX', 'string');
    await setSetting('lowStockThreshold', '10', 'int');
    await setSetting('expiryWarningDays', '30', 'int');
    await setSetting('companyName', 'Tafoweg Pharmacy Ltd', 'string');
    await setSetting('companyAddress', 'Kampala, Uganda', 'string');
    await setSetting('companyPhone', '+256 XXX XXX XXX', 'string');
    await setSetting('companyEmail', 'info@tafowegpharmacy.com', 'string');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tafoweg_pharmacy.db'));
    return NativeDatabase.createInBackground(file);
  });
}
