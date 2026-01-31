import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/Suppliers_screen.dart';
import 'package:jawda_sales/screens/customers_screen.dart';
import 'package:jawda_sales/screens/home_screen.dart';
import 'package:jawda_sales/screens/inventory_dashboard_screen.dart';
import 'package:jawda_sales/screens/products_screen.dart';
import 'package:jawda_sales/screens/purchases_dashboard_screen.dart';
import 'package:jawda_sales/screens/purchases_screen.dart';
import 'package:jawda_sales/screens/reports_dashboard_screen.dart';
import 'package:jawda_sales/screens/sales_dashboard_screen.dart';
import 'package:jawda_sales/screens/sales_screen.dart';
import 'package:jawda_sales/screens/managment_dashboard_screen.dart';
import 'package:lottie/lottie.dart';

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
        appBar: AppBar(
          title: Text(
            'لوحة التحكم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF213D5C),
          centerTitle: true,
        ),
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
