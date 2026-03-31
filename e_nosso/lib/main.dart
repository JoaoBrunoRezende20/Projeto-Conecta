import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// telas
import 'telas/auth/tela_tipo_usuario.dart';
import 'telas/cliente/tela_inicial_comum.dart';
import 'telas/lojista/tela_inicial_lojista.dart';
import 'telas/prestador/tela_inicial_prestador_servico.dart';
import 'telas/admin/tela_inicial_administrador.dart';
import 'telas/cliente/tela_divisao_categoria.dart';
import 'telas/categorias/categoria_bebidas.dart';
import 'telas/categorias/categoria_feira_livre.dart';
import 'telas/categorias/categoria_outros.dart';
import 'telas/categorias/categoria_quitandas.dart';
import 'telas/categorias/categoria_servicos.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E_nosso App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),

      // AQUI ESTÁ A CORREÇÃO
      home: const AuthWrapper(),

      routes: {
        '/categorias': (_) => const TelaDivisaoCategoria(),
        '/bebidas': (_) => const CategoriaBebidas(),
        '/quitandas': (_) => const CategoriaQuitandas(),
        '/servicos': (_) => const CategoriaServicos(),
        '/feira': (_) => const CategoriaFeiraLivre(),
        '/outros': (_) => const CategoriaOutros(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> _getUserType(String uid) async {
    var doc = await FirebaseFirestore.instance
        .collection('administrador')
        .doc(uid)
        .get();
    if (doc.exists) return 'administrador';

    doc = await FirebaseFirestore.instance
        .collection('lojistas')
        .doc(uid)
        .get();
    if (doc.exists) return 'lojista';

    doc = await FirebaseFirestore.instance
        .collection('prestadorServicos')
        .doc(uid)
        .get();
    if (doc.exists) return 'prestador';

    return 'comum';
  }

  Widget _getHomeScreen(String tipo) {
    switch (tipo) {
      case 'administrador':
        return TelaInicialAdministrador();
      case 'lojista':
        return TelaInicialLojista();
      case 'prestador':
        return TelaInicialPrestador();
      case 'comum':
      default:
        return TelaInicialComum();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<String>(
            future: _getUserType(snapshot.data!.uid),
            builder: (context, typeSnapshot) {
              if (typeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final tipo = typeSnapshot.data ?? 'comum';
              return _getHomeScreen(tipo);
            },
          );
        }

        // se não estiver logado → vai para escolha de tipo de usuário
        return const TelaTipoUsuario();
      },
    );
  }
}
