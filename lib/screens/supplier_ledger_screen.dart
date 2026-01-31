import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:jawda_sales/screens/Suppliers_screen.dart';
import 'package:jawda_sales/screens/pdf_view_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bidi/bidi.dart' as bidi;

class SupplierLedgerPage extends StatefulWidget {
  final Supplier supplier;

  const SupplierLedgerPage({super.key, required this.supplier});

  @override
  State<SupplierLedgerPage> createState() => _SupplierLedgerPageState();
}

class _SupplierLedgerPageState extends State<SupplierLedgerPage> {
  final Dio dio = Dio();
  final intl.NumberFormat amountFormatter = intl.NumberFormat('#,###');

  bool isLoading = true;
  bool showDetails = false;

  int totalPurchases = 0;
  int totalPayments = 0;
  int balance = 0;

  List<dynamic> ledgerEntries = [];

  // Payment Dialog variables
  List<dynamic> paymentTypes = [];
  List<dynamic> paymentMethods = [];

  String? selectedPaymentType;
  String? selectedPaymentMethod;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchLedger();
    fetchPaymentTypes();
    fetchPaymentMethods();
  }

  Future<void> fetchLedger() async {
    setState(() => isLoading = true);
    try {
      final token = await AuthService.getToken();

      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/suppliers/${widget.supplier.id}/ledger',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;

      setState(() {
        totalPurchases = (data['summary']['total_purchases'] ?? 0).toInt();
        totalPayments = (data['summary']['total_payments'] ?? 0).toInt();
        balance = (data['summary']['balance'] ?? 0).toInt();
        ledgerEntries = data['ledger_entries'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Ledger error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchPaymentTypes() async {
    try {
      final token = await AuthService.getToken();
      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/payment-types',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      setState(() {
        paymentTypes = response.data['types'] ?? [];
      });
    } catch (e) {
      debugPrint('Payment types error: $e');
      paymentTypes = [];
    }
  }

  Future<void> fetchPaymentMethods() async {
    try {
      final token = await AuthService.getToken();
      final response = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/payment-methods',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      setState(() {
        paymentMethods = response.data['methods'] ?? [];
      });
    } catch (e) {
      debugPrint('Payment methods error: $e');
      paymentMethods = [];
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
      case 'purchase':
        return 'شراء';
      case 'payment':
        return 'دفعة';
      case 'credit':
        return 'دائن';
      case 'adjustment':
        return 'تسوية';
      default:
        return type;
    }
  }

  Color typeColor(String type) {
    switch (type) {
      case 'purchase':
        return Colors.red;
      case 'payment':
        return Colors.green;
      case 'credit':
        return Colors.orange;
      case 'adjustment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> generateSupplierLedgerPdf({
    required BuildContext context,
    required Supplier supplier,
    required List<dynamic> ledgerEntries,
    required int totalPurchases,
    required int totalPayments,
    required int balance,
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    final pdf = pw.Document();

    final today = DateTime.now().toString().substring(0, 10);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // العنوان
                pw.Center(
                  child: pw.Text(
                    'كشف حساب المورد',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),

                // معلومات المورد
                pw.Text(
                  'اسم المورد: ${supplier.name}',
                  style: pw.TextStyle(font: font),
                ),
                pw.Text('التاريخ: $today', style: pw.TextStyle(font: font)),
                pw.SizedBox(height: 20),

                // الجدول
                pw.Table(
                  border: pw.TableBorder.all(),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    // رأس الجدول
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFEFEFEF),
                      ),
                      children:
                          [
                                'التاريخ',
                                'النوع',
                                'الوصف',
                                'مدين',
                                'دائن',
                                'الرصيد',
                                'المرجع',
                              ]
                              .map(
                                (e) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    e,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    // البيانات
                    ...ledgerEntries.map((e) {
                      final debit = e['debit']?.toString() ?? '0';
                      final credit = e['credit']?.toString() ?? '0';
                      final balanceValue = e['balance']?.toString() ?? '0';
                      return pw.TableRow(
                        children:
                            [
                                  e['date']?.toString().substring(0, 10) ?? '',
                                  _translateType(e['type']),
                                  e['description'] ?? '',
                                  debit,
                                  credit,
                                  balanceValue,
                                  e['reference'] ?? '—',
                                ]
                                .map(
                                  (v) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(4),
                                    child: pw.Text(
                                      v,
                                      style: pw.TextStyle(font: font),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 20),
                pw.Divider(),

                // الملخص
                pw.Text(
                  'إجمالي المشتريات: $totalPurchases',
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  'إجمالي المدفوعات: $totalPayments',
                  style: pw.TextStyle(font: font),
                ),
                pw.Text(
                  'الرصيد الحالي: $balance',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/supplier_ledger_${supplier.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewPage(file: file)),
      );
    }
  }

  String _translateType(String? type) {
    switch (type) {
      case 'purchase':
        return 'شراء';
      case 'payment':
        return 'دفعة';
      case 'credit':
        return 'دائن';
      case 'adjustment':
        return 'تسوية';
      default:
        return type ?? '';
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// النص (يمين)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  amountFormatter.format(value),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            /// الأيقونة (شمال)
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

    final date = e['date'] != null ? e['date'].toString().substring(0, 10) : '';

    final type = e['type'] ?? '';
    final reference = e['reference'];
    final description = e['description'];

    final translatedType = translateType(type);
    final color = typeColor(type);

    return SafeArea(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// التاريخ + النوع
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      translatedType,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (description != null && description.toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'الوصف: $description',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مدين: ${amountFormatter.format(debit)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  Text(
                    'دائن: ${amountFormatter.format(credit)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الرصيد: ${amountFormatter.format(balanceValue)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'المرجع: ${reference ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showAddPaymentDialog() {
    if (paymentTypes.isEmpty || paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جارٍ تحميل طرق الدفع وأنواع الدفع…')),
      );
      return;
    }

    selectedPaymentType = paymentTypes[0]['value']?.toString();
    selectedPaymentMethod = paymentMethods[0]['value']?.toString();
    amountController.clear();
    referenceController.clear();
    notesController.clear();
    paymentDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إضافة دفعة'),
                content: SingleChildScrollView(
                  child: Column(
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
                        value: selectedPaymentType,
                        decoration: const InputDecoration(
                          labelText: 'نوع الدفع',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            paymentTypes.map<DropdownMenuItem<String>>((
                              dynamic e,
                            ) {
                              final map = e as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: map['value']?.toString(),
                                child: Text(map['label']?.toString() ?? ''),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setStateDialog(() => selectedPaymentType = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'طريقة الدفع',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            paymentMethods.map<DropdownMenuItem<String>>((
                              dynamic e,
                            ) {
                              final map = e as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: map['value']?.toString(),
                                child: Text(map['label']?.toString() ?? ''),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setStateDialog(() => selectedPaymentMethod = val);
                        },
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
                          if (picked != null) {
                            setStateDialog(() => paymentDate = picked);
                          }
                        },
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'تاريخ الدفع',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: intl.DateFormat(
                                'yyyy-MM-dd',
                              ).format(paymentDate),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'رقم المرجع',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (isSubmitting)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(child: CircularProgressIndicator()),
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
                      if (amountController.text.isEmpty ||
                          selectedPaymentType == null ||
                          selectedPaymentMethod == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى تعبئة جميع الحقول الأساسية'),
                          ),
                        );
                        return;
                      }

                      // عرض مؤشر التحميل
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );

                      try {
                        final token = await AuthService.getToken();

                        final payload = {
                          'amount': double.tryParse(amountController.text) ?? 0,
                          'type': selectedPaymentType,
                          'method': selectedPaymentMethod,
                          'payment_date': intl.DateFormat(
                            'yyyy-MM-dd',
                          ).format(paymentDate), // 2026-01-25
                          'reference':
                              referenceController.text.isEmpty
                                  ? null
                                  : referenceController.text,
                          'notes':
                              notesController.text.isEmpty
                                  ? null
                                  : notesController.text,
                        };

                        debugPrint('Sending payment data: $payload');

                        debugPrint('Sending payment data: $payload');

                        final response = await dio.post(
                          '${ApiConfig.baseUrl}/sales-api/public/api/suppliers/${widget.supplier.id}/payments',
                          options: Options(
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                            // حتى لا يرمِ DioException على 422
                            validateStatus: (status) => status! < 500,
                          ),
                          data: payload,
                        );

                        Navigator.pop(context); // إخفاء مؤشر التحميل

                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          Navigator.pop(context); // إغلاق الديالوق
                          fetchLedger(); // تحديث الكشوف
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تمت إضافة الدفعة بنجاح'),
                            ),
                          );
                        } else {
                          // عرض رسالة الخطأ من السيرفر
                          final msg =
                              response.data['message'] ??
                              'حدث خطأ أثناء الإضافة';
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(msg)));
                          debugPrint(
                            'Add payment error: ${response.statusCode} - ${response.data}',
                          );
                        }
                      } catch (e) {
                        Navigator.pop(
                          context,
                        ); // إخفاء مؤشر التحميل في حال حدوث خطأ
                        debugPrint('Add payment exception: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('حدث خطأ أثناء الإضافة'),
                          ),
                        );
                      }
                    },
                    child: const Text('حفظ'),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: primaryColor,
          centerTitle: true,
          title: Column(
            children: [
              const Text('كشف حساب', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                widget.supplier.name,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child:
              isLoading
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
                                  onPressed: showAddPaymentDialog,
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'إضافة دفعة',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    generateSupplierLedgerPdf(
                                      context: context,
                                      supplier: widget.supplier,
                                      ledgerEntries: ledgerEntries,
                                      totalPurchases: totalPurchases,
                                      totalPayments: totalPayments,
                                      balance: balance,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.picture_as_pdf,
                                    color: primaryColor,
                                  ),
                                  label: const Text(
                                    'تحميل PDF',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child:
                            showDetails
                                ? ListView.builder(
                                  itemCount: ledgerEntries.length,
                                  itemBuilder:
                                      (_, i) => ledgerRow(ledgerEntries[i]),
                                )
                                : ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    summaryCard(
                                      'إجمالي المشتريات',
                                      totalPurchases,
                                      Colors.red,
                                      Icons.shopping_cart,
                                    ),
                                    const SizedBox(height: 16),
                                    summaryCard(
                                      'إجمالي المدفوعات',
                                      totalPayments,
                                      Colors.green,
                                      Icons.payments,
                                    ),
                                    const SizedBox(height: 16),
                                    summaryCard(
                                      'الرصيد الحالي',
                                      balance,
                                      Colors.orange,
                                      Icons.account_balance_wallet,
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed:
                                  () => setState(() => showDetails = true),
                              child: const Text(
                                'عرض التفاصيل',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
