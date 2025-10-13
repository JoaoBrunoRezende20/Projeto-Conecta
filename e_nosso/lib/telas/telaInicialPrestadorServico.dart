import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. IMPORTAMOS O FIREBASE AUTH

class TelaInicialPrestador extends StatelessWidget {
  const TelaInicialPrestador({super.key});

  // 2. A MESMA FUNÇÃO DE LOGOUT QUE USAMOS ANTES
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // O AuthWrapper no main.dart vai cuidar do resto!
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Prestador"),
        // 3. ADICIONAMOS A LISTA DE AÇÕES NA BARRA SUPERIOR
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () {
              // 4. O BOTÃO CHAMA A FUNÇÃO DE LOGOUT
              _signOut(context);
            },
          ),
        ],
      ),
      body: const Center(child: Text("Bem-vindo, Prestador!")),
    );
  }
}
