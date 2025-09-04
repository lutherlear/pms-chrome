import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyCompanyName = 'company_name';
  static const String _keyAddress = 'company_address';
  static const String _keyPhone = 'company_phone';
  static const String _keyEmail = 'company_email';
  static const String _keyTin = 'company_tin';
  static const String _keyRegistration = 'company_registration';
  static const String _keySlogan = 'company_slogan';
  static const String _keyCurrency = 'currency';
  static const String _keyDateFormat = 'date_format';
  static const String _keyTheme = 'theme';
  static const String _keyNotifications = 'notifications';
  static const String _keyAutoBackup = 'auto_backup';
  static const String _keyBackupFrequency = 'backup_frequency';
  static const String _keyPrintLogo = 'print_logo';
  static const String _keyPrintSlogan = 'print_slogan';
  static const String _keyPrintTin = 'print_tin';
  static const String _keyReceiptFooter = 'receipt_footer';
  
  static Future<void> saveCompanySettings({
    required String companyName,
    required String address,
    required String phone,
    required String email,
    String? tin,
    String? registration,
    String? slogan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompanyName, companyName);
    await prefs.setString(_keyAddress, address);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyEmail, email);
    if (tin != null) await prefs.setString(_keyTin, tin);
    if (registration != null) await prefs.setString(_keyRegistration, registration);
    if (slogan != null) await prefs.setString(_keySlogan, slogan);
  }
  
  static Future<Map<String, String>> getCompanySettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'companyName': prefs.getString(_keyCompanyName) ?? 'Tafoweg Pharmacy',
      'address': prefs.getString(_keyAddress) ?? 'P.O. Box 123, Kampala, Uganda',
      'phone': prefs.getString(_keyPhone) ?? '+256 700 123 456',
      'email': prefs.getString(_keyEmail) ?? 'info@tafowegpharmacy.com',
      'tin': prefs.getString(_keyTin) ?? 'UG1234567890',
      'registration': prefs.getString(_keyRegistration) ?? 'BN123456789',
      'slogan': prefs.getString(_keySlogan) ?? 'Your Health, Our Priority',
    };
  }
  
  static Future<void> saveSystemSettings({
    required String currency,
    required String dateFormat,
    required String theme,
    required bool notifications,
    required bool autoBackup,
    required int backupFrequency,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
    await prefs.setString(_keyDateFormat, dateFormat);
    await prefs.setString(_keyTheme, theme);
    await prefs.setBool(_keyNotifications, notifications);
    await prefs.setBool(_keyAutoBackup, autoBackup);
    await prefs.setInt(_keyBackupFrequency, backupFrequency);
  }
  
  static Future<Map<String, dynamic>> getSystemSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'currency': prefs.getString(_keyCurrency) ?? 'UGX',
      'dateFormat': prefs.getString(_keyDateFormat) ?? 'DD/MM/YYYY',
      'theme': prefs.getString(_keyTheme) ?? 'Light',
      'notifications': prefs.getBool(_keyNotifications) ?? true,
      'autoBackup': prefs.getBool(_keyAutoBackup) ?? false,
      'backupFrequency': prefs.getInt(_keyBackupFrequency) ?? 7,
    };
  }
  
  static Future<void> saveReceiptSettings({
    required bool printLogo,
    required bool printSlogan,
    required bool printTin,
    required String receiptFooter,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrintLogo, printLogo);
    await prefs.setBool(_keyPrintSlogan, printSlogan);
    await prefs.setBool(_keyPrintTin, printTin);
    await prefs.setString(_keyReceiptFooter, receiptFooter);
  }
  
  static Future<Map<String, dynamic>> getReceiptSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'printLogo': prefs.getBool(_keyPrintLogo) ?? true,
      'printSlogan': prefs.getBool(_keyPrintSlogan) ?? true,
      'printTin': prefs.getBool(_keyPrintTin) ?? false,
      'receiptFooter': prefs.getString(_keyReceiptFooter) ?? 'Thank you for your purchase!',
    };
  }
  
  static Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(_keyCurrency) ?? 'UGX';
    
    switch (currency) {
      case 'UGX':
        return 'UGX ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'GHS':
        return 'GH₵';
      case 'NGN':
        return '₦';
      case 'KES':
        return 'KSh ';
      case 'TZS':
        return 'TSh ';
      default:
        return currency + ' ';
    }
  }
}
