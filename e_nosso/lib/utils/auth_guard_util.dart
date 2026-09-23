import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../telas/auth/tela_login.dart';
import '../telas/auth/tela_cadastro_usuarios.dart';

class AuthGuardUtil {
  /// Retorna true se o usuário está logado com uma conta real (não anônima).
  static bool get isUsuarioAutenticado {
    try {
      final user = FirebaseAuth.instance.currentUser;
      return user != null && !user.isAnonymous;
    } catch (_) {
      return false;
    }
  }

  /// Retorna true se o usuário for visitante (não logado ou anônimo).
  static bool get isVisitante => !isUsuarioAutenticado;

  /// Verifica se o usuário é visitante e intercepta a ação.
  /// Se já estiver autenticado com conta real, executa imediatamente [onAutenticado].
  /// Se for visitante/anônimo, exibe o AlertDialog padrão idêntico ao do carrinho solicitando Login ou Cadastro.
  static Future<void> executarComAutenticacao(
    BuildContext context, {
    required VoidCallback onAutenticado,
    String titulo = "Autenticação necessária",
    String mensagem =
        "Você precisa entrar na sua conta ou se cadastrar para entrar em contato com o prestador.",
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final bool isVisitor = user == null || user.isAnonymous;

    if (!isVisitor) {
      onAutenticado();
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaLogin(
                    tipoUsuario: 'comum',
                  ),
                ),
              );
            },
            child: const Text("Entrar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TelaCadastro(
                    tipoUsuario: 'comum',
                  ),
                ),
              );
            },
            child: const Text("Cadastrar"),
          ),
        ],
      ),
    );
  }
}
