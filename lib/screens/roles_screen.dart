import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({super.key});

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  List<Role> roles = [];
  bool isLoading = false;
  int page = 1;
  final int perPage = 15;

  final Color primaryColor = const Color(0xFF213D5C);

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  // ================= GET ROLES =================
  Future<void> fetchRoles() async {
    setState(() => isLoading = true);

    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/roles',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      final List data = response.data['data'];
      roles = data.map((e) => Role.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading roles: $e');
    }

    setState(() => isLoading = false);
  }

  // ================= ADD ROLE DIALOG =================
  void showAddRoleDialog() {
    final TextEditingController roleNameController = TextEditingController();
    List<Permission> permissions = [];
    Set<String> selectedPermissions = {};
    bool loadingPermissions = true;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> loadPermissions() async {
                try {
                  final token = await AuthService.getToken();
                  final response = await Dio().get(
                    '${ApiConfig.baseUrl}/sales-api/public/api/admin/permissions',
                    options: Options(headers: {
                      'Accept': 'application/json',
                      if (token != null)
                        'Authorization': 'Bearer $token',
                    }),
                  );

                  permissions = (response.data['data'] as List)
                      .map((e) => Permission.fromJson(e))
                      .toList();
                } catch (e) {
                  debugPrint(e.toString());
                }
                setDialogState(() => loadingPermissions = false);
              }

              if (loadingPermissions) loadPermissions();

              return AlertDialog(
                title: const Text('إضافة دور جديد'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      TextField(
                        controller: roleNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الدور',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تعيين الصلاحيات',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: loadingPermissions
                            ? const Center(
                                child: CircularProgressIndicator())
                            : ListView(
                                children: permissions.map((permission) {
                                  return CheckboxListTile(
                                    title: Text(permission.name),
                                    value: selectedPermissions
                                        .contains(permission.name),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selectedPermissions
                                              .add(permission.name);
                                        } else {
                                          selectedPermissions
                                              .remove(permission.name);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    child: const Text(
                      'حفظ',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      await createRole(
                        roleNameController.text,
                        selectedPermissions.toList(),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ================= CREATE ROLE =================
  Future<void> createRole(String name, List<String> permissions) async {
    if (name.isEmpty) return;

    try {
      final token = await AuthService.getToken();
      final response = await Dio().post(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/roles',
        data: {
          'name': name,
          'permissions': permissions,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      debugPrint(response.data.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الدور بنجاح')),
      );

      fetchRoles();
    } on DioException catch (e) {
      debugPrint(e.response?.data.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data.toString() ?? 'حدث خطأ'),
        ),
      );
    }
  }

  // ================= EDIT ROLE DIALOG =================
 void showEditRoleDialog(Role role) {
  final TextEditingController roleNameController =
      TextEditingController(text: role.name);
  List<Permission> permissions = [];
  Set<String> selectedPermissions = role.permissions.toSet();
  bool loadingPermissions = true;

  // تحميل الصلاحيات مرة واحدة قبل بناء الديا لوج
  Future<void> loadPermissions() async {
    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/permissions',
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      permissions = (response.data['data'] as List)
          .map((e) => Permission.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint(e.toString());
    }
    loadingPermissions = false;
  }

  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            // إذا كانت الصلاحيات لا تزال تتحمل، أبدأ التحميل مرة واحدة
            if (loadingPermissions) {
              loadPermissions().then((_) => setDialogState(() {}));
            }

            return AlertDialog(
              title: const Text('تعديل الدور'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: roleNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الدور',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'تعيين الصلاحيات',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: loadingPermissions
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              children: permissions.map((permission) {
                                return CheckboxListTile(
                                  title: Text(permission.name),
                                  value: selectedPermissions
                                      .contains(permission.name),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedPermissions
                                            .add(permission.name);
                                      } else {
                                        selectedPermissions
                                            .remove(permission.name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  child: const Text(
                    'حفظ',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () async {
                    await updateRole(
                      role.id,
                      roleNameController.text,
                      selectedPermissions.toList(),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

  // ================= UPDATE ROLE =================
  Future<void> updateRole(int id, String name, List<String> permissions) async {
    if (name.isEmpty) return;

    try {
      final token = await AuthService.getToken();
      final response = await Dio().put(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/roles/$id',
        data: {
          'name': name,
          'permissions': permissions,
        },
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الدور بنجاح')),
      );

      fetchRoles();
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data.toString() ?? 'حدث خطأ'),
        ),
      );
    }
  }

  // ================= DELETE ROLE =================
  Future<void> deleteRole(int id) async {
    try {
      final token = await AuthService.getToken();
      await Dio().delete(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/roles/$id',
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الدور بنجاح')),
      );

      fetchRoles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الحذف')),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأدوار',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: showAddRoleDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : roles.isEmpty
              ? const Center(child: Text('لا توجد أدوار'))
              : ListView.builder(
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          role.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              shape: StadiumBorder(
                                side: BorderSide(color: primaryColor),
                              ),
                              label: Text(
                                'المستخدمين: ${role.usersCount}',
                                style: TextStyle(color: primaryColor),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            Chip(
                              shape: StadiumBorder(
                                side: BorderSide(color: primaryColor),
                              ),
                              label: Text(
                                'الصلاحيات: ${role.permissionsCount}',
                                style: TextStyle(color: primaryColor),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                          ],
                        ),
                        leading: PopupMenuButton(
  icon: const Icon(Icons.more_vert),
  onSelected: (value) {
    if (value == 'edit') {
      showEditRoleDialog(role);
    } else if (value == 'delete') {
      deleteRole(role.id);
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'edit',
      child: Row(
        children: const [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 8),
          Text('تعديل'),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'delete',
      child: Row(
        children: const [
          Icon(Icons.delete, color: Colors.red),
          SizedBox(width: 8),
          Text('حذف'),
        ],
      ),
    ),
  ],
),

                      ),
                    );
                  },
                ),
    );
  }
}

// ================= MODELS =================
class Role {
  final int id;
  final String name;
  final List<String> permissions;
  final int usersCount;
  final int permissionsCount;

  Role({
    required this.id,
    required this.name,
    required this.permissions,
    required this.usersCount,
    required this.permissionsCount,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      permissions: (json['permissions'] as List).map((e) => e.toString()).toList(),
      usersCount: json['users_count'],
      permissionsCount: json['permissions_count'],
    );
  }
}

class Permission {
  final int id;
  final String name;

  Permission({required this.id, required this.name});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'],
      name: json['name'],
    );
  }
}
