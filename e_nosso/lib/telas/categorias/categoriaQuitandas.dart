import 'package:flutter/material.dart';

class CategoriaQuitandas extends StatelessWidget {
  const CategoriaQuitandas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quitandas"),
        backgroundColor: Colors.grey[200],
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Tela de Quitandas",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
