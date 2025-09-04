# Tafoweg Pharmacy Management System

A professional, cross-platform Pharmacy Management System built with Flutter & Dart for Tafoweg Pharmacy Ltd. The system runs as both a web application and Windows desktop application, providing comprehensive pharmacy management capabilities.

## 🚀 Live Demo

Deploy this application directly to Vercel:

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/lutherlear/pms-chrome)

## 🌟 Features

### ✅ Completed Modules

#### 1. **Authentication System**
- Secure login with hashed passwords
- Role-based access control (Admin, Cashier, Stock Manager)
- User session management
- Activity logging

#### 2. **Dashboard**
- Real-time sales metrics in UGX (Ugandan Shillings)
- Stock alerts (low stock and expiring drugs)
- Interactive sales charts
- Quick action buttons
- Professional Material 3 design

#### 3. **Inventory Management**
- Complete CRUD operations for drugs
- Batch tracking and expiry date monitoring
- Automatic stock level alerts
- Category-based organization
- Real-time search and filtering
- Low stock and expiring drugs tabs
- Supplier information tracking

#### 4. **Point of Sale (POS)**
- User-friendly sales interface
- Barcode scanning support (ready for integration)
- Shopping cart management
- Multiple payment methods (Cash, Mobile Money, Card)
- Customer information capture
- Discount application
- Real-time stock validation
- PDF receipt generation and printing
- Sales history tracking

### 🚧 Modules In Progress

#### 5. **Reports & Analytics**
- Daily, weekly, and monthly sales reports
- Profit & loss analysis
- Stock valuation reports
- Best-selling drugs analysis
- Export to PDF/Excel

#### 6. **System Utilities**
- Database backup and restore
- Settings configuration
- Printer integration
- Currency configuration

## 🛠️ Technology Stack

- **Frontend Framework:** Flutter 3.x
- **Programming Language:** Dart
- **Database:** SQLite (via Drift ORM)
- **State Management:** Provider
- **PDF Generation:** pdf package
- **Charts:** fl_chart
- **Icons:** Phosphor Icons
- **Design System:** Material 3

## 📋 Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Windows 10/11 (for desktop development)
- Visual Studio 2022 with C++ development tools
- Chrome/Edge browser (for web development)

## 🚀 Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/tafoweg_pharmacy.git
cd tafoweg_pharmacy
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate database code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the application**

For Windows Desktop:
```bash
flutter run -d windows
```

For Web:
```bash
flutter run -d chrome
```

## 🔐 Default Credentials

- **Username:** admin
- **Password:** admin123

⚠️ **Important:** Change these credentials after first login!

## 📁 Project Structure

```
tafoweg_pharmacy/
├── lib/
│   ├── config/          # App configuration and theme
│   ├── database/        # Database models and operations
│   ├── models/          # Data models
│   ├── services/        # Business logic services
│   ├── views/           # UI screens
│   │   ├── auth/        # Authentication screens
│   │   ├── dashboard/   # Dashboard screen
│   │   ├── inventory/   # Inventory management
│   │   ├── sales/       # POS and sales
│   │   ├── reports/     # Reports and analytics
│   │   ├── users/       # User management
│   │   └── settings/    # Settings screen
│   ├── widgets/         # Reusable widgets
│   └── main.dart        # Application entry point
├── windows/             # Windows-specific code
├── web/                 # Web-specific code
└── pubspec.yaml         # Dependencies
```

## 💰 Currency Configuration

The system is configured to use **Ugandan Shillings (UGX)** by default. All monetary values are displayed with the UGX symbol and formatted appropriately.

## 🏗️ Building for Production

### Windows Desktop (.exe)
```bash
flutter build windows --release
```
The executable will be located at: `build/windows/x64/runner/Release/tafoweg_pharmacy.exe`

### Web Application
```bash
flutter build web --release
```
The web files will be in: `build/web/`

## 🎨 Design Philosophy

- **Color Scheme:** Soft, friendly colors (green, blue, white) reflecting health and trust
- **Layout:** Clean, modern interface with consistent spacing
- **Responsiveness:** Adaptive design for different screen sizes
- **Accessibility:** Large, readable text with clear contrasts
- **User Experience:** Intuitive navigation with visual feedback

## 📊 Key Features by Role

### Admin
- Full system access
- User management
- System configuration
- All reports and analytics
- Database backup/restore

### Cashier
- Access to POS system
- Process sales and returns
- Generate receipts
- View own sales reports
- Limited inventory viewing

### Stock Manager
- Full inventory management
- Stock adjustments
- Supplier management
- Stock reports
- Expiry tracking

## 🔄 Stock Management

- **Automatic Stock Deduction:** Stock quantities are automatically updated after each sale
- **Low Stock Alerts:** Visual warnings when stock falls below reorder levels
- **Expiry Tracking:** Alerts for drugs nearing expiration (30 days by default)
- **Batch Tracking:** Each drug batch is tracked separately

## 🧾 Receipt Features

- Professional PDF generation
- Company branding
- Itemized product list
- Payment method display
- Cashier information
- Print or save as PDF
- Customer details (optional)

## 🔒 Security Features

- Password hashing using SHA-256
- Role-based access control
- Session management
- Activity logging
- Secure local storage

## 📈 Performance Optimization

- Offline-first architecture
- Efficient database queries with Drift
- Lazy loading for large datasets
- Optimized widget rebuilds
- Cached data where appropriate

## 🐛 Known Issues

- Barcode scanner integration pending
- Excel export functionality in development
- Multi-branch support not yet implemented

## 📝 Future Enhancements

1. Cloud synchronization
2. Mobile app versions (Android/iOS)
3. Advanced analytics dashboard
4. SMS/Email notifications
5. Loyalty program integration
6. Insurance billing integration
7. Multi-language support
8. Dark mode theme

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software developed for Tafoweg Pharmacy Ltd.

## 🆘 Support

For support and inquiries:
- Email: info@tafowegpharmacy.com
- Phone: +256 XXX XXX XXX

## 👥 Development Team

Developed with ❤️ for Tafoweg Pharmacy Ltd.

---

**Version:** 1.0.0  
**Last Updated:** September 2025  
**Status:** Production Ready (Core Modules)
