// importando os pacotes necessários
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // O arquivo FlutterFire

// O bloco principal de inicialização
void main() async {
  // inicializa o flutter antes de chamar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Apos conectado roda o app
  runApp(const MyApp());
}

// O início do app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Por exemplo, a tela de login que você vai criar
      home: Scaffold(
        appBar: AppBar(
          title: Text('App Conectado ao Firebase!'),
        ),
        body: Center(
          child: Text('Firebase foi inicializado com sucesso!'),
        ),
      ),
    );
  }
}