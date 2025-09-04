import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class AuthService extends ChangeNotifier {
  final AppDatabase _db;
  User? _currentUser;
  bool _isAuthenticated = false;

  AuthService(this._db);

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  
  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isCashier => _currentUser?.role == 'Cashier';
  bool get isStockManager => _currentUser?.role == 'Stock Manager';

  Future<bool> login(String username, String password) async {
    try {
      final user = await _db.authenticateUser(username, password);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id);
        await prefs.setString('username', user.username);
        await prefs.setString('role', user.role);
        
        // Log activity
        await _db.logActivity(ActivityLogsCompanion(
          userId: drift.Value(user.id),
          action: const drift.Value('Login'),
          module: const drift.Value('Authentication'),
          details: drift.Value('User ${user.username} logged in'),
        ));
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      // Log activity
      await _db.logActivity(ActivityLogsCompanion(
        userId: drift.Value(_currentUser!.id),
        action: const drift.Value('Logout'),
        module: const drift.Value('Authentication'),
        details: drift.Value('User ${_currentUser!.username} logged out'),
      ));
    }
    
    _currentUser = null;
    _isAuthenticated = false;
    
    // Clear saved login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    
    if (userId != null) {
      final users = await _db.select(_db.users).get();
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse: () => throw Exception('User not found'),
      );
      
      if (user.isActive) {
        _currentUser = user;
        _isAuthenticated = true;
        notifyListeners();
      }
    }
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    
    switch (_currentUser!.role) {
      case 'Admin':
        return true; // Admin has all permissions
      case 'Cashier':
        return ['sales', 'view_inventory', 'view_reports'].contains(permission);
      case 'Stock Manager':
        return ['inventory', 'view_sales', 'view_reports'].contains(permission);
      default:
        return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;
    
    try {
      final hashedOldPassword = AppDatabase.hashPassword(oldPassword);
      
      if (_currentUser!.password == hashedOldPassword) {
        final hashedNewPassword = AppDatabase.hashPassword(newPassword);
        
        await (_db.update(_db.users)..where((u) => u.id.equals(_currentUser!.id)))
          .write(UsersCompanion(
            password: drift.Value(hashedNewPassword),
          ));
        
        // Log activity
        await _db.logActivity(ActivityLogsCompanion(
          userId: drift.Value(_currentUser!.id),
          action: const drift.Value('Password Change'),
          module: const drift.Value('Authentication'),
          details: drift.Value('User ${_currentUser!.username} changed password'),
        ));
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Password change error: $e');
      return false;
    }
  }
}
