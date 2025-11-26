import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaTipoUsuario.dart';

class TelaInicialComum extends StatefulWidget {
  const TelaInicialComum({super.key});

  @override
  State<TelaInicialComum> createState() => _TelaInicialComumState();
}

class _TelaInicialComumState extends State<TelaInicialComum> {
  // Ação para usuários logados
  Future<void> _signOut() async {
    // Apenas desloga o usuário. O AuthWrapper cuidará da navegação.
    await FirebaseAuth.instance.signOut();
  }

  // <<< NOVA FUNÇÃO: Ação para visitantes >>>
  // Apenas navega de volta para a tela de escolha, limpando o histórico.
  void _exitVisitorMode() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const TelaTipoUsuario()),
          (route) => false,
    );
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
          'categorias',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // TODO: Implementar lógica para abrir o menu lateral (Drawer)
          },
        ),
        // <<< CORREÇÃO PRINCIPAL AQUI >>>
        // Agora, sempre haverá um botão, mas ele muda dependendo do usuário.
        actions: [
          if (isVisitor)
          // Botão para o VISITANTE
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.black),
              tooltip: 'Sair',
              onPressed: _exitVisitorMode,
            )
          else
          // Botão para o USUÁRIO LOGADO
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
                  _buildCategoryCard(
                    icon: Icons.cake_outlined,
                    label: 'Quitandas',
                    onTap: () {
                      // TODO: Navegar para a tela da categoria Quitandas
                    },
                  ),
                  _buildCategoryCard(
                    icon: Icons.local_drink_outlined,
                    label: 'Bebidas',
                    onTap: () {
                      // TODO: Navegar para a tela da categoria Bebidas
                    },
                  ),
                  _buildCategoryCard(
                    icon: Icons.build_outlined,
                    label: 'Serviços',
                    onTap: () {
                      // TODO: Navegar para a tela da categoria Serviços
                    },
                  ),
                  _buildCategoryCard(
                    icon: Icons.shopping_basket_outlined,
                    label: 'Feira Livre',
                    onTap: () {
                      // TODO: Navegar para a tela da categoria Feira Livre
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOutrosButton(
                onTap: () {
                  // TODO: Navegar para a tela de "Outras" categorias
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Os widgets de construção (_build...) continuam iguais e podem ficar aqui
  Widget _buildCategoryCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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

