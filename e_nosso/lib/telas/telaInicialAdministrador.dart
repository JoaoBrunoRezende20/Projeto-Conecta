import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaTipoUsuario.dart';

class TelaInicialAdministrador extends StatelessWidget {
  const TelaInicialAdministrador({super.key});

  // Função de Logout
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Após o logout, remove todas as telas e volta para a de escolha
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const TelaTipoUsuario()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel Administrativo"),
        backgroundColor: Colors.redAccent, // Cor diferente para o admin
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Bem-vindo, Administrador!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
