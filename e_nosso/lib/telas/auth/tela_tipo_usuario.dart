import 'package:flutter/material.dart';
import 'tela_login.dart';
import '../cliente/tela_inicial_comum.dart';
import '../suporte/tela_faq.dart';

class TelaTipoUsuario extends StatelessWidget {
  const TelaTipoUsuario({super.key});

  void _navegarParaLogin(BuildContext context, String tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TelaLogin(tipoUsuario: tipo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definindo o estilo base dos botões
    final ButtonStyle estiloBotao = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE0E0E0), // Cinza claro
      foregroundColor: Colors.black, // Cor do texto e ícone
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      // Alinha o conteúdo à esquerda se quiser que o ícone fique fixo,
      // ou no centro (padrão). Vamos manter padrão centralizado.
      alignment: Alignment.center,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      // Removi a AppBar para limpar a tela. O SafeArea cuida do espaçamento no topo.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1), // Empurra o conteúdo um pouco para baixo

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

              // Botão Cliente
              ElevatedButton.icon(
                style: estiloBotao,
                onPressed: () => _navegarParaLogin(context, 'comum'),
                icon: const Icon(Icons.person, size: 28, color: Colors.black),
                label: const Text('Cliente/Outro'),
              ),

              const SizedBox(height: 20),

              // Botão Prestador
              ElevatedButton.icon(
                style: estiloBotao,
                onPressed: () => _navegarParaLogin(context, 'prestador'),
                icon: const Icon(Icons.handyman, size: 28, color: Colors.black),
                label: const Text('Prestador de serviço'),
              ),

              const SizedBox(height: 20),

              // Botão Lojista
              ElevatedButton.icon(
                style: estiloBotao,
                onPressed: () => _navegarParaLogin(context, 'lojista'),
                icon: const Icon(Icons.store, size: 28, color: Colors.black),
                label: const Text('Lojista'),
              ),

              const SizedBox(height: 20),

              // Botão Visitante
              ElevatedButton.icon(
                style: estiloBotao,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TelaInicialComum()),
                  );
                },
                icon: const Icon(
                  Icons.visibility,
                  size: 28,
                  color: Colors.black,
                ),
                label: const Text('Visitante'),
              ),

              const Spacer(flex: 2), // Espaço flexível no final
              // Botão de FAQ no final da tela
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaFaq()),
    );
  },
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    color: Colors.grey.shade200,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.help_outline, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          "Tem dúvidas? Acesse o FAQ",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
