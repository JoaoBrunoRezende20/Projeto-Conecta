import 'package:flutter/material.dart';

class TelaDefinicaoSenha extends StatefulWidget {
  const TelaDefinicaoSenha({super.key});

  @override
  State<TelaDefinicaoSenha> createState() => _TelaDefinicaoSenhaState();
}

class _TelaDefinicaoSenhaState extends State<TelaDefinicaoSenha> {
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // --- ESTADOS DE VALIDAÇÃO ---
  bool _temMinimoCaracteres = false;
  bool _temMaiuscula = false;
  bool _temMinuscula = false;
  bool _temNumero = false;
  bool _temEspecial = false;
  bool _senhasIguais = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE VALIDAÇÃO (O CÉREBRO) ---
  void _validarSenha(String senha) {
    setState(() {
      // 1. Mínimo de 8 caracteres
      _temMinimoCaracteres = senha.length >= 8;

      // 2. Pelo menos uma letra maiúscula (RegEx)
      _temMaiuscula = senha.contains(RegExp(r'[A-Z]'));

      // 3. Pelo menos uma letra minúscula (RegEx)
      _temMinuscula = senha.contains(RegExp(r'[a-z]'));

      // 4. Pelo menos um número (RegEx)
      _temNumero = senha.contains(RegExp(r'[0-9]'));

      // 5. Pelo menos um caractere especial (!@#$%&*)
      _temEspecial = senha.contains(RegExp(r'[!@#\$%&*]'));

      // Verifica se as senhas batem (caso já tenha digitado a confirmação)
      _checarSenhasIguais();
    });
  }

  void _checarSenhasIguais() {
    setState(() {
      _senhasIguais = _senhaController.text == _confirmarSenhaController.text &&
          _senhaController.text.isNotEmpty;
    });
  }

  // Verifica se TUDO está válido para habilitar o botão
  bool _isFormularioValido() {
    return _temMinimoCaracteres &&
        _temMaiuscula &&
        _temMinuscula &&
        _temNumero &&
        _temEspecial &&
        _senhasIguais;
  }

  Future<void> _confirmarAlteracao() async {
    if (_isFormularioValido()) {
      // TODO: Aqui você chama o Firebase para atualizar a senha
      // await currentUser.updatePassword(_senhaController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha definida com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Volta para a tela anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Defina sua senha',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Digite e confirme abaixo sua nova senha. Ela deve ter:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            // --- CHECKLIST VISUAL ---
            _buildRequisitoRow('Mínimo de 8 caracteres', _temMinimoCaracteres),
            _buildRequisitoRow('Pelo menos uma letra maiúscula (A-Z)', _temMaiuscula),
            _buildRequisitoRow('Pelo menos uma letra minúscula (a-z)', _temMinuscula),
            _buildRequisitoRow('Pelo menos um número (0-9)', _temNumero),
            _buildRequisitoRow('Pelo menos um caractere especial (ex: !@#\$%&*)', _temEspecial),

            const SizedBox(height: 32),

            // --- CAMPO SENHA ---
            const Text('Digite aqui sua senha:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _senhaController,
              obscureText: true,
              onChanged: _validarSenha, // <<< Chama a validação a cada letra digitada
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- CAMPO CONFIRMAR SENHA ---
            const Text('Confirme sua senha:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmarSenhaController,
              obscureText: true,
              onChanged: (val) => _checarSenhasIguais(), // Verifica igualdade
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                // Feedback visual extra no campo de confirmação
                suffixIcon: _confirmarSenhaController.text.isNotEmpty
                    ? (_senhasIguais
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error, color: Colors.red))
                    : null,
              ),
            ),

            const SizedBox(height: 40),

            // --- BOTÃO ---
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isFormularioValido() ? _confirmarAlteracao : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF424242), // Cor escura do seu design
                  disabledBackgroundColor: Colors.grey, // Cor quando bloqueado
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Confirmar senha', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dúvidas para definir/redefinir sua senha? Acesse o '),
                InkWell(
                  onTap: () { /* TODO: FAQ */ },
                  child: const Text(
                    'FAQ',
                    style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA O CHECKLIST ---
  Widget _buildRequisitoRow(String texto, bool atendido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // O ícone muda de "bolinha" para "check"
          Icon(
            atendido ? Icons.check_circle : Icons.circle_outlined,
            color: atendido ? Colors.green : Colors.red, // Verde se atendeu, Vermelho se não
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                // Opcional: riscar o texto ou mudar a cor se atendido
                color: atendido ? Colors.green[900] : Colors.black87,
                decoration: atendido ? TextDecoration.none : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}