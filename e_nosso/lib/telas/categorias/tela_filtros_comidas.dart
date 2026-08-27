import 'package:flutter/material.dart';
import 'categoria_comidas.dart';

class TelaFiltrosComidas extends StatelessWidget {
  const TelaFiltrosComidas({super.key});

  void _navegarParaListagem(BuildContext context, String? categoria, String titulo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriaComidas(
          categoriaSelecionada: categoria,
          tituloCategoria: titulo,
        ),
      ),
    );
  }

  Widget _buildFiltroCard(BuildContext context, String titulo, IconData icone, String? categoria) {
    return InkWell(
      onTap: () => _navegarParaListagem(context, categoria, titulo),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 48, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              titulo,
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
      backgroundColor: const Color(0xFFF5F5F5),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildFiltroCard(context, "Comidas", Icons.cake_outlined, "Comidas"),
                      _buildFiltroCard(context, "Bebidas", Icons.local_drink_outlined, "Bebidas"),
                      _buildFiltroCard(context, "Feira Livre", Icons.shopping_basket_outlined, "Feira Livre"),
                      _buildFiltroCard(context, "Outros", Icons.add, "Outros"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
