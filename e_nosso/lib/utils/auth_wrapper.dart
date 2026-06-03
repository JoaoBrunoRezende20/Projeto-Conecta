import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../repositories/usuario_repository.dart';

// Ajuste os imports abaixo de acordo com o caminho das suas telas
import '../telas/auth/tela_tipo_usuario.dart';
import '../telas/cliente/tela_inicial_comum.dart';
import '../telas/lojista/tela_inicial_lojista.dart';
import '../telas/prestador/tela_inicial_prestador_servico.dart';
import '../telas/admin/tela_inicial_administrador.dart';

class AuthWrapper extends StatelessWidget {
  final AuthRepository _authRepository = AuthRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges,
      builder: (context, snapshot) {
        // 1. Estado de carregamento do Firebase Auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Se o utilizador está logado, vamos descobrir o seu perfil no Firestore
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Widget>(
            // Envia o UID do utilizador logado para a função de verificação
            future: _redirecionarPorPerfil(snapshot.data!.uid),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (futureSnapshot.hasData) {
                return futureSnapshot.data!; // Vai para a Tela do Lojista, Prestador ou Cliente
              }
              
              // Se falhar (ex: documento do Firestore foi apagado manualmente), força logout e volta
              _authRepository.sair();
              return const TelaTipoUsuario();
            },
          );
        }

        // 3. Se não está logado, vai para a tela de escolha
        return const TelaTipoUsuario();
      },
    );
  }

  // --- LÓGICA DE VERIFICAÇÃO DE PERFIL ---
  Future<Widget> _redirecionarPorPerfil(String uid) async {
    try {
      final colecao = await _usuarioRepository.descobrirPerfilUsuario(uid);
      
      switch (colecao) {
        case 'admins':
          return const TelaInicialAdministrador();
        case 'lojistas':
          return const TelaInicialLojista();
        case 'prestadorServicos':
          return const TelaInicialPrestador();
        case 'usuarioComum':
          return const TelaInicialComum();
        default:
          return const TelaTipoUsuario();
      }
    } catch (e) {
      debugPrint('Erro ao redirecionar: $e');
    }

    // Retorno de segurança caso não ache em lugar nenhum
    return const TelaTipoUsuario();
  }
}