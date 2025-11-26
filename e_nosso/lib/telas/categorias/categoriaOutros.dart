import 'package:flutter/material.dart';

class CategoriaOutros extends StatelessWidget {
  const CategoriaOutros({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Outros"),
        backgroundColor: Colors.grey[200],
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Tela de Outros",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
