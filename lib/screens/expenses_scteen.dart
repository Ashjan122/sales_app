import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/api_config.dart';
import 'package:jawda_sales/core/services/auth_service.dart';
import 'package:intl/intl.dart' as intl;

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final Dio dio = Dio();
  List expenses = [];
  List categories = [];
  bool loading = true;

  final Color primaryColor = const Color(0xFF213D5C);
  final intl.NumberFormat numberFormat = intl.NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => loading = true);

    final token = await AuthService.getToken();
    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final res = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/expenses',
        queryParameters: {
          'page': 1,
          'per_page': 10,
          'sort_by': 'expense_date',
          'sort_direction': 'desc',
        },
      );

      setState(() {
        expenses = res.data['data'];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ في تحميل المصروفات: $e')));
    }
  }

  Future<List> _fetchCategories() async {
    final token = await AuthService.getToken();
    dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    try {
      final res = await dio.get(
        '${ApiConfig.baseUrl}/sales-api/public/api/admin/expense-categories',
        queryParameters: {'all_flat': true},
      );
      return res.data['data'] ?? [];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفئات: $e')));
      return [];
    }
  }

  Future<void> _showAddExpenseDialog() async {
    // أولًا نعرض لودينج أثناء تحميل الفئات
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(child: CircularProgressIndicator());
        });

    categories = await _fetchCategories();
    Navigator.of(context).pop(); // إغلاق اللودينج

    final _formKey = GlobalKey<FormState>();
    String title = '';
    String amount = '';
    DateTime expenseDate = DateTime.now();
    int? selectedCategoryId;
    String paymentMethod = 'cash';
    String reference = '';
    String description = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('إضافة مصروف جديد', textAlign: TextAlign.right),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // اسم المصروف
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'اسم المصروف',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.right,
                      onSaved: (val) => title = val ?? '',
                      validator: (val) =>
                          val == null || val.isEmpty ? 'الرجاء إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 10),
                    // المبلغ
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      onSaved: (val) => amount = val ?? '',
                      validator: (val) =>
                          val == null || val.isEmpty ? 'الرجاء إدخال المبلغ' : null,
                    ),
                    const SizedBox(height: 10),
                    // التاريخ
                    TextFormField(
                      readOnly: true,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: expenseDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                expenseDate = picked;
                              });
                            }
                          },
                        ),
                      ),
                      controller: TextEditingController(
                          text:
                              '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}'),
                    ),
                    const SizedBox(height: 10),
                    // الفئة
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'الفئة / القسم',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      value: selectedCategoryId,
                      items: categories
                          .map((cat) => DropdownMenuItem<int>(
                                value: cat['id'],
                                child: Text(cat['name'], textAlign: TextAlign.right),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedCategoryId = val;
                        });
                      },
                      validator: (val) =>
                          val == null ? 'الرجاء اختيار الفئة' : null,
                    ),
                    const SizedBox(height: 10),
                    // طريقة الدفع
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'طريقة الدفع',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      value: paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('كاش')),
                        DropdownMenuItem(value: 'bank', child: Text('بنك')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          paymentMethod = val ?? 'cash';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // المرجع
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'المرجع',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.right,
                      onSaved: (val) => reference = val ?? '',
                    ),
                    const SizedBox(height: 10),
                    // الوصف
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الوصف',
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.right,
                      onSaved: (val) => description = val ?? '',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء')),
              ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final token = await AuthService.getToken();
                      dio.options.headers = {
                        'Authorization': 'Bearer $token',
                        'Accept': 'application/json',
                      };

                      try {
                        await dio.post(
                          '${ApiConfig.baseUrl}/sales-api/public/api/admin/expenses',
                          data: {
                            "title": title,
                            "amount": amount,
                            "expense_date":
                                '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
                            "expense_category_id": selectedCategoryId,
                            "payment_method": paymentMethod,
                            "reference": reference,
                            "description": description,
                          },
                        );
                        Navigator.of(context).pop();
                        _loadExpenses();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ في إضافة المصروف: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('إنشاء')),
            ],
          );
        });
      },
    );
  }
  Future<void> _showEditExpenseDialog(Map exp) async {
  // أولًا نعرض لودينج أثناء تحميل الفئات
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(child: CircularProgressIndicator());
      });

  categories = await _fetchCategories();
  Navigator.of(context).pop(); // إغلاق اللودينج

  final _formKey = GlobalKey<FormState>();
  String title = exp['title'] ?? '';
  String amount = exp['amount'] ?? '';
  DateTime expenseDate = DateTime.tryParse(exp['expense_date'] ?? '') ?? DateTime.now();
  int? selectedCategoryId = exp['expense_category_id'];
  String paymentMethod = exp['payment_method'] ?? 'cash';
  String reference = exp['reference'] ?? '';
  String description = exp['description'] ?? '';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text('تعديل المصروف', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // نفس الحقول كما في الإضافة
                  TextFormField(
                    initialValue: title,
                    decoration: InputDecoration(
                      labelText: 'اسم المصروف',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                    onSaved: (val) => title = val ?? '',
                    validator: (val) => val == null || val.isEmpty ? 'الرجاء إدخال الاسم' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: amount,
                    decoration: InputDecoration(
                      labelText: 'المبلغ',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    onSaved: (val) => amount = val ?? '',
                    validator: (val) => val == null || val.isEmpty ? 'الرجاء إدخال المبلغ' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: expenseDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              expenseDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    controller: TextEditingController(
                        text:
                            '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'الفئة / القسم',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: selectedCategoryId,
                    items: categories
                        .map((cat) => DropdownMenuItem<int>(
                              value: cat['id'],
                              child: Text(cat['name'], textAlign: TextAlign.right),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedCategoryId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'طريقة الدفع',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    value: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('كاش')),
                      DropdownMenuItem(value: 'bank', child: Text('بنك')),
                    ],
                    onChanged: (val) {
                      setStateDialog(() {
                        paymentMethod = val ?? 'cash';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: reference,
                    decoration: InputDecoration(
                      labelText: 'المرجع',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                    onSaved: (val) => reference = val ?? '',
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: description,
                    decoration: InputDecoration(
                      labelText: 'الوصف',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.right,
                    onSaved: (val) => description = val ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء')),
            ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final token = await AuthService.getToken();
                    dio.options.headers = {
                      'Authorization': 'Bearer $token',
                      'Accept': 'application/json',
                    };

                    try {
                      await dio.put(
                        '${ApiConfig.baseUrl}/sales-api/public/api/admin/expenses/${exp['id']}',
                        data: {
                          "title": title,
                          "amount": amount,
                          "expense_date":
                              '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
                          "expense_category_id": selectedCategoryId,
                          "payment_method": paymentMethod,
                          "reference": reference,
                          "description": description,
                        },
                      );
                      Navigator.of(context).pop();
                      _loadExpenses();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('خطأ في تحديث المصروف: $e')),
                      );
                    }
                  }
                },
                child: const Text('تحديث')),
          ],
        );
      });
    },
  );
}

