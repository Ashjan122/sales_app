import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<User> users = [];
  List<User> filteredUsers = [];
  List<Role> roles = [];
  List<Warehouse> warehouses = [];
  bool isLoading = false;
  int page = 1;
  final int perPage = 15;
  final Color primaryColor = const Color(0xFF213D5C);
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String username = '';
  String password = '';
  String confirmPassword = '';
  int? selectedWarehouseId;
  List<int> selectedRoleIds = [];

  @override
  void initState() {
    super.initState();
    fetchRoles();
    fetchWarehouses();
    fetchUsers();
  }

  Future<void> fetchRoles() async {
    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/roles',
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final List data = response.data['data'];
      roles = data.map((e) => Role.fromJson(e)).toList();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }
  }

  Future<void> fetchWarehouses() async {
    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/warehouses',
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final List data = response.data['data'];
      warehouses = data.map((e) => Warehouse.fromJson(e)).toList();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
    }
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/users',
        queryParameters: {'page': page, 'per_page': perPage},
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final List data = response.data['data'];
      users = data.map((e) => User.fromJson(e)).toList();
      filteredUsers = users;
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> addUser() async {
    try {
      final token = await AuthService.getToken();
      final response = await Dio().post(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/users',
        data: {
          'name': name,
          'username': username,
          'password': password,
          'warehouse_id': selectedWarehouseId,
          'roles': selectedRoleIds,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المستخدم بنجاح')),
        );
      }
    } catch (e) {
      debugPrint('Error adding user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إضافة المستخدم')),
      );
    }
  }

  void showAddUserDialog() {
    selectedWarehouseId = null;
    selectedRoleIds = [];
    password = '';
    confirmPassword = '';
    name = '';
    username = '';

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('إضافة مستخدم جديد'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (val) => name = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'الرجاء إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'اسم الدخول',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (val) => username = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'الرجاء إدخال اسم الدخول' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    DropdownButtonFormField<int>(
                      value: selectedWarehouseId,
                      decoration: const InputDecoration(
                        labelText: 'المستودع الرئيسي',
                        border: OutlineInputBorder(),
                      ),
                      items: warehouses
                          .map((w) => DropdownMenuItem<int>(
                                value: w.id,
                                child: Text(w.name),
                              ))
                          .toList(),
                      onChanged: (val) => setStateDialog(() => selectedWarehouseId = val),
                      validator: (val) =>
                          val == null ? 'الرجاء اختيار المستودع' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onSaved: (val) => password = val!.trim(),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      onSaved: (val) => confirmPassword = val!.trim(),
                      validator: (val) =>
                          val != password ? 'كلمة المرور غير متطابقة' : null,
                    ),
                    const SizedBox(height: 8),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Text(
                        'تعيين الأدوار',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: roles.map((role) {
                        final isSelected = selectedRoleIds.contains(role.id);
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width / 2) - 64,
                          child: CheckboxListTile(
                            value: isSelected,
                            title: Text(role.name),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  selectedRoleIds.add(role.id);
                                } else {
                                  selectedRoleIds.remove(role.id);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('كلمة المرور غير متطابقة')));
                      return;
                    }
                    addUser();
                    Navigator.pop(context);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمين', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddUserDialog,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'بحث باسم المستخدم أو اسم الدخول',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    filteredUsers = users.where((user) {
                      final nameLower = user.name.toLowerCase();
                      final usernameLower = user.username.toLowerCase();
                      final searchLower = value.toLowerCase();
                      return nameLower.contains(searchLower) ||
                          usernameLower.contains(searchLower);
                    }).toList();
                  });
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? const Center(child: Text('لا يوجد مستخدمين'))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final roleNames =
                                user.roles.isNotEmpty ? user.roles.join(', ') : 'غير محدد';
                            final warehouseName = user.warehouse ?? 'غير محدد';
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                              'اسم الدخول: ${user.username.isEmpty ? 'غير محدد' : user.username}'),
                                        ),
                                        Expanded(child: Text('الدور: $roleNames')),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('المستودع: $warehouseName'),
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
    );
  }
}


class User {
  final int id;
  final String name;
  final String username;
  final int? warehouseId;
  final String? warehouse;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    required this.username,
    this.warehouseId,
    this.warehouse,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'] ?? '',
      warehouseId: json['warehouse_id'],
      warehouse: json['warehouse']?['name'],
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}

class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Warehouse {
  final int id;
  final String name;

  Warehouse({required this.id, required this.name});

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      name: json['name'],
    );
  }
}
