import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:jawda_sales/screens/Suppliers_screen.dart';
import 'package:jawda_sales/screens/supplier_ledger_screen.dart';

class SuppliersSummaryPage extends StatefulWidget {
  const SuppliersSummaryPage({super.key});

  @override
  State<SuppliersSummaryPage> createState() => _SuppliersSummaryPageState();
}

class _SuppliersSummaryPageState extends State<SuppliersSummaryPage> {
  final Dio dio = Dio();
  final intl.NumberFormat formatter = intl.NumberFormat('#,###');

  final Color primaryColor = const Color(0xFF213D5C);

  bool isLoading = true;
  List<dynamic> suppliers = [];

  @override
  void initState() {
    super.initState();
    fetchSuppliersSummary();
  }

  Future<void> fetchSuppliersSummary() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/suppliers/summary',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      setState(() {
        suppliers = response.data ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Suppliers summary error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحميل ملخص الموردين')),
      );
    }
  }

  Widget buildCell(String text,
      {bool isHeader = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black,
          fontSize: 13,
        ),
      ),
    );
  }

  TableRow buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
      ),
      children: [
        buildCell('اسم المورد', isHeader: true),
        buildCell('إجمالي المدين', isHeader: true),
        buildCell('إجمالي الدائن', isHeader: true),
        buildCell('الرصيد', isHeader: true),
        buildCell('إجراءات', isHeader: true),
      ],
    );
  }

  TableRow buildSupplierRow(dynamic s) {
    return TableRow(
      children: [
        buildCell(s['name'] ?? ''),
        buildCell(formatter.format(s['total_debit'] ?? 0),
            color: Colors.red),
        buildCell(formatter.format(s['total_credit'] ?? 0),
            color: Colors.green),
        buildCell(formatter.format(s['balance'] ?? 0)),
        Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.remove_red_eye),
            color: primaryColor,
            onPressed: () {
  final supplier = Supplier(
    id: s['id'],
    name: s['name'],
    contactPerson: null,
    email: null,
    phone: null,
    address: null,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SupplierLedgerPage(
        supplier: supplier,
      ),
    ),
  );
},

          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: primaryColor,
          centerTitle: true,
          title: const Text(
            'ملخص الموردين',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body:SafeArea(child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                      ),
                      defaultColumnWidth:
                          const IntrinsicColumnWidth(),
                      children: [
                        buildHeaderRow(),
                        ...suppliers.map(buildSupplierRow).toList(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      )
    );
  }
}
