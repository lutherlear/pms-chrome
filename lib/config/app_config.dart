class AppConfig {
  static const String appName = 'Tafoweg Pharmacy Management System';
  static const String companyName = 'Tafoweg Pharmacy Ltd';
  static const String companyAddress = 'Kampala, Uganda';
  static const String companyPhone = '+256 XXX XXX XXX';
  static const String companyEmail = 'info@tafowegpharmacy.com';
  
  // Currency
  static const String currency = 'UGX';
  static const String currencySymbol = 'UGX ';
  
  // Stock thresholds
  static const int lowStockThreshold = 10;
  static const int expiryWarningDays = 30;
  
  // Database
  static const String databaseName = 'tafoweg_pharmacy.db';
  static const int databaseVersion = 1;
  
  // Receipt settings
  static const String receiptHeader = 'TAFOWEG PHARMACY LTD';
  static const String receiptFooter = 'Thank you for choosing Tafoweg Pharmacy!';
  
  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Pagination
  static const int itemsPerPage = 20;
}
