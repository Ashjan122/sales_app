import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/expenses_scteen.dart';
import 'package:jawda_sales/screens/roles_screen.dart';
import 'package:jawda_sales/screens/users_screen.dart';

class ManagementDashboardScreen extends StatelessWidget {
  const ManagementDashboardScreen({super.key});

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
            'الإدارة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _dashboardItem(
                title: 'المستخدمين',
                icon: Icons.people_alt,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsersPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _dashboardItem(
                title: 'الأدوار',
                icon: Icons.gpp_good,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RolesPage()),
                  );
                },
              ),
              _dashboardItem(title: 'المصروفات', icon: Icons.attach_money_outlined, onTap: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpensesScreen()));
              })
            ],
          ),
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
        backgroundColor: ManagementDashboardScreen.primaryColor,
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