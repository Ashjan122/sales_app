import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/products_screen.dart';

class InventoryDashboardScreen extends StatelessWidget {
  const InventoryDashboardScreen({super.key});

  static const Color primaryColor = Color(0xFF213D5C);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          centerTitle: true,
          title: const Text(
            'إدارة المخزون',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _dashboardItem(
              title: 'المنتجات',
              icon: Icons.inventory, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductsListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
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
        backgroundColor: InventoryDashboardScreen.primaryColor,
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
