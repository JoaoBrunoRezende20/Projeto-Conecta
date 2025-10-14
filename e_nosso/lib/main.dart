import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// <<< CORREÇÃO 1: Padronizando o nome da pasta para 'telas' (tudo minúsculo)
import 'telas/telaTipoUsuario.dart';
import 'telas/telaInicialComum.dart';
import 'telas/telaInicialLojista.dart';
import 'telas/telaInicialPrestadorServico.dart';
import 'telas/telaInicialAdministrador.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E_nosso App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Sua lógica para buscar o tipo de usuário está perfeita!
  Future<String> _getUserType(String uid) async {
    var doc = await FirebaseFirestore.instance.collection('administrador').doc(uid).get();
    if (doc.exists) return 'administrador';

    doc = await FirebaseFirestore.instance.collection('lojistas').doc(uid).get();
    if (doc.exists) return 'lojista';

    doc = await FirebaseFirestore.instance.collection('prestadorServicos').doc(uid).get();
    if (doc.exists) return 'prestador';

    // Se não for nenhum dos acima, é um usuário comum
    return 'comum';
  }

  // Sua lógica para escolher a tela home está perfeita!
  Widget _getHomeScreen(String tipo) {
    switch (tipo) {
      case 'administrador':
        return TelaInicialAdministrador();
      case 'lojista':
      // <<< CORREÇÃO 1: Usando PascalCase para chamar as classes
        return  TelaInicialLojista();
      case 'prestador':
        return  TelaInicialPrestador();
      case 'comum':
      default:
        return  TelaInicialComum();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // <<< DICA 2: Usando 'const'
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          // Sua lógica de FutureBuilder está perfeita!
          return FutureBuilder<String>(
            future: _getUserType(snapshot.data!.uid),
            builder: (context, typeSnapshot) {
              if (typeSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final tipo = typeSnapshot.data ?? 'comum';
              return _getHomeScreen(tipo);
            },
          );
        }


        return  TelaTipoUsuario();
      },
    );
  }
}

