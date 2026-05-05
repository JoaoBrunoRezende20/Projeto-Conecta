import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ajuste os imports abaixo de acordo com o caminho das suas telas
import '../telas/auth/tela_tipo_usuario.dart';
import '../telas/cliente/tela_inicial_comum.dart';
import '../telas/lojista/tela_inicial_lojista.dart';
import '../telas/prestador/tela_inicial_prestador_servico.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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
              FirebaseAuth.instance.signOut();
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
      // Tenta encontrar o UID na coleção de Lojistas
      final lojistaDoc = await FirebaseFirestore.instance.collection('lojistas').doc(uid).get();
      if (lojistaDoc.exists) {
        return const TelaInicialLojista();
      }

      // Tenta encontrar o UID na coleção de Prestadores
      final prestadorDoc = await FirebaseFirestore.instance.collection('prestadorServicos').doc(uid).get();
      if (prestadorDoc.exists) {
        return const TelaInicialPrestador();
      }

      // Tenta encontrar o UID na coleção de Clientes (Comum)
      final comumDoc = await FirebaseFirestore.instance.collection('usuarioComum').doc(uid).get();
      if (comumDoc.exists) {
        return const TelaInicialComum();
      }
    } catch (e) {
      debugPrint('Erro ao redirecionar: $e');
    }

    // Retorno de segurança caso não ache em lugar nenhum
    return const TelaTipoUsuario();
  }
}