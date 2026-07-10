import 'package:flutter/material.dart';

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
      ),
      body: const Center(
        child: Text(
          "Home is coming!!!!!",
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
}
git branch -M main
azure@Azures-MacBook-Air sokko_link % git push -u origin main