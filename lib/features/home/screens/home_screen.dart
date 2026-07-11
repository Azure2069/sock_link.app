import 'package:flutter/material.dart';
import '../widgets/action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Makola Trader",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          children: [
            ActionCard(
              icon: Icons.shopping_cart,
              title: "New Sale",
              onTap: () {},
            ),
            ActionCard(icon: Icons.inventory, title: "Inventory", onTap: () {}),
            ActionCard(icon: Icons.bar_chart, title: "Reports", onTap: () {}),
            ActionCard(title: "Customers", icon: Icons.people, onTap: () {}),
          ],
        ),
      ),
    );
  }
}
