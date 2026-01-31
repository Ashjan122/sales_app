import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/monthly_sales_report_screen.dart';

import 'package:jawda_sales/screens/sales_reports_screen.dart';
import 'package:jawda_sales/screens/suppliers_summary_screen.dart'; 

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

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
            'التقارير',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _dashboardItem(
              title: 'تقرير المبيعات',
              icon: Icons.bar_chart, 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SalesReportScreen()),
                );
              },
            ),
            _dashboardItem(title: 'تقرير المبيعات الشهري', icon: Icons.calendar_month, onTap: () {
              Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MonthlySalesReportPage(month: DateTime.now().month,
      year: DateTime.now().year,)));},),
      _dashboardItem(title: 'ملخص الموردين', icon: Icons.assignment, onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => SuppliersSummaryPage()));
      })
            
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
        backgroundColor: ReportsDashboardScreen.primaryColor,
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
