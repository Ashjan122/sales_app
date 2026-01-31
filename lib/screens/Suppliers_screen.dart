import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:jawda_sales/screens/supplier_ledger_screen.dart';

const Color primaryColor = Color(0xFF213D5C);

class Supplier {
  final int id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;

  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'] ?? '',
      contactPerson: json['contact_person'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
    );
  }
}

class SuppliersListPage extends StatefulWidget {
  const SuppliersListPage({super.key});

  @override
  State<SuppliersListPage> createState() => _SuppliersListPageState();
}

class _SuppliersListPageState extends State<SuppliersListPage> {
  final Dio _dio = Dio();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];

  int _page = 1;
  int _lastPage = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;

  final String _url =
      '${ApiConfig.baseUrl}/sales-api/public/api/suppliers';

  @override
  void initState() {
    super.initState();
    _fetchSuppliers(initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 150 &&
          !_isLoadingMore &&
          !_isInitialLoading &&
          _page <= _lastPage) {
        _fetchSuppliers();
      }
    });

    _searchController.addListener(_applyFilters);
  }

  /// =====================
  /// Search Filter
  /// =====================
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        return query.isEmpty ||
            supplier.name.toLowerCase().contains(query) ||
            (supplier.contactPerson?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _fetchSuppliers({bool initial = false}) async {
    if (!initial && _page > _lastPage) return;

    setState(() {
      initial ? _isInitialLoading = true : _isLoadingMore = true;
    });

    try {
      final token = await AuthService.getToken();

      final response = await _dio.get(
        _url,
        queryParameters: {
          'per_page': 15,
          'page': _page,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;

      final newSuppliers = (data['data'] as List)
          .map((e) => Supplier.fromJson(e))
          .toList();

      setState(() {
        if (initial) _suppliers.clear();

        _suppliers.addAll(newSuppliers);
        _applyFilters();

        _page++;
        _lastPage = data['last_page'];
      });
    } catch (e) {
      debugPrint('Error fetching suppliers: $e');
    }

    setState(() {
      _isInitialLoading = false;
      _isLoadingMore = false;
    });
  }
 void _openSupplierStatement(Supplier supplier) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SupplierLedgerPage(supplier: supplier),
    ),
  );
}


  Widget _buildSupplierCard(Supplier supplier) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showSupplierDetailsDialog(supplier),
        title: Text(
          supplier.name,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          supplier.contactPerson != null
              ? 'المسؤول: ${supplier.contactPerson}'
              : 'المسؤول: غير محدد',
          textAlign: TextAlign.right,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'statement') {
              _openSupplierStatement(supplier);
            } else if (value == 'edit') {
              _showEditSupplierDialog(supplier);
            } else if (value == 'delete') {
              _confirmDeleteSupplier(supplier.id);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'statement',
              child: Row(
                children: const [
                  Icon(Icons.receipt_long, color: Colors.green),
                  SizedBox(width: 8),
                  Text('كشف الحساب'),
                ],
              ),
            ),
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
    ),
  );
}


  void _showSupplierDetailsDialog(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تفاصيل المورد'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('الاسم', supplier.name),
                  _detailRow('المسؤول', supplier.contactPerson),
                  _detailRow('الهاتف', supplier.phone),
                  _detailRow('البريد الإلكتروني', supplier.email),
                  _detailRow('العنوان', supplier.address),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Text(
            value ?? 'غير متوفر',
            textAlign: TextAlign.left,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    ),
  );
}
void _showAddSupplierDialog() {
  final nameController = TextEditingController();
  final contactPersonController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة مورد جديد'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildInputField(nameController, 'اسم المورد'),
                _buildInputField(contactPersonController, 'المسؤول'),
                _buildInputField(emailController, 'البريد الإلكتروني'),
                _buildInputField(phoneController, 'رقم الهاتف'),
                _buildInputField(addressController, 'العنوان'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _addSupplier(
                  name: nameController.text,
                  contactPerson: contactPersonController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    },
  );
}
Future<void> _addSupplier({
  required String name,
  String? contactPerson,
  String? email,
  String? phone,
  String? address,
}) async {
  try {
    final token = await AuthService.getToken();

    final data = <String, dynamic>{
      "name": name,
      if (contactPerson != null && contactPerson.isNotEmpty)
        "contact_person": contactPerson,
      if (email != null && email.isNotEmpty) "email": email,
      if (phone != null && phone.isNotEmpty) "phone": phone,
      if (address != null && address.isNotEmpty) "address": address,
    };

    await _dio.post(
      _url,
      data: data,
      options: Options(
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة المورد بنجاح')),
    );

    _page = 1;
    _lastPage = 1;
    _fetchSuppliers(initial: true);
  } catch (e) {
    debugPrint('Add supplier error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل إضافة المورد'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
Widget _buildInputField(
  TextEditingController controller,
  String label,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
void _showEditSupplierDialog(Supplier supplier) {
  final nameController =
      TextEditingController(text: supplier.name);
  final contactPersonController =
      TextEditingController(text: supplier.contactPerson);
  final emailController =
      TextEditingController(text: supplier.email);
  final phoneController =
      TextEditingController(text: supplier.phone);
  final addressController =
      TextEditingController(text: supplier.address);

  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل المورد'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildInputField(nameController, 'اسم المورد'),
                _buildInputField(contactPersonController, 'المسؤول'),
                _buildInputField(emailController, 'البريد الإلكتروني'),
                _buildInputField(phoneController, 'رقم الهاتف'),
                _buildInputField(addressController, 'العنوان'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateSupplier(
                  id: supplier.id,
                  name: nameController.text,
                  contactPerson: contactPersonController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    },
  );
}
Future<void> _updateSupplier({
  required int id,
  required String name,
  String? contactPerson,
  String? email,
  String? phone,
  String? address,
}) async {
  try {
    final token = await AuthService.getToken();

    final data = {
      "name": name,
      "contact_person": contactPerson,
      "email": email,
      "phone": phone,
      "address": address,
    };

    await _dio.put(
      '$_url/$id',
      data: data,
      options: Options(
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعديل المورد بنجاح')),
    );

    _page = 1;
    _lastPage = 1;
    _fetchSuppliers(initial: true);
  } catch (e) {
    debugPrint('Update supplier error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل تعديل المورد'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
void _confirmDeleteSupplier(int id) {
  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المورد'),
          content: const Text('هل أنت متأكد من حذف هذا المورد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSupplier(id);
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _deleteSupplier(int id) async {
  try {
    final token = await AuthService.getToken();

    await _dio.delete(
      '$_url/$id',
      options: Options(
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المورد')),
    );

    _suppliers.removeWhere((e) => e.id == id);
    _applyFilters();
  } catch (e) {
    debugPrint('Delete supplier error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل حذف المورد'),
        backgroundColor: Colors.red,
      ),
    );
  }
}




  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('الموردون', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
    IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: _showAddSupplierDialog,
    ),
  ],
      ),
      body: Column(
        children: [
          Padding(
  padding: const EdgeInsets.all(12.0),
  child: Directionality(
    textDirection: TextDirection.rtl,
    child: TextField(
      controller: _searchController,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: 'بحث بالاسم ، البريد الالكتروني أو المسؤول',
        hintTextDirection: TextDirection.rtl,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  ),
),

          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      return _buildSupplierCard(
                          _filteredSuppliers[index]);
                    },
                  ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
