import 'package:flutter/material.dart';

// Importe as telas das categorias que você já criou
// Se ainda não criou alguma, comente o import correspondente
import 'categorias/categoriaBebidas.dart';
import 'categorias/categoriaQuitandas.dart';
import 'categorias/categoriaFeiraLivre.dart';
import 'categorias/categoriaServicos.dart';
import 'categorias/categoriaOutros.dart';

class TelaDivisaoCategoria extends StatelessWidget {
  const TelaDivisaoCategoria({super.key});

  // Função para construir cada card
  Widget _buildCategoriaCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Widget destino, // Recebe a tela para onde vai
  }) {
    return InkWell(
      onTap: () {
        // Navega para a tela de destino
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destino),
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Categorias",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
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
            // Card Quitandas
            _buildCategoriaCard(
              context: context,
              icon: Icons.local_grocery_store, // Ícone de carrinho/mercado
              label: "Quitandas",
              destino: const CategoriaQuitandas(), // Manda para a tela de Quitandas
            ),

            // Card Bebidas
            _buildCategoriaCard(
              context: context,
              icon: Icons.local_drink, // Ícone de bebida
              label: "Bebidas",
              destino: const CategoriaBebidas(), // Manda para a tela de Bebidas
            ),

            // Card Serviços
            _buildCategoriaCard(
              context: context,
              icon: Icons.build, // Ícone de ferramenta
              label: "Serviços",
              destino: const CategoriaServicos(), // Manda para a tela de Serviços
            ),

            // Card Feira Livre
            _buildCategoriaCard(
              context: context,
              icon: Icons.shopping_basket, // Ícone de cesta
              label: "Feira Livre",
              destino: const CategoriaFeiraLivre(), // Manda para a tela de Feira Livre
            ),

            // Card Outros
            _buildCategoriaCard(
              context: context,
              icon: Icons.more_horiz, // Ícone de três pontinhos
              label: "Outros",
              destino: const CategoriaOutros(), // Manda para a tela de Outros
            ),
          ],
        ),
      ),
    );
  }
}