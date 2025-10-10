import 'package:flutter/material.dart';

//
class telaInicialComum extends StatelessWidget {
  const telaInicialComum({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tela Inicial")),
      body: Center(
        child: Text("Usuário logado com sucesso!"),
      ),
    );
  }
}