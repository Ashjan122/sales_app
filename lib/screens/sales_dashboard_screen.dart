import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/customers_screen.dart';
import 'package:jawda_sales/screens/sales_screen.dart';

class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  static const Color primaryColor = Color(0xFF213D5C);

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child:  Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text(
          'إدارة المبيعات',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dashboardItem(
            title: 'نقطة بيع',
            icon: Icons.point_of_sale,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _dashboardItem(
            title: 'العملاء',
            icon: Icons.people,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomersScreen(),
                ),
              );
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _dashboardItem({
  required String title,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 6, 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), 
      leading: CircleAvatar(
        radius: 25, 
        backgroundColor: SalesDashboardScreen.primaryColor,
        child: Icon(icon, color: Colors.white, size: 25), 
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18, 
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 22),
      onTap: onTap,
    ),
  );
}
}