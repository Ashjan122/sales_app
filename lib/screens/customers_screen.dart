import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:jawda_sales/core/network/dio_client.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jawda_sales/screens/client_ledger_screen.dart';


class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllCustomers();
  }

  Future<void> fetchAllCustomers() async {
    try {
      String? url = '/clients?per_page=15';
      List allCustomers = [];

      while (url != null) {
        final response = await DioClient.dio.get(url);
        allCustomers.addAll(response.data['data']);
        url = response.data['next_page_url'] != null
            ? response.data['next_page_url']!.replaceFirst(
                'http://alroomy.a.pinggy.link/sales-api/public/api', '')
            : null;
      }

      setState(() {
        customers = allCustomers;
        isLoading = false;
      });
    } catch (e) {
      print("🔥 ERROR: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل في جلب بيانات العملاء")),
      );
    }
  }

 Future<void> addCustomer() async {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isSaving = false;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عميل جديد'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);

                      try {
                        final response = await DioClient.dio.post(
                          '/clients', // تأكد أن Base URL مضبوط في DioClient
                          data: {
                            "name": nameController.text,
                            "email": emailController.text,
                            "phone": phoneController.text,
                            "address": addressController.text,
                          },
                        );

                        // إضافة العميل الجديد للقائمة محليًا
                        setState(() {
                          customers.add(response.data['client']);
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم إضافة العميل بنجاح")),
                        );
                      } catch (e) {
                        print("🔥 ERROR ADD: $e");
                        if (e is DioError) {
                          print("Dio error data: ${e.response?.data}");
                        }
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("فشل في إضافة العميل")),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    ),
  );
}


  Future<void> updateCustomer(Map customer) async {
    final TextEditingController nameController =
        TextEditingController(text: customer['name']);
    final TextEditingController emailController =
        TextEditingController(text: customer['email']);
    final TextEditingController phoneController =
        TextEditingController(text: customer['phone']);
    final TextEditingController addressController =
        TextEditingController(text: customer['address']);

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل العميل'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'الهاتف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.red),),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);

                        try {
                          final response = await DioClient.dio.put(
                            '/clients/${customer['id']}',
                            data: {
                              "name": nameController.text,
                              "email": emailController.text,
                              "phone": phoneController.text,
                              "address": addressController.text,
                            },
                          );

                          setState(() {
                            int index = customers.indexWhere(
                                (element) => element['id'] == customer['id']);
                            if (index != -1) {
                              customers[index] = response.data['client'];
                            }
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("تم تحديث العميل بنجاح")),
                          );
                        } catch (e) {
                          print("🔥 ERROR UPDATE: $e");
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("فشل في تعديل العميل")),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('حفظ', style: TextStyle(color: Color(0xFF213D5C)),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteCustomer(Map customer) async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف العميل ${customer['name']}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.red),),
            ),
            ElevatedButton(
              onPressed: () {
                confirm = true;
                Navigator.pop(context);
              },
              child: const Text('حذف', style: TextStyle(color: Color(0xFF213D5C)),),
            ),
          ],
        ),
      ),
    );

    if (confirm) {
      try {
        await DioClient.dio.delete('/clients/${customer['id']}');

        setState(() {
          customers.removeWhere((c) => c['id'] == customer['id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حذف العميل بنجاح")),
        );
      } catch (e) {
        print("🔥 ERROR DELETE: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل في حذف العميل")),
        );
      }
    }
  }
  String formatNumber(dynamic value) {
  if (value == null) return '0';
  final number = num.tryParse(value.toString()) ?? 0;
  return intl.NumberFormat('#,##0', 'en').format(number);
}

  void showCustomerDetailsDialog(Map customer) {
  showDialog(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'تفاصيل العميل',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('الاسم', customer['name']),
            _infoRow('رقم الهاتف', customer['phone'] ?? '—'),
            const Divider(),

            _infoRow(
  'إجمالي المديونية',
  formatNumber(customer['total_debit']),
),
_infoRow(
  'إجمالي المدفوعات',
  formatNumber(customer['total_credit']),
),
_infoRow(
  'الرصيد',
  formatNumber(customer['balance']),
  isBalance: true,
),

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
Widget _infoRow(String label, String value, {bool isBalance = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBalance ? FontWeight.bold : FontWeight.normal,
            color: isBalance ? Colors.blueGrey : Colors.black,
          ),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("العملاء", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF213D5C),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white,),
            onPressed: addCustomer, // فتح Dialog الإضافة
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
              ? const Center(child: Text("لا توجد بيانات"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListTile(
  onTap: () {
    showCustomerDetailsDialog(customer);
  },
  title: Text(
    customer['name'] ?? 'بدون اسم',
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
  subtitle: Text(customer['phone'] ?? 'بدون رقم'),
 trailing: PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert),
  onSelected: (value) {
    if (value == 'ledger') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ClientLedgerPage(
        clientId: customer['id'],
        clientName: customer['name'],
      ),
    ),
  );
}
 else if (value == 'edit') {
      updateCustomer(customer);
    } else if (value == 'delete') {
      deleteCustomer(customer);
    }
  },
  itemBuilder: (context) => const [
    PopupMenuItem(
      value: 'ledger',
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.green),
          SizedBox(width: 8),
          Text('كشف الحساب'),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'edit',
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 8),
          Text('تعديل'),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete, color: Colors.red),
          SizedBox(width: 8),
          Text('حذف'),
        ],
      ),
    ),
  ],
),

),

                      ),
                    );
                  },
                ),
    );
  }
}
