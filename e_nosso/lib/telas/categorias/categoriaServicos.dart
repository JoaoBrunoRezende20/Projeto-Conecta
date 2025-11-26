import 'package:flutter/material.dart';

class CategoriaServicos extends StatelessWidget {
  const CategoriaServicos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Serviços"),
        backgroundColor: Colors.grey[200],
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Tela de Serviços",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
