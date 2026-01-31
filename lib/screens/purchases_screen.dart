import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/screens/PurchaseItemsScreen.dart';
import 'package:jawda_sales/screens/products_screen.dart';

class PurchasesListPage extends StatefulWidget {
  const PurchasesListPage({super.key});

  @override
  State<PurchasesListPage> createState() => _PurchasesListPageState();
}

class _PurchasesListPageState extends State<PurchasesListPage> {
  final Dio _dio = Dio();
  final ScrollController _scrollController = ScrollController();

  // 🔍 بحث بالاسم فقط
  final TextEditingController _searchController = TextEditingController();

  final List<Purchase> _purchases = [];
  int _page = 1;
  int _lastPage = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  final List<Purchase> _allPurchases = [];


  Timer? _debounce;

  final String _url =
      '${ApiConfig.baseUrl}/sales-api/public/api/purchases';

  final intl.NumberFormat _numberFormat =
      intl.NumberFormat("#,##0", "en_US");


  @override
  void initState() {
    super.initState();
    _fetchPurchases(initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 150 &&
          !_isLoadingMore &&
          !_isInitialLoading &&
          _page <= _lastPage) {
        _fetchPurchases();
      }
    });

    // 🔍 debounce للبحث
   _searchController.addListener(() {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    setState(() {
      _applyLocalSearch();
    });
  });
});

  }

  Future<void> _fetchPurchases({bool initial = false}) async {
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

    final newItems = (data['data'] as List)
        .map((e) => Purchase.fromJson(e))
        .toList();

    setState(() {
      if (initial) {
        _allPurchases.clear();
        _purchases.clear();
      }

      _allPurchases.addAll(newItems);
      _applyLocalSearch(); // 🔍 فلترة محلية
      _page++;
      _lastPage = data['meta']['last_page'];
    });
  } catch (e) {
    debugPrint('Error fetching purchases: $e');
  }

  setState(() {
    _isInitialLoading = false;
    _isLoadingMore = false;
  });
}
void _applyLocalSearch() {
  final query = _searchController.text.trim().toLowerCase();

  if (query.isEmpty) {
    _purchases
      ..clear()
      ..addAll(_allPurchases);
  } else {
    _purchases
      ..clear()
      ..addAll(
        _allPurchases.where((p) =>
            p.supplierName.toLowerCase().contains(query)),
      );
  }
}

  // 🔹 تفاصيل مشتريات حسب ID
  Future<void> _showPurchaseDetailsById(int purchaseId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await AuthService.getToken();

      final response = await _dio.get(
        '$_url/$purchaseId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      Navigator.pop(context);

      final purchaseData = response.data['purchase'];
      if (purchaseData != null) {
        _showPurchaseDialog(Purchase.fromJson(purchaseData));
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void _showPurchaseDialog(Purchase p) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل المشتريات'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('رقم المشتريات', p.id.toString()),
                _detailRow('المورد', p.supplierName),
                _detailRow('المستخدم', p.userName),
                _detailRow('تاريخ الشراء', p.purchaseDate),
                _detailRow('المرجع', p.referenceNumber),
                _detailRow('الحالة', p.status),
                _detailRow(
                  'الإجمالي',
                  _numberFormat
                      .format(double.tryParse(p.totalAmount) ?? 0),
                ),
                _detailRow('ملاحظات', p.notes),
                const Divider(),
                const Text('الأصناف:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (p.items != null && p.items!.isNotEmpty)
                  ...p.items!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        _detailRow(
                            'المنتج',
                            item.product?.name ??
                                item.productName ??
                                '—'),
                        _detailRow(
                            'SKU',
                            item.product?.sku ??
                                item.productSku ??
                                '—'),
                        _detailRow(
                            'الدفعة', item.batchNumber ?? '—'),
                        _detailRow(
                            'الكمية', item.quantity.toString()),
                        _detailRow(
                            'سعر الوحدة',
                            _numberFormat.format(item.unitCost)),
                        _detailRow(
                            'الإجمالي',
                            _numberFormat.format(item.totalCost)),
                        _detailRow(
                            'الصلاحية',
                            item.expiryDate ?? '—'),
                        if (index != p.items!.length - 1)
                          const Divider(),
                      ],
                    );
                  })
                else
                  const Text('لا توجد أصناف'),
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
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value ?? '—'),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase p) {
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
          onTap: () {
          // فتح الصفحة الجديدة
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PurchaseItemsPage(purchase: p),
            ),
          );
        },
          title: Text(
            p.supplierName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('التاريخ: ${p.purchaseDate}'),
              Text(
                'السعر: ${_numberFormat.format(double.tryParse(p.totalAmount) ?? 0)}',
              ),
            ],
          ),
          trailing: Text(
            p.status,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
 void _showAddPurchaseDialog() async {
  String? selectedWarehouse;
  String? selectedSupplier;
  String status = 'pending';
  String currency = 'SDG';

  final referenceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> suppliers = [];

  /// 🔄 Loading قبل فتح الديالوج
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final token = await AuthService.getToken();

    final whRes = await Dio().get(
      '${ApiConfig.baseUrl}/sales-api/public/api/warehouses',
      options: Options(headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }),
    );

    final supRes = await Dio().get(
      '${ApiConfig.baseUrl}/sales-api/public/api/suppliers?page=1',
      options: Options(headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }),
    );

    warehouses = List<Map<String, dynamic>>.from(whRes.data['data']);
    suppliers = List<Map<String, dynamic>>.from(supRes.data['data']);
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل تحميل البيانات'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Navigator.pop(context);

  showDialog(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة فاتورة مشتريات'),
        content: SingleChildScrollView(
          child: Column(
            children: [

              /// 🏬 المخزن
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('المخزن'),
                items: warehouses
                    .map((w) => DropdownMenuItem(
                          value: w['id'].toString(),
                          child: Text(w['name']),
                        ))
                    .toList(),
                onChanged: (v) => selectedWarehouse = v,
              ),

              const SizedBox(height: 12),

              /// 🚚 المورد
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('المورد'),
                items: suppliers
                    .map((s) => DropdownMenuItem(
                          value: s['id'].toString(),
                          child: Text(s['name']),
                        ))
                    .toList(),
                onChanged: (v) => selectedSupplier = v,
              ),

              const SizedBox(height: 12),

              /// 📌 الحالة
              DropdownButtonFormField<String>(
                value: status,
                decoration: _inputDecoration('الحالة'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                  DropdownMenuItem(value: 'received', child: Text('مستلمة')),
                  DropdownMenuItem(value: 'ordered', child: Text('تم الطلب')),
                ],
                onChanged: (v) => status = v!,
              ),

              const SizedBox(height: 12),

              /// 💰 العملة
              DropdownButtonFormField<String>(
                value: currency,
                decoration: _inputDecoration('العملة'),
                items: const [
                  DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                ],
                onChanged: (v) => currency = v!,
              ),

              const SizedBox(height: 12),

              /// 🔢 رقم المرجع
              _input('رقم المرجع', referenceCtrl),

              /// 📝 ملاحظات
              _input('ملاحظات', notesCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            child: const Text('حفظ'),
            onPressed: () async {
              if (selectedWarehouse == null || selectedSupplier == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء اختيار المخزن والمورد'),
                  ),
                );
                return;
              }

              try {
                final token = await AuthService.getToken();
                final today = DateTime.now().toIso8601String().split('T')[0];

                await Dio().post(
                  '${ApiConfig.baseUrl}/sales-api/public/api/purchases',
                  data: {
                    "warehouse_id": int.parse(selectedWarehouse!),
                    "supplier_id": int.parse(selectedSupplier!),
                    "purchase_date": today,
                    "status": status,
                    "currency": currency,
                    "reference_number": referenceCtrl.text,
                    "notes": notesCtrl.text,
                  },
                  options: Options(headers: {
                    'Accept': 'application/json',
                    if (token != null) 'Authorization': 'Bearer $token',
                  }),
                );

                Navigator.pop(context);

                _page = 1;
                _lastPage = 1;
                _purchases.clear();
                _allPurchases.clear();
                _fetchPurchases(initial: true);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت الإضافة بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('فشل الإضافة'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}


Future<void> _createPurchase(
  String supplierId,
  String warehouseId,
  String purchaseDate,
  String reference,
  String status,
  String notes,
  String productId,
  String batch,
  String quantity,
  String unitCost,
  String salePrice,
  String salePriceStock,
  String expiry,
) async {
  try {
    final token = await AuthService.getToken();

    await _dio.post(
      _url,
      data: {
        "supplier_id": int.parse(supplierId),
        "warehouse_id": int.parse(warehouseId),
        "purchase_date": purchaseDate,
        "reference_number": reference,
        "status": status,
        "notes": notes,
        "items": [
          {
            "product_id": int.parse(productId),
            "batch_number": batch,
            "quantity": int.parse(quantity),
            "unit_cost": double.parse(unitCost),
            "sale_price": double.parse(salePrice),
            "sale_price_stocking_unit": double.parse(salePriceStock),
            "expiry_date": expiry,
          }
        ]
      },
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    //  إعادة تحميل القائمة
    _page = 1;
    _lastPage = 1;
    _purchases.clear();
    _allPurchases.clear();
    _fetchPurchases(initial: true);
  } catch (e) {
    debugPrint('Create purchase error: $e');
  }
}



  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('المشتريات',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
    IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: _showAddPurchaseDialog,
    ),
  ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) =>
                        _buildPurchaseCard(_purchases[index]),
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
Widget _input(String label, TextEditingController c) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.blue, width: 1.5),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}


// ===================== Models =====================

class Purchase {
  final int id;
  final int supplierId;
  final String supplierName;
  final String userName;
  final String purchaseDate;
  final String? referenceNumber;
  String status;
  String totalAmount;
  final String? notes;
  List<PurchaseItem>? items;
  

  Purchase({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.userName,
    required this.purchaseDate,
    this.referenceNumber,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.items,
   
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'] ?? '',
      userName: json['user_name'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      referenceNumber: json['reference_number'],
      status: json['status'] ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      notes: json['notes'],

      items: (json['items'] as List?)
          ?.map((e) => PurchaseItem.fromJson(e))
          .toList(),
    );
  }
}

class PurchaseItem {
  final int id;
  final int quantity;
  final double unitCost;
  final double totalCost;
  final String? expiryDate;
  final String? batchNumber;
  final String? productName;
  final String? productSku;
  final Product? product;
  final double? salePrice; // جديد
  final double? salePriceStockingUnit;

  PurchaseItem({
    required this.id,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    this.expiryDate,
    this.batchNumber,
    this.productName,
    this.productSku,
    this.product,
     required this.salePrice,
    required this.salePriceStockingUnit
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      quantity: json['quantity'] ?? 0,
      unitCost:
          double.tryParse(json['unit_cost'].toString()) ?? 0,
      totalCost:
          double.tryParse(json['total_cost'].toString()) ?? 0,
      expiryDate: json['expiry_date'],
      batchNumber: json['batch_number'],
      productName: json['product_name'],
      productSku: json['product_sku'],
       salePrice: json['sale_price'] != null ? double.tryParse(json['sale_price'].toString()) : null,
      salePriceStockingUnit: json['sale_price_stocking_unit'] != null
          ? double.tryParse(json['sale_price_stocking_unit'].toString())
          : null,
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

class Product {
  final int id; 
  final String name;
  final String? sku;

  Product({required this.id, required this.name, this.sku});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], 
      name: json['name'],
      sku: json['sku'],
    );
  }
}

