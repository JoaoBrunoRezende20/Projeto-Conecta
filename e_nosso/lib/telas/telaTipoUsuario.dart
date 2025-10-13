import 'package:flutter/material.dart';
import 'telaLogin.dart';
import 'telaInicialComum.dart'; // <<< CORREÇÃO 2: Importamos a tela que faltava

class TelaTipoUsuario extends StatelessWidget {
  const TelaTipoUsuario({super.key});

  void _navegarParaLogin(BuildContext context, String tipo) {
    Navigator.push(
      context,
      // <<< CORREÇÃO 1: Usando PascalCase para chamar a classe
      MaterialPageRoute(builder: (_) => TelaLogin(tipoUsuario: tipo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bem-vindo ao E-Nosso')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Como você quer entrar?', textAlign: TextAlign.center, style: TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _navegarParaLogin(context, 'lojista'),
                child: const Text('Sou Lojista'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _navegarParaLogin(context, 'prestador'),
                child: const Text('Sou Prestador de Serviço'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _navegarParaLogin(context, 'comum'),
                child: const Text('Sou Usuário Comum'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  // Lógica para visitante: navega direto para a home de visitante
                  Navigator.pushReplacement(
                      context,
                      // <<< CORREÇÃO 1: Usando PascalCase para chamar a classe
                      MaterialPageRoute(builder: (_) => TelaInicialComum()));
                },
                child: const Text('Entrar como Visitante'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
