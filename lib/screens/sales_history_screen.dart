import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final Dio dio = Dio();
  List sales = [];
  List filteredSales = [];
  bool loading = true;

  final Color primaryColor = const Color(0xFF213D5C);

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    final token = await AuthService.getToken();
    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final res = await dio.get(
      '${ApiConfig.baseUrl}/sales-api/public/api/sales',
      queryParameters: {'page': 1},
    );

    setState(() {
      sales = res.data['data'];
      filteredSales = List.from(sales);
      loading = false;
    });
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;

        // فلترة العمليات حسب التاريخ (yyyy-mm-dd)
        final formatted = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";

        filteredSales = sales.where((sale) {
          final saleDate = sale['sale_date'] ?? sale['created_at'] ?? '';
          return saleDate.startsWith(formatted);
        }).toList();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      selectedDate = null;
      filteredSales = List.from(sales);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'العمليات السابقة',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // 👈 فلتر التاريخ
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _pickDate,
                          icon:  Icon(Icons.date_range,color:primaryColor,),
                          label: Text(
                            selectedDate == null
                                ? 'بحث بالتاريخ '
                                : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}",
                                style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                      if (selectedDate != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _clearFilter,
                          icon: const Icon(Icons.clear, color: Colors.red),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 👈 GridView العمليات
                  Expanded(
                    child: GridView.builder(
                      itemCount: filteredSales.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final sale = filteredSales[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(context, sale);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            elevation: 2,
                            child: Center(
                              child: Text(
                                '#${sale['id']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
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
