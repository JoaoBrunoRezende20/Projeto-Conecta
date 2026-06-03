import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/auth_wrapper.dart';

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
        '/bebidas': (_) => const CategoriaBebidas(),
        '/comidas': (_) => const CategoriaComidas(),
        '/servicos': (_) => const CategoriaServicos(),
        '/feira': (_) => const CategoriaFeiraLivre(),
        '/outros': (_) => const CategoriaOutros(),
      },
    );
  }
}

