import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';

const Color primaryColor = Color(0xFF213D5C);

class Product {
  final int id;
  final String name;
  final String? scientificName;
  final int stock;
  final double? price;

  final String? categoryName;
  final String? stockingUnitName;
  final String? sellableUnitName;
  final int? unitsPerStockingUnit;
  final int? stockQuantity;
  final int? stockAlertLevel;
  final double? latestCostPerSellableUnit;
  final double? suggestedSalePricePerSellableUnit;
  final int? totalItemsPurchased;
  final int? totalItemsSold;
  final String? sku;
  final String? description;
  final int? categoryId;
  final String? createdAt;
final List<dynamic>? warehouses;


  Product({
    required this.id,
    required this.name,
    this.scientificName,
    required this.stock,
    this.price,
    this.categoryName,
    this.stockingUnitName,
    this.sellableUnitName,
    this.unitsPerStockingUnit,
    this.stockQuantity,
    this.stockAlertLevel,
    this.latestCostPerSellableUnit,
    this.suggestedSalePricePerSellableUnit,
    this.totalItemsPurchased,
    this.totalItemsSold,
    this.sku,
    this.description,
    this.categoryId,
    this.createdAt,
    this.warehouses
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      scientificName: json['scientific_name'],
      stock: json['current_stock_quantity'] ?? 0,
      price: json['last_sale_price_per_sellable_unit']?.toDouble(),
      categoryName: json['category_name'],
      categoryId: json['category_id'],
      sku: json['sku'],
      description: json['description'],
      stockingUnitName: json['stocking_unit_name'],
      sellableUnitName: json['sellable_unit_name'],
      unitsPerStockingUnit: json['units_per_stocking_unit'],
      stockQuantity: json['stock_quantity'],
      stockAlertLevel: json['stock_alert_level'],
      latestCostPerSellableUnit: json['latest_cost_per_sellable_unit']?.toDouble(),
      suggestedSalePricePerSellableUnit: json['suggested_sale_price_per_sellable_unit']?.toDouble(),
      totalItemsPurchased: json['total_items_purchased'],
      totalItemsSold: json['total_items_sold'],
      createdAt: json['created_at'],
warehouses: json['warehouses'],

    );
  }
}

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  final Dio _dio = Dio();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final List<Product> _products = [];
  List<Product> _filteredProducts = [];

  List<SimpleItem> _categories = [];
List<SimpleItem> _stockingUnits = [];
List<SimpleItem> _sellableUnits = [];

