import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/products_screen.dart';
import '../sales/sales_screen.dart';
import '../people/people_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  final BusinessData business;
  final VoidCallback onLock;
  const HomeScreen({super.key, required this.business, required this.onLock});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(business: widget.business),
      const ProductsScreen(),
      const SalesScreen(),
      const PeopleScreen(),
      MoreScreen(business: widget.business, onLock: widget.onLock)
    ];
    return Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Products'),
              NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: 'Sales'),
              NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'People'),
              NavigationDestination(
                  icon: Icon(Icons.more_horiz), label: 'More'),
            ]));
  }
}
