import 'package:flutter/material.dart';
import 'package:jawda_sales/screens/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final List<Widget> pages = [
      OverviewPage(),
      SalesPage(),
      PurchasesPage(),
      InventoryPage(),
    ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: Text(
          currentIndex == 0
              ? "Overview"
              : currentIndex == 1
                  ? "المبيعات"
                  : currentIndex == 2
                      ? "المشتريات"
                      : "المخزون",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Scaffold.of(context).openEndDrawer();
              },
              child: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.black),
              ),
            ),
          ),
          SizedBox(width: 15),
        ],

      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => currentIndex = 0),
                icon: Icon(
                  Icons.grid_view,
                  color: currentIndex == 0 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 1),
                icon: Icon(
                  Icons.sell,
                  color: currentIndex == 1 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 2),
                icon: Icon(
                  Icons.shopping_cart,
                  color: currentIndex == 2 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => currentIndex = 3),
                icon: Icon(
                  Icons.inventory_2,
                  color: currentIndex == 3 ? Color(0xFF213D5C) : Colors.grey,
                ),
              ),
               IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.home,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),);
    
    

}}
class OverviewPage extends StatefulWidget{
  const OverviewPage({super.key});
  
   @override
  State<OverviewPage> createState() => _OverviewPageState();
}
class _OverviewPageState extends State<OverviewPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        child: Text("Overview"),
      ),
    );
  }
}
class SalesPage extends StatefulWidget{
  const SalesPage({super.key});
  @override
  State<SalesPage> createState() => _SalesPageState();
}
class _SalesPageState extends State<SalesPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        child: Text("المبيعات"),
      ),
    );
  }
}
class PurchasesPage extends StatefulWidget{
  const PurchasesPage({super.key});
  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}
class _PurchasesPageState extends State<PurchasesPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        child: Text("المشتريات"),
      ),
    );
  }
}
class InventoryPage extends StatefulWidget{
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}
class _InventoryPageState extends State<InventoryPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        child: Text("المخزون"),
      ),
    );
    
  }
}