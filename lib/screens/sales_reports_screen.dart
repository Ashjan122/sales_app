import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  static const Color primaryColor = Color(0xFF213D5C);
  final Dio dio = Dio();
  bool isLoading = true;
  bool showSummaryPage = true; 
  List<dynamic> sales = [];

  // فلترة
  List<dynamic> clients = [];
  List<dynamic> products = [];
  dynamic selectedClient;
  dynamic selectedProduct;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  // ملخص اليوم
  int totalAmountToday = 0;
  int paidAmountToday = 0;
  int discountAmountToday = 0;
  int dueAmountToday = 0;

  int totalExpensesToday = 0;
  int cashExpensesToday = 0;
  int bankExpensesToday = 0;

  List<dynamic> shifts = [];
dynamic selectedShift;


  @override
  void initState() {
    super.initState();
    fetchFiltersData();
    fetchShifts();
    fetchTodaySummary();
    fetchTodayExpenses();
  }

  Future<void> fetchTodayExpenses() async {
  try {
    final token = await AuthService.getToken();
    String url = '${ApiConfig.baseUrl}/sales-api/public/api/admin/expenses?page=1&per_page=1000';

    // إذا الوردية محددة
    if (selectedShift != null) {
      url += '&shift_id=${selectedShift['id']}';
    } else {
      final formatter = intl.DateFormat('yyyy-MM-dd');
      final today = formatter.format(DateTime.now());
      url += '&date_from=$today&date_to=$today';
    }

    final response = await dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final expenses = response.data['data'] ?? [];

    int total = 0;
    int cash = 0;
    int bank = 0;

    for (var expense in expenses) {
      final amount = parseAmount(expense['amount']);
      total += amount;

      if (expense['payment_method'] == 'cash') {
        cash += amount;
      } else if (expense['payment_method'] == 'bank') {
        bank += amount;
      }
    }

    setState(() {
      totalExpensesToday = total;
      cashExpensesToday = cash;
      bankExpensesToday = bank;
    });
  } catch (e) {
    debugPrint('Error fetching expenses summary: $e');
  }
}

  Future<void> fetchShifts() async {
  try {
    final token = await AuthService.getToken();
    final response = await dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/shifts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    shifts = response.data['data'] ?? [];

    // تحديد آخر وردية تلقائيًا
    if (shifts.isNotEmpty) {
      shifts.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int)); // ترتيب تنازلي
      selectedShift = shifts.first;
      fetchSales(); // جلب المبيعات بعد تحديد آخر وردية
      fetchTodaySummary();
  fetchTodayExpenses();
    }

    setState(() {});
  } catch (e) {
    debugPrint('Error fetching shifts: $e');
  }
}


  Future<void> fetchFiltersData() async {
    try {
      final token = await AuthService.getToken();

      // جلب العملاء
      final clientsResponse = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/clients?page=1',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      clients = clientsResponse.data['data'];

      // جلب المنتجات
      final productsResponse = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/products?page=1&per_page=1000&sort_by=created_at&sort_direction=desc',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      products = productsResponse.data['data'];

      setState(() {});
      fetchSales(); // تحميل المبيعات بعد تحضير الفلاتر
    } catch (e) {
      debugPrint('Error fetching filters: $e');
    }
  }

  Future<void> fetchTodaySummary() async {
  setState(() => isLoading = true);
  try {
    final token = await AuthService.getToken();

    String url =
        '${ApiConfig.baseUrl}/sales-api/public/api/reports/sales?page=1&per_page=500';

    // إذا الوردية محددة
    if (selectedShift != null) {
      url += '&shift_id=${selectedShift['id']}';
    } else {
      final formatter = intl.DateFormat('yyyy-MM-dd');
      final today = formatter.format(DateTime.now());
      url += '&start_date=$today&end_date=$today&pos_mode=days';
    }

    final response = await dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final todaySales = response.data['data'] ?? [];

    int total = 0, paid = 0, discount = 0, due = 0;

    for (var sale in todaySales) {
      total += parseAmount(sale['total_amount']);
      paid += parseAmount(sale['paid_amount']);
      discount += parseAmount(sale['discount_amount']);
      due += parseAmount(sale['due_amount']);
    }

    setState(() {
      totalAmountToday = total;
      paidAmountToday = paid;
      discountAmountToday = discount;
      dueAmountToday = due;
      isLoading = false;
    });
  } catch (e) {
    debugPrint('Error fetching today summary: $e');
    setState(() => isLoading = false);
  }
}

  Future<void> fetchSales() async {
  setState(() => isLoading = true);
  try {
    final token = await AuthService.getToken();
    final formatter = intl.DateFormat('yyyy-MM-dd');

    String url =
        '${ApiConfig.baseUrl}/sales-api/public/api/reports/sales?page=1&per_page=500';

    // إذا الوردية محددة
    if (selectedShift != null) {
      url += '&shift_id=${selectedShift['id']}';
    } else {
      url += '&start_date=${formatter.format(startDate)}&end_date=${formatter.format(endDate)}';
    }

    if (selectedClient != null) {
      url += '&client_id=${selectedClient['id']}';
    }
    if (selectedProduct != null) {
      url += '&product_id=${selectedProduct['id']}';
    }

    final response = await dio.get(
      url,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    setState(() {
      sales = response.data['data'] ?? [];
      isLoading = false;
    });
  } catch (e) {
    debugPrint('Error fetching sales: $e');
    setState(() => isLoading = false);
  }
}

  int parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  void showSaleDetails(dynamic sale) {
    final clientName = sale['client_name'] ?? '';
    final userName = sale['user_name'] ?? '';
    final saleNumber = sale['id'] ?? '';
    final saleDate = sale['sale_date'] ?? '';
    final totalAmount = parseAmount(sale['total_amount']);
    final discountAmount = parseAmount(sale['discount_amount']);
    final dueAmount = parseAmount(sale['due_amount']);
    final paymentsCount = (sale['payments'] as List).length;
    final paidAmount = parseAmount(sale['paid_amount']);
    final notes = sale['notes'] ?? '';

    final formatter = intl.NumberFormat('#,###');

    showDialog(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text('تفاصيل العملية رقم $saleNumber'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المستخدم: $userName'),
                  const SizedBox(height: 4),
                  Text(' المبلغ الاجمالي: ${formatter.format(totalAmount)}'),
                  const SizedBox(height: 4),
                  Text('المدفوع: ${formatter.format(paidAmount)}'),
                  const SizedBox(height: 4),
                  Text('عدد الدفعات: $paymentsCount'),
                  const SizedBox(height: 4),
                  Text('الخصم: ${formatter.format(discountAmount)}'),
                  const SizedBox(height: 4),
                  Text('المستحق: ${formatter.format(dueAmount)}'),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('ملاحظات: $notes'),
                  ],
                ],
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

  Widget buildSaleItem(dynamic sale) {
    final clientName = sale['client_name'] ?? '';
    final saleNumber = sale['id'] ?? '';
    final saleDate = sale['sale_date'] ?? '';
    final totalAmount = parseAmount(sale['total_amount']);
    final paymentsCount = (sale['payments'] as List).length;
    final paidAmount = parseAmount(sale['paid_amount']);
    final formatter = intl.NumberFormat('#,###');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'رقم العملية: $saleNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'التاريخ: $saleDate',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'العميل: $clientName',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'المبلغ الإجمالي: ${formatter.format(totalAmount)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFilters() {
    final dateFormatter = intl.DateFormat('yyyy-MM-dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                    fetchSales();
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'من',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    controller: TextEditingController(
                      text: dateFormatter.format(startDate),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => endDate = picked);
                    fetchSales();
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'إلى',
                      border: OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    controller: TextEditingController(
                      text: dateFormatter.format(endDate),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        
        
        Row(
          children: [
            Flexible(
              child: DropdownButtonFormField<dynamic>(
                isExpanded: true,
                value: selectedClient,
                decoration: const InputDecoration(
                  labelText: 'العميل',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items:
                    clients.map((client) {
                      return DropdownMenuItem(
                        value: client,
                        child: Text(
                          client['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() => selectedClient = val);
                  fetchSales();
                },
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: DropdownButtonFormField<dynamic>(
                isExpanded: true,
                value: selectedProduct,
                decoration: const InputDecoration(
                  labelText: 'المنتج',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items:
                    products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(
                          product['name'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() => selectedProduct = val);
                  fetchSales();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 5,),
        Row(
  children: [
    Flexible(
      child: DropdownButtonFormField<dynamic>(
        isExpanded: true,
        value: selectedShift,
        decoration: const InputDecoration(
          labelText: 'الوردية',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: shifts.map((shift) {
          return DropdownMenuItem(
            value: shift,
            child: Text(
              shift['name'],
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (val) {
          setState(() => selectedShift = val);
          fetchSales();
        },
      ),
    ),
  ],
),

      ],
    );
  }

  Widget buildSummaryPage() {
    final formatter = intl.NumberFormat('#,###');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  summaryCard(
                    title: 'إجمالي المبيعات',
                    value: totalAmountToday,
                    color: Colors.blue,
                    icon: Icons.attach_money,
                    formatter: formatter,
                  ),
                  summaryCard(
                    title: 'المدفوع',
                    value: paidAmountToday,
                    color: Colors.green,
                    icon: Icons.payments,
                    formatter: formatter,
                  ),
                  summaryCard(
                    title: 'الخصم',
                    value: discountAmountToday,
                    color: Colors.orange,
                    icon: Icons.discount,
                    formatter: formatter,
                  ),
                  summaryCard(
                    title: 'المستحق',
                    value: dueAmountToday,
                    color: Colors.red,
                    icon: Icons.account_balance_wallet,
                    formatter: formatter,
                  ),
                  summaryCard(
                    title: 'إجمالي المصروفات',
                    value: totalExpensesToday,
                    color: Colors.purple,
                    icon: Icons.money_off,
                    formatter: formatter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() => showSummaryPage = false);
                },
                child: const Text(
                  'عرض تفاصيل المبيعات',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء كارد
  Widget summaryCard({
    required String title,
    required int value,
    required Color color,
    required IconData icon,
    required intl.NumberFormat formatter,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(value),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تقرير المبيعات',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryColor,
          centerTitle: true,
          leading:
              !showSummaryPage
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() => showSummaryPage = true);
                      fetchTodaySummary(); // تحديث الملخص عند العودة
                      fetchTodayExpenses();
                    },
                  )
                  : null,
        ),
        body: SafeArea(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : showSummaryPage
                  ? buildSummaryPage()
                  : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        buildFilters(),
                        const SizedBox(height: 16),
                        Expanded(
                          child:
                              sales.isEmpty
                                  ? const Center(child: Text('لا توجد مبيعات'))
                                  : ListView.builder(
                                    itemCount: sales.length,
                                    itemBuilder: (context, index) {
                                      return buildSaleItem(sales[index]);
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
