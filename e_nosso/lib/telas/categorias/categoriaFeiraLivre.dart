import 'package:flutter/material.dart';

class CategoriaFeiraLivre extends StatelessWidget {
  const CategoriaFeiraLivre({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feira Livre"),
        backgroundColor: Colors.grey[200],
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Tela de Feira Livre",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
