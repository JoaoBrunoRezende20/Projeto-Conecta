// importando os pacotes necessários
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORTE O PACOTE DE AUTENTICAÇÃO
import 'firebase_options.dart';

// IMPORTE AS NOVAS TELAS QUE CRIAMOS
import 'Telas/telaTipoUsuario.dart';
import 'Telas/telaInicialComum.dart';


// O bloco principal de inicialização (continua o mesmo)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// O início do app (continua o mesmo)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // AQUI ESTÁ A MUDANÇA: a "home" agora é o nosso Porteiro Inteligente
      home: AuthWrapper(),
    );
  }
}


// O "PORTEIRO INTELIGENTE" QUE VERIFICA O LOGIN
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // O StreamBuilder fica "ouvindo" o status da autenticação em tempo real
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Se estiver esperando a resposta do Firebase, mostra um "carregando"
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se o snapshot TEM um usuário (ou seja, o usuário ESTÁ LOGADO)...
        if (snapshot.hasData) {
          // Manda ele para a tela inicial
          // MAIS TARDE, AQUI VAI A LÓGICA PARA ESCOLHER ENTRE AS HOMES
          return telaInicialComum();
        }

        // Se NÃO TEM um usuário (ou seja, está DESLOGADO)...
        else {
          // Manda ele para a tela de escolher o tipo de usuário
          return telaTipoUsuario();
        }
      },
    );
  }
}