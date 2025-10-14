import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaCadastro extends StatefulWidget {
  final String tipoUsuario;
  const TelaCadastro({super.key, required this.tipoUsuario});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  // controllers
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    // É uma boa prática limpar todos os controllers
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    // lógica de cadastro
    if (_emailController.text.trim().isEmpty || _senhaController.text.trim().isEmpty || _nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha os campos obrigatórios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      await _salvarDadosNoFirestore(credencial.user!.uid);

      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no cadastro: ${e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _salvarDadosNoFirestore(String uid) {
    switch (widget.tipoUsuario) {
      case 'lojista':
        return FirebaseFirestore.instance.collection('lojistas').doc(uid).set({
          'dadosDoResponsavel': {
            'nome': _nomeController.text.trim(),
            'sobrenome': _sobrenomeController.text.trim(),
            'cpf': _cpfController.text.trim(),
            'email': _emailController.text.trim(),
            'telefone': _telefoneController.text.trim(),
          },
          'statusCadastro': 'pendente',
          'ativo': false,
          'tipo': 'lojista',
          'dataCriacao': FieldValue.serverTimestamp(),
        });
      case 'prestador':
        return FirebaseFirestore.instance.collection('prestadorServicos').doc(uid).set({
          'nome': _nomeController.text.trim(),
          'sobrenome': _sobrenomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'email': _emailController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'statusCadastro': 'pendente',
          'ativo': false,
          'tipo': 'prestador',
          'dataCriacao': FieldValue.serverTimestamp(),
        });
      case 'comum':
      default:
        return FirebaseFirestore.instance.collection('usuarioComum').doc(uid).set({
          'nome': _nomeController.text.trim(),
          'sobrenome': _sobrenomeController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'email': _emailController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'ativo': true,
          'tipo': 'comum',
          'dataCriacao': FieldValue.serverTimestamp(),
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro - ${widget.tipoUsuario}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 16),
              TextField(controller: _sobrenomeController, decoration: const InputDecoration(labelText: 'Sobrenome')),
              const SizedBox(height: 16),
              TextField(controller: _cpfController, decoration: const InputDecoration(labelText: 'CPF')),
              const SizedBox(height: 16),


              TextField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone / Celular'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextField(controller: _senhaController, decoration: const InputDecoration(labelText: 'Senha'), obscureText: true),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _cadastrar, child: const Text('Finalizar Cadastro')),
            ],
          ),
        ),
      ),
    );
  }
}
