import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/auth_wrapper.dart';

// telas
import 'telas/cliente/tela_divisao_categoria.dart';
import 'telas/categorias/categoria_outros.dart';
import 'telas/categorias/categoria_comidas.dart';
import 'telas/categorias/categoria_servicos.dart';

// Telas importadas não são todas necessárias se o AuthWrapper cuidar disso, mas mantemos por segurança.

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
      home: AuthWrapper(),

      routes: {
        '/categorias': (_) => const TelaDivisaoCategoria(),
        '/comidas': (_) => const CategoriaComidas(),
        '/servicos': (_) => const CategoriaServicos(),
        '/outros': (_) => const CategoriaOutros(),
      },
    );
  }
}

