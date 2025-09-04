class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and special characters
    final cleanedNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's a valid phone number (10-15 digits)
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleanedNumber)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    // Optional: Add more complex password requirements
    // if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
    //   return 'Password must contain uppercase, lowercase, and numbers';
    // }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, {
    String fieldName = 'Number',
    double? min,
    double? max,
    bool allowDecimals = true,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = allowDecimals 
        ? double.tryParse(value) 
        : int.tryParse(value)?.toDouble();
    
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    final result = validateNumber(value, fieldName: fieldName, min: 0);
    if (result != null) return result;
    
    final number = double.tryParse(value!);
    if (number == 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(DateTime? date, {
    String fieldName = 'Date',
    DateTime? minDate,
    DateTime? maxDate,
    bool allowPast = true,
    bool allowFuture = true,
  }) {
    if (date == null) {
      return '$fieldName is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    if (!allowPast && selectedDate.isBefore(today)) {
      return '$fieldName cannot be in the past';
    }
    
    if (!allowFuture && selectedDate.isAfter(today)) {
      return '$fieldName cannot be in the future';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return '$fieldName cannot be before ${_formatDate(minDate)}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return '$fieldName cannot be after ${_formatDate(maxDate)}';
    }
    
    return null;
  }

  // Expiry date validation
  static String? validateExpiryDate(DateTime? date) {
    if (date == null) {
      return 'Expiry date is required';
    }
    
    final now = DateTime.now();
    final minimumExpiryDate = now.add(const Duration(days: 30)); // At least 30 days from now
    
    if (date.isBefore(minimumExpiryDate)) {
      return 'Expiry date must be at least 30 days from today';
    }
    
    return null;
  }

  // Batch number validation
  static String? validateBatchNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Batch number is required';
    }
    
    if (value.length < 3) {
      return 'Batch number must be at least 3 characters';
    }
    
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(value.toUpperCase())) {
      return 'Batch number can only contain letters, numbers, and hyphens';
    }
    
    return null;
  }

  // Currency validation
  static String? validateCurrency(String? value, {String fieldName = 'Amount'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    // Remove currency symbols and spaces
    final cleanedValue = value.replaceAll(RegExp(r'[^\d\.]'), '');
    
    final amount = double.tryParse(cleanedValue);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount < 0) {
      return '$fieldName cannot be negative';
    }
    
    // Check for more than 2 decimal places
    if (cleanedValue.contains('.')) {
      final parts = cleanedValue.split('.');
      if (parts.length > 1 && parts[1].length > 2) {
        return '$fieldName can have maximum 2 decimal places';
      }
    }
    
    return null;
  }

  // Percentage validation (0-100)
  static String? validatePercentage(String? value, {String fieldName = 'Percentage'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final percentage = double.tryParse(value);
    if (percentage == null) {
      return 'Please enter a valid percentage';
    }
    
    if (percentage < 0 || percentage > 100) {
      return '$fieldName must be between 0 and 100';
    }
    
    return null;
  }

  // Stock quantity validation
  static String? validateStockQuantity(String? value, {int? maxQuantity}) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid whole number';
    }
    
    if (quantity < 0) {
      return 'Quantity cannot be negative';
    }
    
    if (maxQuantity != null && quantity > maxQuantity) {
      return 'Quantity cannot exceed available stock ($maxQuantity)';
    }
    
    return null;
  }

  // Helper method to format date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Name validation (for drug names, customer names, etc.)
  static String? validateName(String? value, {
    String fieldName = 'Name',
    int minLength = 2,
    int maxLength = 100,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    // Allow letters, numbers, spaces, and common punctuation
    if (!RegExp(r"^[a-zA-Z0-9\s\-\.'&]+$").hasMatch(value)) {
      return '$fieldName contains invalid characters';
    }
    
    return null;
  }

  // TIN (Tax Identification Number) validation
  static String? validateTIN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // TIN is optional
    }
    
    // Basic format check for Ghana TIN (C + 10 digits)
    if (!RegExp(r'^[CP]\d{10}$').hasMatch(value.toUpperCase())) {
      return 'Invalid TIN format (e.g., C0001234567)';
    }
    
    return null;
  }
}
