import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaTipoUsuario.dart'; // Importa a tela de escolha para o logout

// <<< CORREÇÃO AQUI: O nome da classe DEVE ser este
class TelaInicialLojista extends StatelessWidget {
  const TelaInicialLojista({super.key});

  // Função de Logout
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Após o logout, volta para a primeira tela
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const TelaTipoUsuario()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Lojista"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Chama a função de logout quando o botão é pressionado
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: const Center(child: Text("Bem-vindo, Lojista!")),
    );
  }
}