Future<void> _deleteExpense(int id) async {
  final token = await AuthService.getToken();
  dio.options.headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  try {
    await dio.delete(
      '${ApiConfig.baseUrl}/sales-api/public/api/admin/expenses/$id',
    );
    _loadExpenses();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المصروف')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ في حذف المصروف: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المصروفات',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add,color: Colors.white,),
            onPressed: _showAddExpenseDialog,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(child: Text('لا توجد مصروفات'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: expenses.length,
                  // داخل ListView.builder
itemBuilder: (context, index) {
  final exp = expenses[index];

  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(12),
      title: Text(
        exp['title'] ?? 'بدون عنوان',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.right,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Text('التاريخ: ${exp['expense_date'] ?? ''}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black)),
          Text('القسم: ${exp['expense_category_name'] ?? 'غير محدد'}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black)),
          Text(
            'المبلغ: ${numberFormat.format(double.tryParse(exp['amount'] ?? '0') ?? 0)}',
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: Colors.black, ),
          ),
          Text('طريقة الدفع: ${exp['payment_method'] ?? '-'}',
              textAlign: TextAlign.right, style: const TextStyle(color: Colors.black)),
          Text('المرجع: ${exp['reference'] ?? 'غير محدد'}',
              textAlign: TextAlign.right, style: const TextStyle(color: Colors.black)),
        ],
      ),
      leading: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _showEditExpenseDialog(exp);
          } else if (value == 'delete') {
            _deleteExpense(exp['id']);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('تعديل'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('حذف'),
          ),
        ],
        icon: const Icon(Icons.more_vert, color: Colors.black),
      ),
    ),
  );
},
              ),
    );
  }
}
