import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'telaCadastroUsuarios.dart'; // Certifique-se de que este import está correto

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
  // NOVO: Estado para controlar a visibilidade da senha (Toggle)
  bool _isPasswordVisible = false;

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
        // Exemplo: Navegar para a tela inicial após o login
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

  // >>> FUNÇÃO DE RECUPERAÇÃO DE SENHA (SIMPLIFICADA) <<<
  // Mantendo a estrutura original sem a implementação completa de Dialogs.
  void _esqueceuSenha() {
    // Apenas um TODO simples ou uma mensagem básica para evitar o crash
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ainda precisamos implementar a recuperação de senha.')),
    );
    // Se você quiser a implementação completa (com AlertDialog), me avise!
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

        // Campo Senha (COM TOGGLE)
        const Text('Senha:', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _senhaController,
          // Usa o estado para ocultar/mostrar o texto
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            // Adiciona o ícone de toggle
            suffixIcon: IconButton(
              icon: Icon(
                // Alterna entre os ícones eye e eye-slash
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                // Altera o estado para fazer o toggle
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
        // Fim do Campo Senha modificado

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
              onPressed: _esqueceuSenha, // Chama a função simples
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