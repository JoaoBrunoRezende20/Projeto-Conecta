import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/tela_tipo_usuario.dart';

// <<< IMPORTANTE: Importe as telas de categoria que você já criou >>>
// Verifique se os nomes dos arquivos e pastas estão exatos
import '../categorias/categoria_quitandas.dart';
import '../categorias/categoria_bebidas.dart';
import '../categorias/categoria_feira_livre.dart';
import '../categorias/categoria_servicos.dart';
import '../categorias/categoria_outros.dart';

class TelaInicialComum extends StatefulWidget {
  const TelaInicialComum({super.key});

  @override
  State<TelaInicialComum> createState() => _TelaInicialComumState();
}

class _TelaInicialComumState extends State<TelaInicialComum> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _exitVisitorMode() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const TelaTipoUsuario()),
      (route) => false,
    );
  }

  // Função auxiliar para navegar
  void _navegarPara(Widget pagina) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => pagina));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isVisitor = user?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Categorias',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // TODO: Menu lateral
          },
        ),
        actions: [
          if (isVisitor)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.black),
              tooltip: 'Sair',
              onPressed: _exitVisitorMode,
            )
          else
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              tooltip: 'Logout',
              onPressed: _signOut,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // --- AQUI ESTÁ A CORREÇÃO: ADICIONAMOS A NAVEGAÇÃO ---
                  _buildCategoryCard(
                    icon: Icons.cake_outlined,
                    label: 'Quitandas',
                    onTap: () => _navegarPara(const CategoriaQuitandas()),
                  ),
                  _buildCategoryCard(
                    icon: Icons.local_drink_outlined,
                    label: 'Bebidas',
                    onTap: () => _navegarPara(const CategoriaBebidas()),
                  ),
                  _buildCategoryCard(
                    icon: Icons.build_outlined,
                    label: 'Serviços',
                    onTap: () => _navegarPara(const CategoriaServicos()),
                  ),
                  _buildCategoryCard(
                    icon: Icons.shopping_basket_outlined,
                    label: 'Feira Livre',
                    onTap: () => _navegarPara(const CategoriaFeiraLivre()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOutrosButton(
                onTap: () => _navegarPara(const CategoriaOutros()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap, // Agora o onTap recebe a função de navegar!
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.black87),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutrosButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 24, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              'Outros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
