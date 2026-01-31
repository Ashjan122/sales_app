import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:jawda_sales/screens/pdf_view_screen.dart';
import 'package:jawda_sales/screens/sales_history_screen.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart' as intl;

class Product {
  final int id;
  final String name;
  final int stockQuantity;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      stockQuantity: json['current_stock_quantity'] ?? 0,
      price: (json['last_sale_price_per_sellable_unit'] ?? 0).toDouble(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  double unitPrice;
  bool isEditingPrice;

  CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.isEditingPrice = false,
  });

  double get total => quantity * unitPrice;
}

class Client {
  final int id;
  final String name;

  Client({required this.id, required this.name});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(id: json['id'], name: json['name'] ?? '');
  }
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final Dio dio = Dio();

  bool saleStarted = false;
  List<Product> products = [];
  List<CartItem> cart = [];

  final Color primaryColor = const Color(0xFF213D5C);

  List<Client> clients = [];
  Client? selectedClient;
  late DateTime saleDateTime;

  double remainingAmount = 0.0;
  List<Map<String, dynamic>> payments = [];

  double discountAmount = 0.0;
  String discountType = 'fixed'; // fixed | percentage

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final intl.NumberFormat numberFormat = intl.NumberFormat('#,##0.##');

  double get calculatedDiscount {
    if (discountType == 'percentage') {
      return (cartTotal * discountAmount / 100);
    }
    return discountAmount;
  }

  double get totalAfterDiscount {
    final d = calculatedDiscount;
    return (cartTotal - d) < 0 ? 0 : cartTotal - d;
  }

  void _showDiscountDialog() {
    String tempType = discountType;
    final TextEditingController amountCtrl = TextEditingController(
      text: discountAmount == 0 ? '' : discountAmount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة خصم'),
            content: StatefulBuilder(
              builder: (context, setLocal) {
                double previewDiscount =
                    tempType == 'percentage'
                        ? cartTotal * (_toDouble(amountCtrl.text) / 100)
                        : _toDouble(amountCtrl.text);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tempType,
                      decoration: const InputDecoration(labelText: 'نوع الخصم'),
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('نسبة مئوية'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed',
                          child: Text('مبلغ ثابت'),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => tempType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'مبلغ الخصم',
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                    const SizedBox(height: 16),

                    // ===== المعاينة =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الفرعي'),
                        Text(numberFormat.format(cartTotal)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الخصم'),
                        Text('- ${numberFormat.format(previewDiscount)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          numberFormat.format(cartTotal - previewDiscount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('حفظ'),
                onPressed: () {
                  setState(() {
                    discountType = tempType;
                    discountAmount = _toDouble(amountCtrl.text);
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔒 تحويل آمن (حل مشكلة int/double)
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    saleDateTime = DateTime.now();
    _loadProducts();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final token = await AuthService.getToken();
    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final response = await dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/clients',
      queryParameters: {'page': 1},
    );

    setState(() {
      clients =
          (response.data['data'] as List)
              .map((e) => Client.fromJson(e))
              .toList();
    });
  }

  Future<void> _loadProducts() async {
    final token = await AuthService.getToken();

    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final response = await dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/products',
      queryParameters: {
        'page': 1,
        'per_page': 1000,
        'sort_by': 'name',
        'sort_direction': 'asc',
      },
    );

    if (!mounted) return;

    setState(() {
      products =
          (response.data['data'] as List)
              .map((e) => Product.fromJson(e))
              .toList();
    });
  }

  void addToCart(Product product) {
    final index = cart.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      if (cart[index].quantity < product.stockQuantity) {
        setState(() => cart[index].quantity++);
      }
    } else {
      setState(() {
        cart.add(
          CartItem(product: product, quantity: 1, unitPrice: product.price),
        );
      });
    }
  }

  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.total);

  /// =======================
  /// Load Sale For Edit (FIXED)
  /// =======================
  void _loadSaleForEdit(Map sale) {
    setState(() {
      saleStarted = true;
      cart.clear();
      payments.clear();

      selectedClient = clients.firstWhere(
        (c) => c.id == sale['client_id'],
        orElse:
            () => clients.isNotEmpty ? clients.first : Client(id: 0, name: ''),
      );

      remainingAmount =
          _toDouble(sale['total_amount']) - _toDouble(sale['paid_amount']);

      for (var item in sale['items']) {
        cart.add(
          CartItem(
            product: products.firstWhere((p) => p.id == item['product_id']),
            quantity: item['quantity'] ?? 1,
            unitPrice: _toDouble(item['unit_price']),
          ),
        );
      }
    });
  }

  /// =======================
  /// Payment Dialog (FIXED)
  /// =======================
  void _showPaymentDialog() {
    String paymentMethod = 'cash';
    final TextEditingController amountController = TextEditingController(
      text: remainingAmount.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('الدفع'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ المستحق: ${remainingAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الدفع',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('نقدي')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('تحويل بنكي'),
                    ),
                  ],
                  onChanged: (value) {
                    paymentMethod = value!;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                child: const Text('إضافة'),
                onPressed: () {
                  final paid = _toDouble(amountController.text);

                  if (paid <= 0 || paid > remainingAmount) return;

                  payments.add({
                    'method': paymentMethod,
                    'amount': paid,
                    'payment_date':
                        DateTime.now().toIso8601String().split('T').first,
                  });

                  remainingAmount -= paid;
                  Navigator.pop(context);

                  if (remainingAmount > 0) {
                    _showPaymentDialog();
                  } else {
                    _showConfirmDialog();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            content: const Text(
              'تم استلام كامل المبلغ',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                child: const Text('إتمام البيع والحفظ'),
                onPressed: () {
                  Navigator.pop(context);
                  submitSale();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generatePdfInvoice(BuildContext context) async {
    try {
      if (selectedClient == null || cart.isEmpty) return;

      // ===== حسابات الفاتورة =====
      final total = cartTotal; // المبلغ الأصلي قبل الخصم
      final discount = calculatedDiscount; // قيمة الخصم
      final paid = total - discount; // المدفوع بعد الخصم

      final PdfDocument document = PdfDocument();
      final page = document.pages.add();
      final pageWidth = page.getClientSize().width;

      final PdfStandardFont titleFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        18,
        style: PdfFontStyle.bold,
      );
      final PdfStandardFont boldFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        12,
        style: PdfFontStyle.bold,
      );
      final PdfStandardFont contentFont = PdfStandardFont(
        PdfFontFamily.helvetica,
        11,
      );

      double y = 0;

      // رقم الفاتورة والتاريخ
      final invoiceNumber = DateTime.now().millisecondsSinceEpoch;
      final today =
          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      // اسم العميل
      page.graphics.drawString(
        'Customer: ${selectedClient!.name}',
        contentFont,
        bounds: Rect.fromLTWH(0, y, pageWidth / 2, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );

      page.graphics.drawString(
        'Number: $invoiceNumber',
        contentFont,
        bounds: Rect.fromLTWH(0, y + 20, pageWidth / 2, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );

      // وسط الصفحة: Sales Cash + التاريخ
      page.graphics.drawString(
        'Sales Cash',
        boldFont,
        bounds: Rect.fromLTWH(pageWidth / 2 - 80, y, 160, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      page.graphics.drawString(
        today,
        contentFont,
        bounds: Rect.fromLTWH(pageWidth / 2 - 80, y + 20, 160, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // يمين الصفحة: اسم الشركة
      page.graphics.drawString(
        'LIFECARE MEDICAL EQUIPMENT\nTRADING ENTERPRISES',
        titleFont,
        bounds: Rect.fromLTWH(pageWidth / 2, y, pageWidth / 2, 70),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.right,
          lineAlignment: PdfVerticalAlignment.top,
          wordWrap: PdfWordWrapType.word,
        ),
      );

      y += 70;

      // خط فاصل
      page.graphics.drawLine(
        PdfPen(PdfColor(0, 0, 0)),
        Offset(0, y),
        Offset(pageWidth, y),
      );

      y += 20;

      // جدول المنتجات
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 5);
      grid.headers.add(1);

      final PdfGridRow header = grid.headers[0];
      header.cells[0].value = '#';
      header.cells[1].value = 'Item';
      header.cells[2].value = 'Qty';
      header.cells[3].value = 'Price';
      header.cells[4].value = 'Total';

      for (int i = 0; i < header.cells.count; i++) {
        header.cells[i].style = PdfGridCellStyle(
          font: boldFont,
          cellPadding: PdfPaddings(left: 6, right: 6, top: 6, bottom: 6),
        );
      }

      int index = 1;
      for (var item in cart) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = index.toString();
        row.cells[1].value = item.product.name;
        row.cells[2].value = item.quantity.toString();
        row.cells[3].value = item.unitPrice.toStringAsFixed(2);
        row.cells[4].value = item.total.toStringAsFixed(2);

        for (int i = 0; i < row.cells.count; i++) {
          row.cells[i].style = PdfGridCellStyle(
            font: contentFont,
            cellPadding: PdfPaddings(left: 6, right: 6, top: 6, bottom: 6),
          );
        }

        index++;
      }

      final PdfLayoutResult result =
          grid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageWidth, 0))!;

      y = result.bounds.bottom + 20;
      double rightX = pageWidth - 200;

      // ===== عرض الإجمالي (Total) =====
      page.graphics.drawString(
        'Total',
        boldFont,
        bounds: Rect.fromLTWH(rightX, y, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );
      page.graphics.drawString(
        total.toStringAsFixed(2),
        contentFont,
        bounds: Rect.fromLTWH(rightX + 100, y, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      y += 25;

      // ===== المدفوع (Paid) بعد الخصم =====
      page.graphics.drawString(
        'Paid',
        boldFont,
        bounds: Rect.fromLTWH(rightX, y, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );
      page.graphics.drawString(
        paid.toStringAsFixed(2),
        contentFont,
        bounds: Rect.fromLTWH(rightX + 100, y, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      y += 25;

      // ===== الخصم (Current Due) =====
      page.graphics.drawString(
        'Discount',
        boldFont,
        bounds: Rect.fromLTWH(rightX, y, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );
      page.graphics.drawString(
        discount.toStringAsFixed(2),
        contentFont,
        bounds: Rect.fromLTWH(rightX + 100, y, 100, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );

      // حفظ الملف
      final bytes = await document.save();
      document.dispose();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invoice_$invoiceNumber.pdf');
      await file.writeAsBytes(bytes, flush: true);

      // أغلق الـ loading dialog أولاً
      Navigator.of(context, rootNavigator: true).pop();

      // ثم افتح صفحة الـ PDF
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => PdfViewPage(file: file)));
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  Future<void> submitSale() async {
    if (cart.isEmpty) return;

    final token = await AuthService.getToken();

    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final data = {
      "sale_date": DateTime.now().toIso8601String().split('T').first,
      "client_id": selectedClient?.id ?? 0,
      "total_amount": cartTotal,
      "paid_amount": totalAfterDiscount - remainingAmount,
      "discount_amount": calculatedDiscount,
      "items":
          cart.map((item) {
            return {
              "product_id": item.product.id,
              "quantity": item.quantity,
              "unit_price": item.unitPrice,
              "total_price": item.total,
            };
          }).toList(),
      "payments": payments,
    };

    try {
      await dio.post(
        '${ApiConfig.baseUrl}/sales-api/public/api/sales',
        data: data,
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل إتمام البيع')));
    }
  }

  Widget _qtyButton({
    required IconData icon,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'بيع جديد',
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            onPressed: () {
              setState(() {
                saleStarted = true;
                cart.clear();
                remainingAmount = 0;
                payments.clear();
              });
            },
          ),
          IconButton(
            tooltip: 'العمليات السابقة',
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () async {
              final sale = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
              );
              if (sale != null) _loadSaleForEdit(sale);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====== شريط البحث ======
            RawAutocomplete<Product>(
              textEditingController: _searchController,
              focusNode: _searchFocusNode,

              displayStringForOption: (p) => p.name,

              optionsBuilder: (TextEditingValue value) {
                if (!saleStarted) return const Iterable<Product>.empty();

                final query = value.text.toLowerCase();
                if (query.isEmpty) return products;

                return products.where(
                  (p) => p.name.toLowerCase().contains(query),
                );
              },

              onSelected: (product) {
                addToCart(product);

                // امسحي النص
                _searchController.clear();

                // 👈 اقفلي الدروب داون
                _searchFocusNode.unfocus();
              },

              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: saleStarted,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'ابحث عن منتج',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon:
                        controller.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                focusNode.requestFocus();
                              },
                            )
                            : null,
                  ),
                );
              },

              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Material(
                    elevation: 4,
                    child: SizedBox(
                      height: 250,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final product = options.elementAt(index);

                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        product.stockQuantity != null &&
                                                product.stockQuantity! > 0
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${product.stockQuantity ?? 0}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          product.stockQuantity != null &&
                                                  product.stockQuantity! > 0
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            onTap: () => onSelected(product),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            // ====== السلة ======
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child:
                    cart.isEmpty
                        ? const Center(
                          child: Text(
                            'السلة فارغة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: cart.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            return Card(
                              key: ValueKey(
                                item.product.id,
                              ), // مهم لإعادة البناء
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    // اسم المنتج و السعر
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text('سعر الوحدة: '),

                                              Expanded(
                                                child:
                                                    item.isEditingPrice
                                                        ? SizedBox(
                                                          height: 36,
                                                          child: TextField(
                                                            keyboardType:
                                                                const TextInputType.numberWithOptions(
                                                                  decimal: true,
                                                                ),
                                                            textAlignVertical:
                                                                TextAlignVertical
                                                                    .center,
                                                            decoration: const InputDecoration(
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 8,
                                                                  ),
                                                              border:
                                                                  OutlineInputBorder(),
                                                            ),
                                                            onSubmitted: (v) {
                                                              setState(() {
                                                                cart[index] = CartItem(
                                                                  product:
                                                                      item.product,
                                                                  quantity:
                                                                      item.quantity,
                                                                  unitPrice:
                                                                      double.tryParse(
                                                                        v,
                                                                      ) ??
                                                                      item.unitPrice,
                                                                  isEditingPrice:
                                                                      false,
                                                                );
                                                              });
                                                            },
                                                          ),
                                                        )
                                                        : InkWell(
                                                          onTap:
                                                              () => setState(() {
                                                                cart[index] = CartItem(
                                                                  product:
                                                                      item.product,
                                                                  quantity:
                                                                      item.quantity,
                                                                  unitPrice:
                                                                      item.unitPrice,
                                                                  isEditingPrice:
                                                                      true,
                                                                );
                                                              }),
                                                          child: Text(
                                                            item.unitPrice
                                                                .toStringAsFixed(
                                                                  2,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: const TextStyle(
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                          ),
                                                        ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // أزرار الكمية والحذف
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            // زر النقصان
                                            _qtyButton(
                                              icon: Icons.remove,
                                              onPressed: () {
                                                if (item.quantity > 1) {
                                                  setState(() {
                                                    cart[index] = CartItem(
                                                      product: item.product,
                                                      quantity:
                                                          item.quantity - 1,
                                                      unitPrice: item.unitPrice,
                                                      isEditingPrice:
                                                          item.isEditingPrice,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                            SizedBox(
                                              width: 28,
                                              child: Center(
                                                child: Text('${item.quantity}'),
                                              ),
                                            ),
                                            // زر الزيادة
                                            _qtyButton(
                                              icon: Icons.add,
                                              onPressed: () {
                                                if (item.quantity <
                                                    item
                                                        .product
                                                        .stockQuantity) {
                                                  setState(() {
                                                    cart[index] = CartItem(
                                                      product: item.product,
                                                      quantity:
                                                          item.quantity + 1,
                                                      unitPrice: item.unitPrice,
                                                      isEditingPrice:
                                                          item.isEditingPrice,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                            // زر الحذف
                                            _qtyButton(
                                              icon: Icons.delete,
                                              color: Colors.red,
                                              onPressed:
                                                  () => setState(
                                                    () => cart.removeAt(index),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'المخزون: ${cart[index].product.stockQuantity ?? 0}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                cart[index]
                                                                .product
                                                                .stockQuantity !=
                                                            null &&
                                                        cart[index]
                                                                .product
                                                                .stockQuantity! >
                                                            0
                                                    ? Colors.green.shade800
                                                    : Colors.red.shade800,
                                          ),
                                        ),

                                        // إجمالي المنتج
                                        Text(
                                          'الإجمالي: ${numberFormat.format(cart[index].total)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),

            const SizedBox(height: 8),
            // ====== قسم العميل والدفع يظهر فقط إذا كانت هناك منتجات في السلة ======
            if (cart.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== العميل =====
                      DropdownButtonFormField<Client>(
                        decoration: const InputDecoration(
                          labelText: 'اختر العميل',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            clients
                                .map(
                                  (client) => DropdownMenuItem(
                                    value: client,
                                    child: Text(client.name),
                                  ),
                                )
                                .toList(),
                        value: selectedClient,
                        onChanged:
                            (value) => setState(() => selectedClient = value),
                      ),

                      const SizedBox(height: 8),

                      // ===== التاريخ والوقت =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التاريخ: ${saleDateTime.year}-${saleDateTime.month.toString().padLeft(2, '0')}-${saleDateTime.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'الوقت: ${saleDateTime.hour.toString().padLeft(2, '0')}:${saleDateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      // ===== زر الخصم =====
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _showDiscountDialog,
                          child: const Text(
                            'الخصم',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const Divider(),

                      // ===== المجموع الفرعي =====
                      Row(
                        children: [
                          const Text('المجموع الفرعي'),
                          const Spacer(),
                          Text(numberFormat.format(cartTotal)),
                        ],
                      ),

                      // ===== الخصم (لو موجود) =====
                      if (calculatedDiscount > 0)
                        Row(
                          children: [
                            const Text('الخصم'),
                            const Spacer(),
                            Text(
                              '- ${numberFormat.format(calculatedDiscount)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),

                      const SizedBox(height: 6),

                      // ===== الإجمالي بعد الخصم =====
                      Row(
                        children: [
                          const Text(
                            'الإجمالي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            numberFormat.format(totalAfterDiscount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ===== الأزرار =====
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (selectedClient == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('اختر العميل أولاً'),
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                );

                                try {
                                  await _generatePdfInvoice(context);
                                } catch (e) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ عند إنشاء الفاتورة'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('فاتورة PDF'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  65,
                                  134,
                                  67,
                                ),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                remainingAmount = totalAfterDiscount;
                                payments.clear();
                                _showPaymentDialog();
                              },
                              child: const Text('الدفع'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
