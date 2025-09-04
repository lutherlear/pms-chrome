import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../config/app_theme.dart';
import '../../database/app_database.dart';
import '../../services/auth_service.dart';
import '../../widgets/sidebar_navigation.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String selectedRoute = '/users';
  final _searchController = TextEditingController();

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

    // Only Admin can access user management
    if (!authService.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.lockKey, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              const Text('Admin Access Only', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('User management is restricted to administrators'),
            ],
          ),
        ),
      );
    }

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
                        'User Management',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      
                      // Add User Button
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(context, db),
                        icon: const Icon(PhosphorIconsRegular.userPlus, size: 20),
                        label: const Text('Add User'),
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
                      Tab(text: 'Active Users', icon: Icon(PhosphorIconsRegular.users)),
                      Tab(text: 'Inactive Users', icon: Icon(PhosphorIconsRegular.userMinus)),
                      Tab(text: 'Roles & Permissions', icon: Icon(PhosphorIconsRegular.shieldCheck)),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name, username, or email...',
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

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActiveUsers(db),
                      _buildInactiveUsers(db),
                      _buildRolesPermissions(),
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

  Widget _buildActiveUsers(AppDatabase db) {
    return StreamBuilder<List<User>>(
      stream: db.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.where((u) => u.isActive).toList();

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          users = users.where((user) {
            return user.fullName.toLowerCase().contains(searchLower) ||
                   user.username.toLowerCase().contains(searchLower) ||
                   user.email.toLowerCase().contains(searchLower);
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.usersThree, size: 64, color: AppTheme.gray.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No active users found',
                  style: TextStyle(fontSize: 16, color: AppTheme.gray),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Full Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Last Login')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(user.username),
                          ],
                        ),
                      ),
                      DataCell(Text(user.fullName)),
                      DataCell(Text(user.email)),
                      DataCell(Text(user.phone)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          user.lastLogin != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!)
                              : 'Never',
                          style: TextStyle(
                            color: user.lastLogin != null ? AppTheme.black : AppTheme.gray,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.pencil, size: 18, color: AppTheme.primaryBlue),
                              onPressed: () => _showEditUserDialog(context, db, user),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.key, size: 18, color: AppTheme.warning),
                              onPressed: () => _showResetPasswordDialog(context, db, user),
                              tooltip: 'Reset Password',
                            ),
                            IconButton(
                              icon: Icon(PhosphorIconsRegular.prohibit, size: 18, color: AppTheme.error),
                              onPressed: () => _deactivateUser(context, db, user),
                              tooltip: 'Deactivate',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInactiveUsers(AppDatabase db) {
    return StreamBuilder<List<User>>(
      stream: db.watchAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data!.where((u) => !u.isActive).toList();

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          users = users.where((user) {
            return user.fullName.toLowerCase().contains(searchLower) ||
                   user.username.toLowerCase().contains(searchLower) ||
                   user.email.toLowerCase().contains(searchLower);
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsRegular.userMinus, size: 64, color: AppTheme.gray.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No inactive users',
                  style: TextStyle(fontSize: 16, color: AppTheme.gray),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Full Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Deactivated')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.gray,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(user.username, style: TextStyle(color: AppTheme.gray)),
                          ],
                        ),
                      ),
                      DataCell(Text(user.fullName, style: TextStyle(color: AppTheme.gray))),
                      DataCell(Text(user.email, style: TextStyle(color: AppTheme.gray))),
                      DataCell(Text(user.phone, style: TextStyle(color: AppTheme.gray))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gray.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              color: AppTheme.gray,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(user.createdAt))),
                      DataCell(
                        IconButton(
                          icon: Icon(PhosphorIconsRegular.checkCircle, size: 18, color: AppTheme.success),
                          onPressed: () => _activateUser(context, db, user),
                          tooltip: 'Reactivate',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRolesPermissions() {
    final roles = [
      {
        'name': 'Admin',
        'color': AppTheme.error,
        'icon': PhosphorIconsBold.crown,
        'permissions': [
          'Full system access',
          'User management',
          'System configuration',
          'Database backup/restore',
          'View all reports',
          'Manage all modules',
        ],
      },
      {
        'name': 'Cashier',
        'color': AppTheme.primaryGreen,
        'icon': PhosphorIconsBold.shoppingCart,
        'permissions': [
          'Process sales',
          'Generate receipts',
          'View own sales',
          'View inventory (read-only)',
          'Basic reports access',
        ],
      },
      {
        'name': 'Stock Manager',
        'color': AppTheme.primaryBlue,
        'icon': PhosphorIconsBold.package,
        'permissions': [
          'Manage inventory',
          'Add/edit/delete drugs',
          'Stock adjustments',
          'View stock reports',
          'Manage suppliers',
        ],
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Roles & Permissions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Define what each role can do in the system',
            style: TextStyle(color: AppTheme.gray),
          ),
          const SizedBox(height: 24),
          ...roles.map((role) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (role['color'] as Color).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (role['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    role['icon'] as IconData,
                    color: role['color'] as Color,
                    size: 24,
                  ),
                ),
                title: Text(
                  role['name'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${(role['permissions'] as List).length} permissions',
                  style: TextStyle(color: AppTheme.gray),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (role['permissions'] as List<String>).map((permission) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.checkCircle,
                                size: 18,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 8),
                              Text(permission),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, AppDatabase db) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Cashier';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(PhosphorIconsRegular.userPlus, color: AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  const Text('Add New User'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            prefixIcon: Icon(PhosphorIconsRegular.user),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password *',
                            prefixIcon: Icon(PhosphorIconsRegular.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(PhosphorIconsRegular.identificationCard),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: Icon(PhosphorIconsRegular.envelope),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone *',
                            prefixIcon: Icon(PhosphorIconsRegular.phone),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role *',
                            prefixIcon: Icon(PhosphorIconsRegular.shieldCheck),
                          ),
                          items: ['Admin', 'Cashier', 'Stock Manager'].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(role),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(role),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // Check if username exists
                        final existingUser = await db.getUserByUsername(usernameController.text);
                        if (existingUser != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Username already exists')),
                            );
                          }
                          return;
                        }

                        await db.createUser(UsersCompanion(
                          username: drift.Value(usernameController.text),
                          password: drift.Value(AppDatabase.hashPassword(passwordController.text)),
                          fullName: drift.Value(fullNameController.text),
                          email: drift.Value(emailController.text),
                          phone: drift.Value(phoneController.text),
                          role: drift.Value(selectedRole),
                          isActive: const drift.Value(true),
                        ));

                        // Log activity
                        final authService = context.read<AuthService>();
                        await db.logActivity(ActivityLogsCompanion(
                          userId: drift.Value(authService.currentUser!.id),
                          action: const drift.Value('Create User'),
                          module: const drift.Value('Users'),
                          details: drift.Value('Created user: ${usernameController.text} with role: $selectedRole'),
                        ));

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User created successfully'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating user: $e')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: AppTheme.white,
                  ),
                  child: const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, AppDatabase db, User user) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(PhosphorIconsRegular.pencil, color: AppTheme.primaryBlue),
                  const SizedBox(width: 12),
                  Text('Edit User: ${user.username}'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(PhosphorIconsRegular.identificationCard),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(PhosphorIconsRegular.envelope),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone *',
                          prefixIcon: Icon(PhosphorIconsRegular.phone),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          prefixIcon: Icon(PhosphorIconsRegular.shieldCheck),
                        ),
                        items: ['Admin', 'Cashier', 'Stock Manager'].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(role),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await (db.update(db.users)..where((u) => u.id.equals(user.id)))
                          .write(UsersCompanion(
                            fullName: drift.Value(fullNameController.text),
                            email: drift.Value(emailController.text),
                            phone: drift.Value(phoneController.text),
                            role: drift.Value(selectedRole),
                          ));

                        // Log activity
                        final authService = context.read<AuthService>();
                        await db.logActivity(ActivityLogsCompanion(
                          userId: drift.Value(authService.currentUser!.id),
                          action: const drift.Value('Update User'),
                          module: const drift.Value('Users'),
                          details: drift.Value('Updated user: ${user.username}'),
                        ));

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User updated successfully'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating user: $e')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: AppTheme.white,
                  ),
                  child: const Text('Update User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppDatabase db, User user) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(PhosphorIconsRegular.key, color: AppTheme.warning),
              const SizedBox(width: 12),
              Text('Reset Password: ${user.username}'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password *',
                      prefixIcon: Icon(PhosphorIconsRegular.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password *',
                      prefixIcon: Icon(PhosphorIconsRegular.lockKey),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await (db.update(db.users)..where((u) => u.id.equals(user.id)))
                      .write(UsersCompanion(
                        password: drift.Value(AppDatabase.hashPassword(passwordController.text)),
                      ));

                    // Log activity
                    final authService = context.read<AuthService>();
                    await db.logActivity(ActivityLogsCompanion(
                      userId: drift.Value(authService.currentUser!.id),
                      action: const drift.Value('Reset Password'),
                      module: const drift.Value('Users'),
                      details: drift.Value('Reset password for user: ${user.username}'),
                    ));

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset successfully'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error resetting password: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );
  }

  void _deactivateUser(BuildContext context, AppDatabase db, User user) {
    // Prevent deactivating self
    final authService = context.read<AuthService>();
    if (user.id == authService.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot deactivate your own account')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to deactivate ${user.username}?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.warning, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'The user will not be able to login until reactivated.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await (db.update(db.users)..where((u) => u.id.equals(user.id)))
                    .write(const UsersCompanion(isActive: drift.Value(false)));

                  // Log activity
                  await db.logActivity(ActivityLogsCompanion(
                    userId: drift.Value(authService.currentUser!.id),
                    action: const drift.Value('Deactivate User'),
                    module: const drift.Value('Users'),
                    details: drift.Value('Deactivated user: ${user.username}'),
                  ));

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User deactivated'),
                        backgroundColor: AppTheme.warning,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deactivating user: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );
  }

  void _activateUser(BuildContext context, AppDatabase db, User user) async {
    try {
      await (db.update(db.users)..where((u) => u.id.equals(user.id)))
        .write(const UsersCompanion(isActive: drift.Value(true)));

      // Log activity
      final authService = context.read<AuthService>();
      await db.logActivity(ActivityLogsCompanion(
        userId: drift.Value(authService.currentUser!.id),
        action: const drift.Value('Activate User'),
        module: const drift.Value('Users'),
        details: drift.Value('Reactivated user: ${user.username}'),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User reactivated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error activating user: $e')),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return AppTheme.error;
      case 'Cashier':
        return AppTheme.primaryGreen;
      case 'Stock Manager':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.gray;
    }
  }
}
