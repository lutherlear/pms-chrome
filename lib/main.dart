import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'database/app_database.dart';
import 'services/auth_service.dart';
import 'config/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'views/inventory/inventory_screen.dart';
import 'views/sales/sales_screen.dart';
import 'views/reports/reports_screen.dart';
import 'views/users/users_screen.dart';
import 'views/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for desktop
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  
  // Initialize database
  final database = AppDatabase();
  await database.initializeDefaultData();
  await _createDefaultUsers(database);
  
  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider(
          create: (context) => AuthService(database),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _createDefaultUsers(AppDatabase database) async {
  try {
    // Check if users already exist
    final users = await database.select(database.users).get();
    
    if (users.isEmpty) {
      // Create Admin user
      await database.createUser(UsersCompanion(
        username: const drift.Value('admin'),
        password: drift.Value(AppDatabase.hashPassword('admin123')),
        fullName: const drift.Value('System Administrator'),
        email: const drift.Value('admin@tafoweg.com'),
        phone: const drift.Value('+233240000001'),
        role: const drift.Value('Admin'),
        isActive: const drift.Value(true),
      ));
      
      // Create Cashier user
      await database.createUser(UsersCompanion(
        username: const drift.Value('cashier'),
        password: drift.Value(AppDatabase.hashPassword('cashier123')),
        fullName: const drift.Value('John Cashier'),
        email: const drift.Value('cashier@tafoweg.com'),
        phone: const drift.Value('+233240000002'),
        role: const drift.Value('Cashier'),
        isActive: const drift.Value(true),
      ));
      
      // Create Stock Manager user
      await database.createUser(UsersCompanion(
        username: const drift.Value('stockmanager'),
        password: drift.Value(AppDatabase.hashPassword('stock123')),
        fullName: const drift.Value('Jane Stock Manager'),
        email: const drift.Value('stock@tafoweg.com'),
        phone: const drift.Value('+233240000003'),
        role: const drift.Value('Stock Manager'),
        isActive: const drift.Value(true),
      ));
      
      print('✅ Default users created successfully');
      print('----------------------------------------');
      print('Admin Login: admin / admin123');
      print('Cashier Login: cashier / cashier123');
      print('Stock Manager Login: stockmanager / stock123');
      print('----------------------------------------');
    } else {
      // Check if we need to add missing roles
      final hasAdmin = users.any((u) => u.role == 'Admin');
      final hasCashier = users.any((u) => u.role == 'Cashier');
      final hasStockManager = users.any((u) => u.role == 'Stock Manager');
      
      if (!hasCashier) {
        await database.createUser(UsersCompanion(
          username: const drift.Value('cashier'),
          password: drift.Value(AppDatabase.hashPassword('cashier123')),
          fullName: const drift.Value('John Cashier'),
          email: const drift.Value('cashier@tafoweg.com'),
          phone: const drift.Value('+233240000002'),
          role: const drift.Value('Cashier'),
          isActive: const drift.Value(true),
        ));
        print('✅ Cashier user created: cashier / cashier123');
      }
      
      if (!hasStockManager) {
        await database.createUser(UsersCompanion(
          username: const drift.Value('stockmanager'),
          password: drift.Value(AppDatabase.hashPassword('stock123')),
          fullName: const drift.Value('Jane Stock Manager'),
          email: const drift.Value('stock@tafoweg.com'),
          phone: const drift.Value('+233240000003'),
          role: const drift.Value('Stock Manager'),
          isActive: const drift.Value(true),
        ));
        print('✅ Stock Manager user created: stockmanager / stock123');
      }
    }
  } catch (e) {
    print('Error creating default users: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tafoweg Pharmacy Management System',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/sales': (context) => const SalesScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/users': (context) => const UsersScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = context.read<AuthService>();
    await authService.checkAuthState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
