# Tafoweg Pharmacy Management System - Login Credentials

## 🔐 Default User Accounts

The system comes with three default user accounts, each with different roles and permissions:

### 1. **Administrator Account**
- **Username:** `admin`
- **Password:** `admin123`
- **Role:** Admin
- **Permissions:**
  - ✅ Full system access
  - ✅ User management
  - ✅ System configuration
  - ✅ Database backup/restore
  - ✅ View all reports
  - ✅ Manage all modules

### 2. **Cashier Account**
- **Username:** `cashier`
- **Password:** `cashier123`
- **Role:** Cashier
- **Permissions:**
  - ✅ Process sales
  - ✅ Generate receipts
  - ✅ View own sales
  - ✅ View inventory (read-only)
  - ✅ Basic reports access
  - ❌ Cannot manage users
  - ❌ Cannot access settings

### 3. **Stock Manager Account**
- **Username:** `stockmanager`
- **Password:** `stock123`
- **Role:** Stock Manager
- **Permissions:**
  - ✅ Manage inventory
  - ✅ Add/edit/delete drugs
  - ✅ Stock adjustments
  - ✅ View stock reports
  - ✅ Manage suppliers
  - ❌ Cannot process sales
  - ❌ Cannot manage users

## 📱 How to Test Different Roles

1. **Start the application:** `flutter run -d windows`

2. **Login with different accounts** to see role-based features:
   - Admin sees all modules
   - Cashier sees Dashboard and Sales modules
   - Stock Manager sees Dashboard and Inventory modules

3. **Test role restrictions:**
   - Try accessing Users menu as Cashier (should be hidden)
   - Try accessing Settings as Stock Manager (should be hidden)
   - Try accessing Reports as non-Admin user (should show access denied)

## 🔄 Changing Passwords

After first login, it's recommended to change the default passwords:
1. Login as Admin
2. Go to Users module
3. Click on Reset Password for each user
4. Set new secure passwords

## 🆕 Creating New Users

As an Admin, you can create additional users:
1. Login as Admin
2. Navigate to Users module
3. Click "Add User" button
4. Fill in user details and assign appropriate role
5. User can login with the credentials you set

## 🛡️ Security Notes

- Default passwords should be changed immediately in production
- Passwords are hashed using SHA-256 before storage
- Users can be deactivated without deletion
- All actions are logged in the activity log

## 📊 Role-Based Dashboard

Each role sees different statistics on the dashboard:
- **Admin:** Complete overview of all metrics
- **Cashier:** Sales-focused metrics
- **Stock Manager:** Inventory-focused metrics

## ⚠️ Important Notes

- These are development/demo credentials
- For production use, ensure to:
  - Change all default passwords
  - Implement stronger password policies
  - Enable two-factor authentication (if implemented)
  - Regular password rotation policies
