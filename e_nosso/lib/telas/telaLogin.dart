import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaCadastroUsuarios.dart';

// <<< CORREÇÃO 1: Nome da classe em PascalCase
class TelaLogin extends StatefulWidget {
  final String tipoUsuario;

  // <<< CORREÇÃO 1: Construtor com o mesmo nome da classe
  const TelaLogin({super.key, required this.tipoUsuario});

  @override
  // <<< CORREÇÃO 1: Padrão _ClassNameState
  State<TelaLogin> createState() => _TelaLoginState();
}

// <<< CORREÇÃO 1: Padrão _ClassNameState
class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  // <<< DICA DE PROFISSIONAL: O método dispose para limpar os controladores
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Sua lógica de login está perfeita!
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      // A navegação automática pelo AuthWrapper é a abordagem correta.
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no login: ${e.message ?? "Ocorreu um erro."}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login - ${widget.tipoUsuario}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(controller: _senhaController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: const Text('Entrar')),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                // <<< CORREÇÃO 1: Chamando a classe de cadastro com PascalCase
                MaterialPageRoute(builder: (_) => TelaCadastro(tipoUsuario: widget.tipoUsuario)),
              ),
              child: const Text('Não tem uma conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}
