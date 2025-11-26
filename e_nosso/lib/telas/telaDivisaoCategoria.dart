import 'package:flutter/material.dart';
import 'categorias/categoriaBebidas.dart';
import 'categorias/categoriaQuitandas.dart';
import 'categorias/categoriaFeiraLivre.dart';
import 'categorias/categoriaServicos.dart';
import 'categorias/categoriaOutros.dart';

class TelaDivisaoCategoria extends StatelessWidget {
  const TelaDivisaoCategoria({super.key});

  Widget _buildCategoriaCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget destino,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destino),
        );
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.black.withOpacity(0.08),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(">>> A TELA REAL FOI CARREGADA <<<");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Categorias",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildCategoriaCard(
              context: context,
              icon: Icons.local_grocery_store,
              label: "Quitandas",
              destino: const CategoriaQuitandas(),
            ),
            _buildCategoriaCard(
              context: context,
              icon: Icons.local_drink,
              label: "Bebidas",
              destino: const CategoriaBebidas(),
            ),
            _buildCategoriaCard(
              context: context,
              icon: Icons.build,
              label: "Serviços",
              destino: const CategoriaServicos(),
            ),
            _buildCategoriaCard(
              context: context,
              icon: Icons.shopping_basket,
              label: "Feira Livre",
              destino: const CategoriaFeiraLivre(),
            ),
            _buildCategoriaCard(
              context: context,
              icon: Icons.more_horiz,
              label: "Outros",
              destino: const CategoriaOutros(),
            ),
          ],
        ),
      ),
    );
  }
}
