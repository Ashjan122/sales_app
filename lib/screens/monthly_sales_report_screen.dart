import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:jawda_sales/screens/pdf_view_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class MonthlySalesReportPage extends StatefulWidget {
  final int month;
  final int year;

  const MonthlySalesReportPage({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<MonthlySalesReportPage> createState() =>
      _MonthlySalesReportPageState();
}

class _MonthlySalesReportPageState extends State<MonthlySalesReportPage> {
  final Dio dio = Dio();
  final intl.NumberFormat formatter = intl.NumberFormat('#,###');

  final Color primaryColor = const Color(0xFF213D5C);

  bool isLoading = true;

  List<dynamic> dailyBreakdown = [];
  Map<String, dynamic>? monthSummary;

  late int selectedMonth;
  late int selectedYear;

  /// أسماء الشهور بالعربي
  final List<String> arabicMonths = const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  final List<int> years = List.generate(
    5,
    (index) => DateTime.now().year - index,
  );

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.month;
    selectedYear = widget.year;
    fetchMonthlyReport();
  }

  Future<void> fetchMonthlyReport() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/reports/monthly-revenue',
        queryParameters: {
          'month': selectedMonth,
          'year': selectedYear,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      final data = response.data['data'];

      setState(() {
        dailyBreakdown = data['daily_breakdown'] ?? [];
        monthSummary = data['month_summary'];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Monthly report error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل في تحميل تقرير المبيعات')),
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

  TableRow buildRow(Map<String, dynamic> e,
      {bool isSummary = false}) {
    return TableRow(
      decoration: isSummary
          ? BoxDecoration(color: Colors.grey.shade200)
          : null,
      children: [
        buildCell(isSummary ? 'الإجمالي' : e['date']),
        buildCell(formatter.format(e['total_sales'] ?? 0)),
        buildCell(formatter.format(e['total_paid'] ?? 0)),
        buildCell(formatter.format(e['total_cash'] ?? 0)),
        buildCell(formatter.format(e['total_bank'] ?? 0)),
        buildCell(formatter.format(e['total_expense'] ?? 0),
            color: Colors.red),
        buildCell(formatter.format(e['net'] ?? 0),
            color: Colors.green),
      ],
    );
  }
 Future<void> generateMonthlySalesPdf() async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
  );

  final pdf = pw.Document();
  final today = DateTime.now().toString().substring(0, 10);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {
        return [
          // ✅ العنوان في منتصف الصفحة
          pw.Center(
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'تقرير المبيعات الشهري',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),

          pw.SizedBox(height: 8),

          // الشهر
          pw.Container(
            width: PdfPageFormat.a4.landscape.width,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'الشهر: ${arabicMonths[selectedMonth - 1]} $selectedYear',
                style: pw.TextStyle(font: font, fontSize: 14),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ),

          // تاريخ الإصدار
          pw.Container(
            width: PdfPageFormat.a4.landscape.width,
            child: pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'تاريخ الإصدار: $today',
                style: pw.TextStyle(font: font, fontSize: 14),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ),

          pw.SizedBox(height: 16),

          // ✅ الجدول
         pw.Directionality(
  textDirection: pw.TextDirection.rtl,
  child: pw.Table(
    border: pw.TableBorder.all(),
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    columnWidths: const {
      0: pw.FlexColumnWidth(2.5),
      1: pw.FlexColumnWidth(2.5),
      2: pw.FlexColumnWidth(2.5),
      3: pw.FlexColumnWidth(2),
      4: pw.FlexColumnWidth(1.5),
      5: pw.FlexColumnWidth(1.5),
      6: pw.FlexColumnWidth(1.5),
    },
    children: [
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFEFEFEF),
        ),
        children: [
          'التاريخ',
          'إجمالي المبيعات',
          'إجمالي المدفوع',
          'النقدي',
          'البنكي',
          'المصروفات',
          'الصافي',
        ].map(
          (e) => pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Align(
              alignment: pw.Alignment.center, // ✅ محاذاة مركزية
              child: pw.Text(
                e,
                style: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ).toList(),
      ),

      // الصفوف اليومية
      ...dailyBreakdown.map((e) {
        return pw.TableRow(
          children: [
            e['date'] ?? '',
            formatter.format(e['total_sales'] ?? 0),
            formatter.format(e['total_paid'] ?? 0),
            formatter.format(e['total_cash'] ?? 0),
            formatter.format(e['total_bank'] ?? 0),
            formatter.format(e['total_expense'] ?? 0),
            formatter.format(e['net'] ?? 0),
          ].map(
            (v) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  v.toString(),
                  style: pw.TextStyle(font: font),
                ),
              ),
            ),
          ).toList(),
        );
      }),

      // الإجمالي الشهري
      if (monthSummary != null)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F5F5),
          ),
          children: [
            'الإجمالي',
            formatter.format(monthSummary!['total_sales'] ?? 0),
            formatter.format(monthSummary!['total_paid'] ?? 0),
            formatter.format(monthSummary!['total_cash'] ?? 0),
            formatter.format(monthSummary!['total_bank'] ?? 0),
            formatter.format(monthSummary!['total_expense'] ?? 0),
            formatter.format(monthSummary!['net'] ?? 0),
          ].map(
            (v) => pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  v.toString(),
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ).toList(),
        ),
    ],
  ),
),

        ];
      },
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File(
    '${dir.path}/monthly_sales_${selectedMonth}_$selectedYear.pdf',
  );

  await file.writeAsBytes(await pdf.save());

  if (!mounted) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PdfViewPage(file: file),
    ),
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
    'تقرير المبيعات الشهري',
    style: TextStyle(color: Colors.white),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.picture_as_pdf,color: Colors.white,),
      onPressed: isLoading ? null : generateMonthlySalesPdf,
    ),
  ],
),

        body:SafeArea(child:  isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  /// الفلترة
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'الشهر',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: List.generate(12, (index) {
                              final month = index + 1;
                              return DropdownMenuItem(
                                value: month,
                                child: Text(arabicMonths[index]),
                              );
                            }),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedMonth = value);
                              fetchMonthlyReport();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'السنة',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: years.map((year) {
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedYear = value);
                              fetchMonthlyReport();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10 ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Table(
                            border: TableBorder.all(
                                color: Colors.grey.shade300),
                            defaultColumnWidth:
                                const IntrinsicColumnWidth(),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color:
                                      primaryColor.withOpacity(0.1),
                                ),
                                children: [
                                  buildCell('التاريخ',
                                      isHeader: true),
                                  buildCell('إجمالي المبيعات',
                                      isHeader: true),
                                  buildCell('إجمالي المدفوع',
                                      isHeader: true),
                                  buildCell('النقدي',
                                      isHeader: true),
                                  buildCell('البنكي',
                                      isHeader: true),
                                  buildCell('المصروفات',
                                      isHeader: true),
                                  buildCell('الصافي',
                                      isHeader: true),
                                ],
                              ),
                              ...dailyBreakdown
                                  .map((e) => buildRow(e))
                                  .toList(),
                              if (monthSummary != null)
                                buildRow(monthSummary!,
                                    isSummary: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      ),
    );
  }
}