bool _loadingLookups = false;


  int _page = 1;
  int _lastPage = 1;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;

  final String _url = '${ApiConfig.baseUrl}/sales-api/public/api/products';

  @override
  void initState() {
    super.initState();
    _fetchProducts(initial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 150 &&
          !_isLoadingMore &&
          !_isInitialLoading &&
          _page <= _lastPage) {
        _fetchProducts();
      }
    });

    _searchController.addListener(_applyFilters);

    // استمع لتغيير Category ID وجلب المنتجات مباشرة
    _categoryController.addListener(() {
      _page = 1;
      _lastPage = 1;
      _fetchProducts(initial: true);
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesQuery = query.isEmpty
            ? true
            : product.name.toLowerCase().contains(query) ||
              (product.sku?.toLowerCase().contains(query) ?? false) ||
              (product.scientificName?.toLowerCase().contains(query) ?? false) ||
              (product.description?.toLowerCase().contains(query) ?? false);

        return matchesQuery;
      }).toList();
    });
  }

  Future<void> _fetchProducts({bool initial = false}) async {
    if (!initial && _page > _lastPage) return;

    setState(() {
      if (initial) {
        _isInitialLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final token = await AuthService.getToken();
      final categoryInput = _categoryController.text;

      final response = await _dio.get(
        _url,
        queryParameters: {
          'sort_by': 'created_at',
          'sort_direction': 'desc',
          'per_page': 15,
          'page': _page,
          if (categoryInput.isNotEmpty) 'category_id': categoryInput,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;

      setState(() {
        final newProducts = (data['data'] as List)
            .map((e) => Product.fromJson(e))
            .toList();

        if (initial) {
          _products.clear();
        }

        _products.addAll(newProducts);
        _applyFilters();

        _page++;
        _lastPage = data['meta']['last_page'];
      });
    } catch (e) {
      debugPrint('Error: $e');
    }

    setState(() {
      _isInitialLoading = false;
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

 void _showProductDetails(Product product) {
  // تحويل تاريخ الإنشاء إذا كان موجود
  String formattedDate = '-';
  if (product.createdAt != null && product.createdAt!.isNotEmpty) {
    try {
      DateTime dt = DateTime.parse(product.createdAt!);
      formattedDate = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}";
    } catch (_) {
      formattedDate = product.createdAt!;
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('الاسم العلمي', product.scientificName ?? '-', softWrap: true),
                _buildDetailRow('SKU', product.sku ?? '-'),
                _buildDetailRow('الفئة', product.categoryName ?? '-'),
                _buildDetailRow('وحدة البيع', product.sellableUnitName ?? '-'),
                _buildDetailRow('وحدة التخزين', product.stockingUnitName ?? '-'),
                _buildDetailRow('عدد الوحدات', product.unitsPerStockingUnit?.toString() ?? '-'),
                _buildDetailRow('تاريخ الإنشاء', formattedDate),
                _buildDetailRow('تنبيه المخزون', product.stockAlertLevel?.toString() ?? '-'),
                _buildDetailRow('إجمالي المخزون', product.stockQuantity?.toString() ?? '-'),
                _buildDetailRow('المخازن', product.warehouses != null && product.warehouses!.isNotEmpty
                    ? product.warehouses!.map((e) => e['name']).join(', ')
                    : '-'),
                _buildDetailRow('أحدث تكلفة', product.latestCostPerSellableUnit?.toString() ?? '-'),
                _buildDetailRow('آخر سعر بيع', product.price?.toString() ?? '-'),
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

 Widget _buildDetailRow(String label, String value, {bool softWrap = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
            softWrap: softWrap, // الآن صحيح
          ),
        ),
      ],
    ),
  );
}



Widget _buildProductCard(Product product) {
  return InkWell(
    onTap: () => _showProductDetails(product), // ⬅️ فتح الديالوج عند الضغط
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                // الاسم العلمي
                if (product.scientificName != null)
                  Text(
                    product.scientificName!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                const SizedBox(height: 2),
                // SKU
                Text(
                  'SKU: ${product.sku ?? "-"}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 2),
                // الفئة في سطر منفصل
                Text(
                  'الفئة: ${product.categoryName ?? "-"}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // تنبيه المخزون
              Text(
                product.stock > 0 ? 'المخزون: ${product.stock}' : 'نفد المخزون',
                style: TextStyle(
                  color: product.stock > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              // الثلاث نقاط
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditProductDialog(product);
                  } else if (value == 'delete') {
                    _deleteProduct(product.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  int? _safeParseInt(String value) {
  if (value.trim().isEmpty) return null;
  return int.tryParse(value);
}

void _showSnackBar(String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}
Future<void> _fetchLookups() async {
  final token = await AuthService.getToken();

  final headers = Options(headers: {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  });

  try {
    final categoriesRes = await _dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/admin/categories?all_flat=true',
      options: headers,
    );

    final stockingRes = await _dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/units/stocking',
      options: headers,
    );

    final sellableRes = await _dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/units/sellable',
      options: headers,
    );

    setState(() {
      _categories = (categoriesRes.data['data'] as List)
          .map((e) => SimpleItem.fromJson(e))
          .toList();

      _stockingUnits = (stockingRes.data['data'] as List)
          .map((e) => SimpleItem.fromJson(e))
          .toList();

      // 👇 هنا التصليح المهم
      final sellableData = sellableRes.data['data'] is List
          ? sellableRes.data['data']
          : sellableRes.data['data']['data'];

      _sellableUnits = (sellableData as List)
          .map((e) => SimpleItem.fromJson(e))
          .toList();
    });
  } catch (e) {
    debugPrint('Lookup error: $e');
  }
}

Widget _buildDropdown({
  required String label,
  required List<SimpleItem> items,
  required int? value,
  required ValueChanged<int?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem<int>(
              value: e.id,
              child: Text(e.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
    ),
  );
}


 void _showAddProductDialog() async {
  await _fetchLookups();

  final nameController = TextEditingController();
  final scientificNameController = TextEditingController();
  final skuController = TextEditingController();

  int? selectedCategoryId;
  int? selectedStockingUnitId;
  int? selectedSellableUnitId;

  final unitsPerStockingUnitController =
      TextEditingController(text: '1');
  final stockAlertLevelController =
      TextEditingController(text: '10');

  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة منتج'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(nameController, 'اسم المنتج'),
                _buildTextField(scientificNameController, 'الاسم العلمي'),
                _buildSkuField(skuController),


                _buildDropdown(
                  label: 'الفئة',
                  items: _categories,
                  value: selectedCategoryId,
                  onChanged: (v) => selectedCategoryId = v,
                ),

                _buildDropdown(
                  label: 'وحدة التخزين',
                  items: _stockingUnits,
                  value: selectedStockingUnitId,
                  onChanged: (v) => selectedStockingUnitId = v,
                ),

                _buildDropdown(
                  label: 'وحدة البيع',
                  items: _sellableUnits,
                  value: selectedSellableUnitId,
                  onChanged: (v) => selectedSellableUnitId = v,
                ),

                _buildTextField(
                  unitsPerStockingUnitController,
                  'عدد الوحدات في وحدة المخزون',
                  isNumber: true,
                ),

                _buildTextField(
                  stockAlertLevelController,
                  'حد تنبيه المخزون',
                  isNumber: true,
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
              onPressed: () async {
                await _addProduct(
                  name: nameController.text,
                  scientificName: scientificNameController.text,
                  sku: skuController.text,
                  categoryId: selectedCategoryId,
                  stockingUnitId: selectedStockingUnitId,
                  sellableUnitId: selectedSellableUnitId,
                  unitsPerStockingUnit:
                      int.tryParse(unitsPerStockingUnitController.text),
                  stockAlertLevel:
                      int.tryParse(stockAlertLevelController.text),
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


void _showEditProductDialog(Product product) async {
  await _fetchLookups();

  final nameController =
      TextEditingController(text: product.name);
  final scientificNameController =
      TextEditingController(text: product.scientificName ?? '');
  final skuController =
      TextEditingController(text: product.sku ?? '');

  final unitsPerStockingUnitController =
      TextEditingController(text: (product.unitsPerStockingUnit ?? 1).toString());

  final stockAlertLevelController =
      TextEditingController(text: (product.stockAlertLevel ?? 10).toString());

  int? selectedCategoryId = product.categoryId;
  int? selectedStockingUnitId;
  int? selectedSellableUnitId;

  // محاولة ربط IDs لو موجودة بالاسم
  selectedStockingUnitId = _stockingUnits
      .firstWhere(
        (e) => e.name == product.stockingUnitName,
        orElse: () => _stockingUnits.isNotEmpty
            ? _stockingUnits.first
            : SimpleItem(id: -1, name: ''),
      )
      .id;

  selectedSellableUnitId = _sellableUnits
      .firstWhere(
        (e) => e.name == product.sellableUnitName,
        orElse: () => _sellableUnits.isNotEmpty
            ? _sellableUnits.first
            : SimpleItem(id: -1, name: ''),
      )
      .id;

  showDialog(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل المنتج'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(nameController, 'اسم المنتج'),
                _buildTextField(scientificNameController, 'الاسم العلمي'),
                _buildSkuField(skuController),


                _buildDropdown(
                  label: 'الفئة',
                  items: _categories,
                  value: selectedCategoryId,
                  onChanged: (v) {
                    selectedCategoryId = v;
                  },
                ),

                _buildDropdown(
                  label: 'وحدة التخزين',
                  items: _stockingUnits,
                  value: selectedStockingUnitId,
                  onChanged: (v) {
                    selectedStockingUnitId = v;
                  },
                ),

                _buildDropdown(
                  label: 'وحدة البيع',
                  items: _sellableUnits,
                  value: selectedSellableUnitId,
                  onChanged: (v) {
                    selectedSellableUnitId = v;
                  },
                ),

                _buildTextField(
                  unitsPerStockingUnitController,
                  'عدد الوحدات في وحدة المخزون',
                  isNumber: true,
                ),

                _buildTextField(
                  stockAlertLevelController,
                  'حد تنبيه المخزون',
                  isNumber: true,
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
              onPressed: () async {
                await _updateProduct(
                  id: product.id,
                  name: nameController.text,
                  scientificName: scientificNameController.text,
                  categoryId: selectedCategoryId,
                  stockingUnitId: selectedStockingUnitId,
                  sellableUnitId: selectedSellableUnitId,
                  unitsPerStockingUnit:
                      int.tryParse(unitsPerStockingUnitController.text),
                  stockAlertLevel:
                      int.tryParse(stockAlertLevelController.text),
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

Future<void> _addProduct({
  String? name,
  String? scientificName,
  String? sku,
  String? description,
  int? stockQuantity,
  int? stockAlertLevel,
  int? categoryId,
  int? stockingUnitId,
  int? sellableUnitId,
  int? unitsPerStockingUnit,
}) async {

  // ⬅️ لازم هنا
  final Map<String, dynamic> data = {};

  try {
    final token = await AuthService.getToken();

    if (name != null) data["name"] = name;
    if (scientificName != null) data["scientific_name"] = scientificName;
    if (sku != null) data["sku"] = sku;
    if (description != null) data["description"] = description;
    data["stock_quantity"] = stockQuantity ?? 0;
    if (stockAlertLevel != null) data["stock_alert_level"] = stockAlertLevel;
    if (categoryId != null) data["category_id"] = categoryId;
    if (stockingUnitId != null) data["stocking_unit_id"] = stockingUnitId;
    if (sellableUnitId != null) data["sellable_unit_id"] = sellableUnitId;
    if (unitsPerStockingUnit != null) {
      data["units_per_stocking_unit"] = unitsPerStockingUnit;
    }

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

    _showSnackBar('تمت إضافة المنتج بنجاح');
    _page = 1;
    _lastPage = 1;
    _fetchProducts(initial: true);

  } on DioException catch (e) {
    debugPrint('❌ STATUS CODE: ${e.response?.statusCode}');
    debugPrint('❌ SENT DATA: $data');
    debugPrint('❌ RESPONSE DATA: ${e.response?.data}');

    String errorMessage = 'فشل إضافة المنتج';

    final res = e.response?.data;
    if (res is Map && res['errors'] != null) {
      errorMessage = '';
      (res['errors'] as Map).forEach((key, value) {
        errorMessage += '$key: ${value.join(', ')}\n';
      });
    } else if (res is Map && res['message'] != null) {
      errorMessage = res['message'].toString();
    }

    _showSnackBar(errorMessage, error: true);
  }
}


Future<void> _updateProduct({
  required int id,
  String? name,
  String? scientificName,
  String? description,
  int? stockAlertLevel,
  int? categoryId,
  int? stockingUnitId,
  int? sellableUnitId,
  int? unitsPerStockingUnit,
}) async {
  try {
    final token = await AuthService.getToken();

    // نرسل فقط الحقول التي ذكرتها
    final data = <String, dynamic>{};

    if (name != null && name.isNotEmpty) data["name"] = name;
    if (scientificName != null && scientificName.isNotEmpty) data["scientific_name"] = scientificName;
    if (description != null && description.isNotEmpty) data["description"] = description;
    if (stockAlertLevel != null) data["stock_alert_level"] = stockAlertLevel;
    if (categoryId != null) data["category_id"] = categoryId;
    if (stockingUnitId != null) data["stocking_unit_id"] = stockingUnitId;
    if (sellableUnitId != null) data["sellable_unit_id"] = sellableUnitId;
    if (unitsPerStockingUnit != null) data["units_per_stocking_unit"] = unitsPerStockingUnit;

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

    _showSnackBar('تم تعديل المنتج بنجاح');
    _page = 1;
    _fetchProducts(initial: true);
  } catch (e) {
    debugPrint('Update product error: $e');
    _showSnackBar('فشل تعديل المنتج', error: true);
  }
}


Future<void> _deleteProduct(int id) async {
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

    _showSnackBar('تم حذف المنتج');
    _page = 1;
    _fetchProducts(initial: true);
  } catch (e) {
    _showSnackBar('فشل حذف المنتج', error: true);
  }
}



Widget _buildTextField(
  TextEditingController controller,
  String label, {
  bool isNumber = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
String _generateRandomSku({int length = 13}) {
  final random = Random();
  return List.generate(length, (_) => random.nextInt(10)).join();
}
Widget _buildSkuField(TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'SKU',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'توليد SKU',
          icon: const Icon(Icons.cached),
          onPressed: () {
            controller.text = _generateRandomSku();
          },
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('المنتجات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
    IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: _showAddProductDialog, // ⬅ فتح الديالوج
    ),
  ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU, scientific name, or description',
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
         
          
          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_filteredProducts[index]);
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
class SimpleItem {
  final int id;
  final String name;

  SimpleItem({required this.id, required this.name});

  factory SimpleItem.fromJson(Map<String, dynamic> json) {
    return SimpleItem(
      id: json['id'],
      name: json['name'],
    );
  }
}

