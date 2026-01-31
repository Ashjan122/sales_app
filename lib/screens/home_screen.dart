import 'dart:math';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart' show AuthService;
import 'package:jawda_sales/screens/dashboard_screen.dart';
import 'package:jawda_sales/screens/inventory_dashboard_screen.dart';
import 'package:jawda_sales/screens/login_screen.dart';
import 'package:jawda_sales/screens/managment_dashboard_screen.dart';
import 'package:jawda_sales/screens/purchases_dashboard_screen.dart';
import 'package:jawda_sales/screens/reports_dashboard_screen.dart';
import 'package:jawda_sales/screens/sales_dashboard_screen.dart';
import 'package:jawda_sales/screens/sales_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final List<Widget> pages = [
      OverviewPage(),
      SalesPage(),
      PurchasesPage(),
      InventoryPage(),
      DashboardScreen(),
    ];
    String username = "اسم المستخدم";
    final titles = [
  "Overview",
  "المبيعات",
  "المشتريات",
  "المنتجات",
  "لوحة التحكم",
];


@override
void initState() {
  super.initState();
  loadUsername();
}

Future<void> loadUsername() async {
  final name = await AuthService.getUsername();
  if (name != null) {
    setState(() {
      username = name;
    });
  }
}

   Widget _buildEndDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 30),
          color: Color(0xFF213D5C),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 45,
                  color: Color(0xFF213D5C),
                ),
              ),
              SizedBox(height: 12),
              Text(
  username,
  style: TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

            ],
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                // حذف التوكن
                await AuthService.clearToken();
                // العودة لشاشة تسجيل الدخول وإزالة كل الشاشات السابقة
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF213D5C)),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "تسجيل الخروج",
                style: TextStyle(
                  color: Color(0xFF213D5C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 40),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
  titles[currentIndex],
  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
),

        actions: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Scaffold.of(context).openEndDrawer();
              },
              child: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.black),
              ),
            ),
          ),
          SizedBox(width: 15),
        ],

      ),
      endDrawer: _buildEndDrawer(context),
      body: pages[currentIndex],
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => currentIndex = 0),
                icon: Icon(
                  Icons.grid_view,
                  color: currentIndex == 0 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 1),
                icon: Icon(
                  Icons.shopping_cart,
                  color: currentIndex == 1 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 2),
                icon: Icon(
                  Icons.sell,
                  color: currentIndex == 2 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 3),
                icon: Icon(
                  Icons.inventory_2,
                  color: currentIndex == 3 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
  onPressed: () => setState(() => currentIndex = 4),
  icon: Icon(
    Icons.home,
    color: currentIndex == 4 ? Color(0xFF213D5C) : Colors.grey,
  ),
),


            ],
          ),
        ),
      ),);
    
    

}}
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  bool isLoading = true;
  Map<String, dynamic>? dashboard;

  final numberFormat = intl.NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    fetchDashboardSummary();
  }

  Future<void> fetchDashboardSummary() async {
    try {
      final token = await AuthService.getToken();
      final response = await Dio().get(
        '${ApiConfig.baseUrl}/sales-api/public/api/dashboard/summary',
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      if (!mounted) return;

      setState(() {
        dashboard = response.data['data'];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحميل البيانات'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _card({
  required String title,
  required Widget content,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(
        color: Color(0xFF213D5C), 
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDashboardSummary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _card(
                    title: 'مبيعات الشهر الحالي',
                    content: Text(
                      numberFormat.format(
                        dashboard!['sales']['this_month_amount'],
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _card(
                    title: 'مشتريات الشهر الحالي',
                    content: Text(
                      numberFormat.format(
                        dashboard!['purchases']['this_month_amount'],
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _card(
                    title: 'إجمالي العملاء',
                    content: Text(
                      numberFormat.format(
                        dashboard!['entities']['total_clients'],
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _card(
                    title: 'إجمالي المنتجات',
                    content: Text(
                      numberFormat.format(
                        dashboard!['inventory']['total_products'],
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _card(
                    title: 'إجمالي الموردين',
                    content: Text(
                      numberFormat.format(
                        dashboard!['entities']['total_suppliers'],
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _card(
                    title: 'المنتجات منخفضة المخزون',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          numberFormat.format(
                            dashboard!['inventory']['low_stock_count'],
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'نفذ المخزون : ${numberFormat.format(
                            dashboard!['inventory']['out_of_stock_count'],
                          )}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}








// ====================== بيانات الشهر ======================
class MonthData {
  final String month;
  final double amount;
  MonthData(this.month, this.amount);
}

// ====================== بيانات المنتج ======================
class ProductData {
  final String name;
  final double quantity;
  final Color color;

  ProductData({
    required this.name,
    required this.quantity,
    required this.color,
  });
}

// ====================== مخطط المبيعات ======================
class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool isLoading = true;
  final List<double> monthlyTotals = List.filled(12, 0);
  final Color primaryColor = const Color(0xFF213D5C);
  final numberFormat = intl.NumberFormat('#,##0', 'en_US');

  final Map<int, String> arabicMonths = const {
    1: 'يناير',
    2: 'فبراير',
    3: 'مارس',
    4: 'أبريل',
    5: 'مايو',
    6: 'يونيو',
    7: 'يوليو',
    8: 'أغسطس',
    9: 'سبتمبر',
    10: 'أكتوبر',
    11: 'نوفمبر',
    12: 'ديسمبر',
  };

  @override
  void initState() {
    super.initState();
    fetchYearlySales();
  }

  Future<void> fetchYearlySales() async {
    try {
      final token = await AuthService.getToken();
      final dio = Dio();

      for (int month = 1; month <= 12; month++) {
        final response = await dio.get(
          '${ApiConfig.baseUrl}/sales-api/public/api/reports/monthly-revenue',
          queryParameters: {'month': month, 'year': DateTime.now().year},
          options: Options(headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          }),
        );

        final total =
            response.data['data']['month_summary']['total_revenue'] ?? 0;

        monthlyTotals[month - 1] = (total as num).toDouble();
      }

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحميل مخطط المبيعات'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white,),
                  label: const Text(
                    'بيع جديد',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF213D5C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(
                      numberFormat: numberFormat,
                      title: AxisTitle(text: 'الإيرادات'),
                    ),
                    title: ChartTitle(text: 'المبيعات خلال أشهر السنة'),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<MonthData, String>>[
                      ColumnSeries<MonthData, String>(
                        dataSource: List.generate(
                          12,
                          (i) =>
                              MonthData(arabicMonths[i + 1]!, monthlyTotals[i]),
                        ),
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.amount,
                        pointColorMapper: (_, __) => primaryColor,
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}

}

// ====================== مخطط المشتريات ======================
class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends State<PurchasesPage> {
  bool isLoading = true;
  final List<double> monthlyTotals = List.filled(12, 0);
  final Color primaryColor = const Color(0xFF213D5C);
  final numberFormat = intl.NumberFormat('#,##0', 'en_US');

  final Map<int, String> arabicMonths = const {
    1: 'يناير',
    2: 'فبراير',
    3: 'مارس',
    4: 'أبريل',
    5: 'مايو',
    6: 'يونيو',
    7: 'يوليو',
    8: 'أغسطس',
    9: 'سبتمبر',
    10: 'أكتوبر',
    11: 'نوفمبر',
    12: 'ديسمبر',
  };

  @override
  void initState() {
    super.initState();
    fetchYearlyPurchases();
  }

  Future<void> fetchYearlyPurchases() async {
    try {
      final token = await AuthService.getToken();
      final dio = Dio();

      for (int month = 1; month <= 12; month++) {
        final response = await dio.get(
          '${ApiConfig.baseUrl}/sales-api/public/api/reports/monthly-purchases',
          queryParameters: {'month': month, 'year': DateTime.now().year},
          options: Options(headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          }),
        );

        final total =
            response.data['data']['month_summary']['total_amount_purchases'] ?? 0;

        monthlyTotals[month - 1] = (total as num).toDouble();
      }

      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحميل مخطط المشتريات'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(
                  numberFormat: numberFormat,
                  title: AxisTitle(text: 'المشتريات'),
                ),
                title: ChartTitle(text: 'المشتريات خلال أشهر السنة'),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<MonthData, String>>[
                  ColumnSeries<MonthData, String>(
                    dataSource: List.generate(
                      12,
                      (i) =>
                          MonthData(arabicMonths[i + 1]!, monthlyTotals[i]),
                    ),
                    xValueMapper: (data, _) => data.month,
                    yValueMapper: (data, _) => data.amount,
                    pointColorMapper: (_, __) => primaryColor,
                    dataLabelSettings:
                        const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
      ),
    );
  }
}

// ====================== مخطط المخزون ======================

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<ProductData> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTopProducts();
  }

  /// ألوان ثابتة لكل منتج
  Color getRandomColor(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.indigo,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Future<void> fetchTopProducts() async {
    try {
      final token = await AuthService.getToken();
      final dio = Dio();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/reports/top-products',
        queryParameters: {
          'start_date': '2025-12-31',
          'end_date': '2026-01-21',
          'limit': 10
        },
        options: Options(headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        chartData = data.asMap().entries.map((entry) {
          final e = entry.value;
          double qty = 0;

          if (e['total_qty'] is int) {
            qty = (e['total_qty'] as int).toDouble();
          } else if (e['total_qty'] is String) {
            qty = double.tryParse(e['total_qty']) ?? 0;
          }

          return ProductData(
            name: e['product_name'] ?? 'غير معروف',
            quantity: qty,
            color: getRandomColor(entry.key),
          );
        }).toList();
      } else {
        throw Exception(
            'Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحميل المخطط: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المنتجات الأكثر مبيعًا')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : chartData.isEmpty
                ? const Center(child: Text('لا توجد بيانات لعرضها'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // المخطط الدائري بدون النسب
                        SizedBox(
                          height: 250,
                          child: SfCircularChart(
                            legend: Legend(
                              isVisible: false, // نخفي legend هنا
                            ),
                            series: <PieSeries<ProductData, String>>[
                              PieSeries<ProductData, String>(
                                dataSource: chartData,
                                xValueMapper: (data, _) => data.name,
                                yValueMapper: (data, _) => data.quantity,
                                pointColorMapper: (data, _) => data.color,
                                dataLabelSettings:
                                    const DataLabelSettings(isVisible: false),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // قائمة الأسماء مع الألوان أسفل المخطط Scrollable
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chartData.length,
                          itemBuilder: (context, index) {
                            final item = chartData[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Widget _buildCard({
    required String lottiePath, 
    required String title,
    required Color borderColor,
    required Color circleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // الدائرة الكبيرة
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: circleColor, width: 2),
                  ),
                ),

                // الدائرة الثانية
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor.withOpacity(0.15),
                  ),
                ),

                SizedBox(
                  width: 40,
                  height: 40,
                  child: Lottie.asset(lottiePath, fit: BoxFit.contain),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
        
        body: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.05,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildCard(
          lottiePath: "assets/lottie/Chart Increasing (1).json",
          title: "المبيعات",
          borderColor: Color(0xFF213D5C),
          circleColor: Color(0xFF213D5C),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SalesDashboardScreen()));
          },
        ),
        _buildCard(
          lottiePath: "assets/lottie/Loss down growth (1).json",
          title: "المشتريات",
          borderColor: Color(0xFF213D5C),
          circleColor: Color(0xFF213D5C),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PurchasesDashboardScreen()),
            );
          },
        ),
        
        _buildCard(
          lottiePath: "assets/lottie/Inventory (1).json",
          title: "المخزون",
          borderColor: Color(0xFF213D5C),
          circleColor: Color(0xFF213D5C),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InventoryDashboardScreen()));
          },
        ),
        
       
        _buildCard(
          lottiePath: "assets/lottie/Gears Lottie Animation.json",
          title: "الإدارة",
          borderColor: Color(0xFF213D5C),
          circleColor: Color(0xFF213D5C),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManagementDashboardScreen()));
          },
        ),
        _buildCard(
          lottiePath: "assets/lottie/accounting (1).json",
          title: "التقارير",
          borderColor: Color(0xFF213D5C),
          circleColor: Color(0xFF213D5C),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder:(context) => ReportsDashboardScreen(),));
          },
        ),
      ],
    ),
  ),
),
),
    );
  }
}

