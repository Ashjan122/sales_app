import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import '../core/services/auth_service.dart';

import '../screens/purchases_screen.dart'; 

class PurchaseItemsPage extends StatefulWidget {
  final Purchase purchase;

  const PurchaseItemsPage({super.key, required this.purchase});

  @override
  State<PurchaseItemsPage> createState() => _PurchaseItemsPageState();
}

class _PurchaseItemsPageState extends State<PurchaseItemsPage> {
  final intl.NumberFormat _numberFormat = intl.NumberFormat("#,##0", "en_US");
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF213D5C); 

  @override
  void initState() {
    super.initState();
    _fetchPurchaseDetails();
  }

  Future<void> _fetchPurchaseDetails() async {
    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/purchases/${widget.purchase.id}',
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      final data = response.data['purchase'];
      if (data != null) {
        setState(() {
          widget.purchase.items = (data['items'] as List)
              .map((e) => PurchaseItem.fromJson(e))
              .toList();
          widget.purchase.totalAmount = data['total_amount']?.toString() ?? '0';
          widget.purchase.status = data['status'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching purchase details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

 void _showAddPurchaseItemDialog() async {
  // عرض الـ loading أولاً
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  List<Product> allProducts = [];
  Product? selectedProduct;

  try {
    final token = await AuthService.getToken();
    final response = await Dio().get(
      '${ApiConfig.baseUrl}/sales-api/public/api/products/autocomplete?limit=2000&show_all_for_empty_search=true',
      options: Options(headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }),
    );

    allProducts = (response.data['data'] as List)
        .map((e) => Product.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching products: $e');
    Navigator.pop(context); // إغلاق الـ loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل جلب المنتجات'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  Navigator.pop(context); // إغلاق الـ loading بعد الانتهاء

  // إعداد Controllers
  final batchController = TextEditingController();
  final quantityController = TextEditingController();
  final unitCostController = TextEditingController();
  final salePriceController = TextEditingController();
  final salePriceStockController = TextEditingController();
  final expiryController = TextEditingController();
  final totalCostController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('إضافة صنف جديد'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Autocomplete<Product>(
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty) return allProducts;
                        return allProducts.where((product) {
                          return product.name
                                  .toLowerCase()
                                  .contains(value.text.toLowerCase()) ||
                              (product.sku
                                      ?.toLowerCase()
                                      .contains(value.text.toLowerCase()) ??
                                  false);
                        });
                      },
                      displayStringForOption: (product) =>
                          '${product.name} - ${product.sku ?? ""}',
                      onSelected: (product) {
                        setState(() {
                          selectedProduct = product;

                          batchController.clear();
                          quantityController.clear();
                          unitCostController.clear();
                          salePriceController.clear();
                          salePriceStockController.clear();
                          expiryController.clear();
                          totalCostController.clear();
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, _) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'بحث بالاسم أو الباركود',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedProduct != null) ...[
                      _editableField('رقم الدفعة', '',
                          controller: batchController),
                      _editableField('الكمية', '',
                          controller: quantityController),
                      _editableField('سعر التكلفة', '',
                          controller: unitCostController),
                      _editableField('سعر البيع (وحدة بيع)', '',
                          controller: salePriceController),
                      _editableField('سعر البيع (وحدة تخزين)', '',
                          controller: salePriceStockController),
                      _editableField('تاريخ الانتهاء', '',
                          controller: expiryController),
                      _editableField(
                        'إجمالي التكلفة',
                        '',
                        controller: totalCostController,
                        readOnly: true,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  child: const Text('إضافة الصنف'),
                  onPressed: () async {
                    if (selectedProduct == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('الرجاء اختيار المنتج أولاً')),
                      );
                      return;
                    }

                    final data = {
  "purchase_id": widget.purchase.id, 
  "product_id": selectedProduct!.id,
  
  "batch_number": batchController.text,
  "quantity": int.tryParse(quantityController.text) ?? 0,
  "unit_cost": double.tryParse(unitCostController.text) ?? 0,
  "sale_price": double.tryParse(salePriceController.text) ?? 0,
  "sale_price_stocking_unit":
      double.tryParse(salePriceStockController.text) ?? 0,
  "expiry_date": expiryController.text,
};


                    try {
                      final token = await AuthService.getToken();
                      await Dio().post(
                        '${ApiConfig.baseUrl}/sales-api/public/api/purchases/${widget.purchase.id}/items',

                        data: data,
                        options: Options(headers: {
                          'Accept': 'application/json',
                          'Content-Type': 'application/json',
                          if (token != null)
                            'Authorization': 'Bearer $token',
                        }),
                      );

                      if (!mounted) return; // تحقق أن الـ widget ما زال موجود
  Navigator.pop(context); // اغلق الـ dialog
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تمت إضافة الصنف بنجاح')),
  );

  // تحديث القائمة فورًا
  _fetchPurchaseDetails();
                   } catch (e) {
  if (e is DioException) {
    debugPrint('STATUS: ${e.response?.statusCode}');
    debugPrint('RESPONSE: ${e.response?.data}');
  } else {
    debugPrint(e.toString());
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('فشل إضافة الصنف'),
      backgroundColor: Colors.red,
    ),
  );
}

                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final purchase = widget.purchase;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة أصناف المشتريات',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddPurchaseItemDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${purchase.supplierName} #${purchase.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'عدد الأصناف: ${purchase.items?.length ?? 0}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'الإجمالي: ${_numberFormat.format(double.tryParse(purchase.totalAmount) ?? 0)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: purchase.status,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'received', child: Text('Received')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'ordered', child: Text('Ordered')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            purchase.status = value;
                          });
                        }
                      },
                    ),
                  ),
                  const Divider(height: 30),
                 Expanded(
  child: ListView.builder(
    itemCount: purchase.items?.length ?? 0,
    itemBuilder: (context, index) {
      final item = purchase.items![index];

      final batchCtrl = TextEditingController(text: item.batchNumber ?? '');
      final quantityCtrl = TextEditingController(text: item.quantity.toString());
      final unitCostCtrl = TextEditingController(text: item.unitCost.toString());
      final salePriceCtrl = TextEditingController(text: item.salePrice?.toString() ?? '');
      final salePriceStockCtrl = TextEditingController(text: item.salePriceStockingUnit?.toString() ?? '');
      final expiryCtrl = TextEditingController(text: item.expiryDate ?? '');
      final totalCostCtrl = TextEditingController(text: item.totalCost.toString());

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName ?? "—"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // حذف الصنف
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تأكيد الحذف'),
                          content: const Text('هل أنت متأكد من حذف هذا الصنف؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('إلغاء'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        final token = await AuthService.getToken();
                        await Dio().delete(
                          '${ApiConfig.baseUrl}/sales-api/public/api/purchases/${widget.purchase.id}/items/${item.id}',
                          options: Options(headers: {
                            'Accept': 'application/json',
                            if (token != null) 'Authorization': 'Bearer $token',
                          }),
                        );

                        // حذف محليًا وتحديث الشاشة
                        setState(() {
                          purchase.items!.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حذف الصنف بنجاح')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('فشل حذف الصنف'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              Text('باركود: ${item.productSku ?? "—"}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _editableField('رقم الدفعة', '', controller: batchCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _editableField('الكمية', '', controller: quantityCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _editableField('سعر التكلفة', '', controller: unitCostCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _editableField('سعر البيع (وحدة بيع)', '', controller: salePriceCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _editableField('سعر البيع (وحدة تخزين)', '', controller: salePriceStockCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _editableField('تاريخ الانتهاء', '', controller: expiryCtrl)),
                ],
              ),
              const SizedBox(height: 12),
              _editableField('إجمالي التكلفة', '', controller: totalCostCtrl, readOnly: true),
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

  Widget _editableField(String label, String value,
      {TextEditingController? controller, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller ?? TextEditingController(text: value),
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}
