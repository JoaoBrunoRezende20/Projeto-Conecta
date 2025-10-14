import 'package:flutter/material.dart';
import 'telaLogin.dart';
import 'telaInicialComum.dart';

class TelaTipoUsuario extends StatelessWidget {
  const TelaTipoUsuario({super.key});


  void _navegarParaLogin(BuildContext context, String tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaLogin(tipoUsuario: tipo)),
    );
  }

  // A PARTE VISUAL (TODA REFEITA)
  @override
  Widget build(BuildContext context) {
    // Definindo um estilo de botão para reutilizar
    final ButtonStyle estiloBotao = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE0E0E0), // Cinza claro
      foregroundColor: Colors.black, // Cor do texto
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // Bordas bem arredondadas
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar transparente
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // TODO: Implementar lógica para abrir o menu lateral (Drawer)
          },
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () {
              // TODO: Implementar lógica de voltar, se aplicável nesta tela
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Como deseja Logar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: estiloBotao,
                onPressed: () => _navegarParaLogin(context, 'comum'),
                child: const Text('Cliente/Outro'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: estiloBotao,
                onPressed: () => _navegarParaLogin(context, 'prestador'),
                child: const Text('Prestador de serviço'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: estiloBotao,
                onPressed: () => _navegarParaLogin(context, 'lojista'),
                child: const Text('Lojista'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: estiloBotao,
                onPressed: () {
                  // Lógica para visitante: navega direto para a home de visitante
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaInicialComum()),
                  );
                },
                child: const Text('Visitante'),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Dúvidas no cadastro? Acesse o '),
                  InkWell(
                    onTap: () {
                      // TODO: Implementar navegação para a tela de FAQ
                    },
                    child: const Text(
                      'FAQ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

