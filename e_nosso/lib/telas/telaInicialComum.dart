import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. PRECISAMOS IMPORTAR O FIREBASE AUTH

class TelaInicialComum extends StatelessWidget {
  const TelaInicialComum({super.key});

  // 2. VAMOS CRIAR UMA FUNÇÃO SÓ PARA O LOGOUT (DEIXA O CÓDIGO MAIS LIMPO)
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Após o logout, volta para a primeira tela

    } catch (e) {
      // Opcional: Mostrar uma mensagem de erro se o logout falhar por algum motivo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer logout: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tela Inicial Comum"),
        // 3. 'actions' É UMA LISTA DE BOTÕES QUE FICAM À DIREITA DO TÍTULO
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Ícone de "sair"
            tooltip: 'Sair', // Mensagem que aparece se o usuário segurar o dedo no botão
            onPressed: () {
              // 4. QUANDO O BOTÃO É PRESSIONADO, CHAMAMOS A FUNÇÃO DE LOGOUT
              _signOut(context);
            },
          ),
        ],
      ),
      body: const Center(child: Text("Bem-vindo, Usuário!")),
    );
  }
}
