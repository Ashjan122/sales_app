import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:jawda_sales/screens/pdf_view_screen.dart';

class ClientLedgerPage extends StatefulWidget {
  final int clientId;
  final String clientName;

  const ClientLedgerPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientLedgerPage> createState() => _ClientLedgerPageState();
}

class _ClientLedgerPageState extends State<ClientLedgerPage> {
  final Dio dio = Dio();
  final intl.NumberFormat amountFormatter = intl.NumberFormat('#,###');
  final Color primaryColor = const Color(0xFF213D5C);

  bool isLoading = true;
  bool showDetails = false;

  int totalSales = 0;
  int totalPayments = 0;
  int balance = 0;

  List<dynamic> ledgerEntries = [];

  @override
  void initState() {
    super.initState();
    fetchLedger();
  }

  Future<void> fetchLedger() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/clients/${widget.clientId}/ledger',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      final data = response.data;

      setState(() {
        totalSales = (data['summary']['total_sales'] ?? 0).toInt();
        totalPayments = (data['summary']['total_payments'] ?? 0).toInt();
        balance = (data['summary']['balance'] ?? 0).toInt();
        ledgerEntries = data['ledger_entries'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Client ledger error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل في جلب بيانات كشف الحساب")),
      );
    }
  }

  int parseAmount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return double.tryParse(v.toString())?.toInt() ?? 0;
  }

  String translateType(String type) {
    switch (type) {
      case 'sale':
        return 'بيع';
      case 'payment':
        return 'دفعة';
      case 'adjustment':
        return 'تسوية';
      default:
        return type;
    }
  }

  Color typeColor(String type) {
    switch (type) {
      case 'sale':
        return Colors.red;
      case 'payment':
        return Colors.green;
      case 'adjustment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget summaryCard(String title, int value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                Text(amountFormatter.format(value),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget ledgerRow(dynamic e) {
    final debit = parseAmount(e['debit']);
    final credit = parseAmount(e['credit']);
    final balanceValue = parseAmount(e['balance']);
    final date =
        e['created_at'] != null ? e['created_at'].toString().substring(0, 10) : '';
    final type = e['type'] ?? '';
    final reference = e['reference'];
    final description = e['description'];
    final translatedType = translateType(type);
    final color = typeColor(type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(translatedType,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (description != null && description.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('الوصف: $description',
                    style: const TextStyle(color: Colors.black54)),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مدين: ${amountFormatter.format(debit)}',
                    style: const TextStyle(color: Colors.red)),
                Text('دائن: ${amountFormatter.format(credit)}',
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الرصيد: ${amountFormatter.format(balanceValue)}'),
                Text('المرجع: ${reference ?? '—'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> generateClientLedgerPdf() async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final pdf = pw.Document();
    final today = DateTime.now().toString().substring(0, 10);

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text('كشف حساب العميل',
                      style: pw.TextStyle(
                          font: font,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 8),
                pw.Text('اسم العميل: ${widget.clientName}', style: pw.TextStyle(font: font)),
                pw.Text('التاريخ: $today', style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
                        children: ['التاريخ', 'النوع', 'الوصف', 'مدين', 'دائن', 'الرصيد', 'المرجع']
                            .map((e) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(e,
                                    style: pw.TextStyle(
                                        font: font, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.center)))
                            .toList()),
                    ...ledgerEntries.map((e) {
                      final debit = e['debit']?.toString() ?? '0';
                      final credit = e['credit']?.toString() ?? '0';
                      final balanceValue = e['balance']?.toString() ?? '0';
                      return pw.TableRow(
                        children: [
                          e['created_at']?.toString().substring(0, 10) ?? '',
                          translateType(e['type'] ?? ''),
                          e['description'] ?? '',
                          debit,
                          credit,
                          balanceValue,
                          e['reference'] ?? '—',
                        ]
                            .map((v) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(v,
                                      style: pw.TextStyle(font: font),
                                      textAlign: pw.TextAlign.center),
                                ))
                            .toList(),
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Text('إجمالي المبيعات: $totalSales', style: pw.TextStyle(font: font)),
                pw.Text('إجمالي المدفوعات: $totalPayments', style: pw.TextStyle(font: font)),
                pw.Text('الرصيد الحالي: $balance',
                    style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        }));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/client_ledger_${widget.clientId}.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewPage(file: file),
        ),
      );
    }
  }

 void showAdjustmentDialog() {
  final amountController = TextEditingController(text: balance.toString());
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  String selectedPaymentMethod = 'cash';
  DateTime paymentDate = DateTime.now();

  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('تسوية الدين'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('نقدًا')),
                      DropdownMenuItem(value: 'bank', child: Text('تحويل بنكي')),
                      DropdownMenuItem(value: 'visa', child: Text('فيزا')),
                    ],
                    onChanged: (val) => setStateDialog(() => selectedPaymentMethod = val!),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: paymentDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setStateDialog(() => paymentDate = picked);
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                            text: intl.DateFormat('yyyy-MM-dd').format(paymentDate)),
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الدفع',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'المرجع (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال المبلغ')),
                    );
                    return;
                  }

                  final token = await AuthService.getToken();

                  final dataToSend = {
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'method': selectedPaymentMethod,
                    'payment_date': intl.DateFormat('yyyy-MM-dd').format(paymentDate),
                    'reference': referenceController.text.isEmpty
                        ? null
                        : referenceController.text,
                    'notes': notesController.text.isEmpty ? null : notesController.text,
                  };

                  debugPrint('💡 بيانات التسوية المرسلة: $dataToSend');

                  try {
                    final response = await dio.post(
                      '${ApiConfig.baseUrl}/sales-api/public/api/clients/${widget.clientId}/adjustments',
                      options: Options(
                        headers: {
                          'Authorization': 'Bearer $token',
                          'Accept': 'application/json'
                        },
                      ),
                      data: dataToSend,
                    );

                    debugPrint('✅ استجابة السيرفر: ${response.data}');

                    if (response.statusCode == 200 || response.statusCode == 201) {
                      Navigator.pop(context);
                      fetchLedger();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت تسوية الدين بنجاح')),
                      );
                    } else {
                      debugPrint('⚠️ خطأ في التسوية: ${response.data}');
                      final msg = response.data['message'] ?? 'حدث خطأ أثناء التسوية';
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    }
                  } catch (e, stack) {
                    debugPrint('❌ خطأ أثناء التسوية: $e');
                    debugPrintStack(stackTrace: stack);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('حدث خطأ أثناء التسوية')),
                    );
                  }
                },
                child: const Text('تأكيد التسوية'),
              ),
            ],
          );
        },
      );
    },
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
          title: Column(
            children: [
              const Text('كشف حساب العميل', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 2),
              Text(widget.clientName,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        body:SafeArea(child:  isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (showDetails)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: showAdjustmentDialog,
                              icon: const Icon(Icons.payments, color: Colors.white),
                              label: const Text('تسوية الدين',
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: generateClientLedgerPdf,
                              icon:  Icon(Icons.picture_as_pdf, color: primaryColor ),
                              label:  Text('تحميل PDF',
                                  style: TextStyle(color: primaryColor)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: showDetails
                        ? ListView.builder(
                            itemCount: ledgerEntries.length,
                            itemBuilder: (_, i) => ledgerRow(ledgerEntries[i]),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              summaryCard('إجمالي المبيعات', totalSales, Colors.red, Icons.sell),
                              const SizedBox(height: 16),
                              summaryCard('إجمالي الدفعات', totalPayments, Colors.green,
                                  Icons.payments),
                              const SizedBox(height: 16),
                              summaryCard('الرصيد الحالي', balance, Colors.orange,
                                  Icons.account_balance_wallet),
                            ],
                          ),
                  ),
                  if (!showDetails)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () => setState(() => showDetails = true),
                          child: const Text('عرض التفاصيل',
                              style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      )
    );
  }
}
