import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaCadastroUsuarios.dart';

class TelaLogin extends StatefulWidget {
  final String tipoUsuario;
  const TelaLogin({super.key, required this.tipoUsuario});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;
  bool _lembrarMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String mensagemErro;
        if (e.code == 'user-not-found') {
          mensagemErro = 'Usuário não encontrado.';
        } else if (e.code == 'wrong-password') {
          mensagemErro = 'Senha incorreta.';
        } else {
          mensagemErro = 'Erro no login: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // <<< FUNÇÃO DE RECUPERAÇÃO CORRIGIDA >>>
  Future<void> _esqueceuSenha() async {
    final emailControllerRecuperacao = TextEditingController();

    // Pré-preenche se já tiver digitado no login
    if (_emailController.text.isNotEmpty) {
      emailControllerRecuperacao.text = _emailController.text;
    }

    return showDialog(
      context: context,
      builder: (dialogContext) { // Usei um nome diferente para o contexto do Dialog
        return AlertDialog(
          title: const Text('Recuperar Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Digite seu email para receber o link de redefinição.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailControllerRecuperacao,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailControllerRecuperacao.text.trim();
                if (email.isEmpty) {
                  // Mostra aviso rápido se o campo estiver vazio
                  // Usamos ScaffoldMessenger.of(context) aqui porque dialogContext é local
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, digite o email.')),
                  );
                  return;
                }

                // 1. Fecha o diálogo de digitação PRIMEIRO
                Navigator.pop(dialogContext);

                // 2. Mostra um novo diálogo de "Enviando..." que não pode ser fechado pelo usuário
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  // 3. Tenta enviar o e-mail (Isso pode demorar um pouco)
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                  // 4. Se chegou aqui, deu certo! Fecha o diálogo de loading
                  // Usamos o 'context' principal e pop() para tirar o loading da frente
                  if (mounted) Navigator.of(context).pop();

                  // 5. Mostra o FEEDBACK DE SUCESSO
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(child: Text('Email enviado! Verifique sua caixa de entrada e spam.')),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 5),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  // Fecha o loading se der erro
                  if (mounted) Navigator.of(context).pop();

                  if (mounted) {
                    String erroMsg = 'Erro ao enviar email.';
                    if (e.code == 'user-not-found') erroMsg = 'Email não cadastrado.';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(erroMsg),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } catch (e) {
                  // Fecha o loading para qualquer outro erro
                  if (mounted) Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Enviar Link'),
            ),
          ],
        );
      },
    );
  }

  String _getTituloBoasVindas() {
    switch (widget.tipoUsuario) {
      case 'lojista':
        return 'Bem-vindo, Lojista!';
      case 'prestador':
        return 'Acesse seu painel, Prestador!';
      case 'comum':
        return 'Olá! Que bom te ver de novo.';
      default:
        return 'Login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 80, color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _getTituloBoasVindas().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildLoginForm(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Não tem uma conta ainda?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TelaCadastro(tipoUsuario: widget.tipoUsuario)),
                            );
                          },
                          child: const Text('Cadastre-se', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Digite seu email:', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        const Text('Senha:', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _senhaController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _lembrarMe,
                  onChanged: (value) => setState(() => _lembrarMe = value!),
                ),
                const Text('Lembrar-me'),
              ],
            ),
            TextButton(
              onPressed: _esqueceuSenha,
              child: const Text('Esqueceu a senha?'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.grey[700],
            ),
            child: const Text('ENTRAR', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width / 4, size.height, size.width / 2, size.height * 0.8);
    path.quadraticBezierTo(size.width * 3 / 4, size.height * 0.6, size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}