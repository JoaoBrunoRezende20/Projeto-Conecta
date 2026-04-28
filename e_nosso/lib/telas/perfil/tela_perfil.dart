import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _areaAtuacaoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cnpjFormatter = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  
  bool _isLoading = true;
  String? _userId;
  String _colecaoUsuario = 'usuarioComum';
  bool _isPrestador = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaAtuacaoController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userId = user.uid;

    try {
      // Tenta achar em prestadorServicos
      var doc = await FirebaseFirestore.instance.collection('prestadorServicos').doc(_userId).get();
      if (doc.exists) {
        _colecaoUsuario = 'prestadorServicos';
        _isPrestador = true;
      } else {
        // Tenta lojista
        doc = await FirebaseFirestore.instance.collection('lojistas').doc(_userId).get();
        if (doc.exists) {
          _colecaoUsuario = 'lojistas';
        } else {
          // Tenta usuario comum
          doc = await FirebaseFirestore.instance.collection('usuarioComum').doc(_userId).get();
          if (doc.exists) {
            _colecaoUsuario = 'usuarioComum';
          }
        }
      }

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (_colecaoUsuario == 'lojistas') {
          _nomeController.text = data['razaoSocial'] ?? '';
          _documentoController.text = data['cnpj'] ?? '';
          _telefoneController.text = data['telefoneComercial'] ?? '';
        } else {
          _nomeController.text = data['nome'] ?? data['nomeCompleto'] ?? data['razaoSocial'] ?? '';
          _documentoController.text = data['cpf'] ?? '';
          _telefoneController.text = data['telefone'] ?? '';
        }
        
        if (_isPrestador) {
          _areaAtuacaoController.text = data['areaAtuacao'] ?? '';
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> dadosAtualizados = {};
      
      // Salva o nome na chave correta dependendo da coleção
      if (_colecaoUsuario == 'lojistas') {
        dadosAtualizados['razaoSocial'] = _nomeController.text.trim();
        dadosAtualizados['cnpj'] = _documentoController.text.trim();
        dadosAtualizados['telefoneComercial'] = _telefoneController.text.trim();
      } else if (_colecaoUsuario == 'usuarioComum') {
        dadosAtualizados['nomeCompleto'] = _nomeController.text.trim();
        dadosAtualizados['cpf'] = _documentoController.text.trim();
        dadosAtualizados['telefone'] = _telefoneController.text.trim();
      } else {
        dadosAtualizados['nome'] = _nomeController.text.trim();
        dadosAtualizados['cpf'] = _documentoController.text.trim();
        dadosAtualizados['telefone'] = _telefoneController.text.trim();
      }

      if (_isPrestador) {
        dadosAtualizados['areaAtuacao'] = _areaAtuacaoController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection(_colecaoUsuario)
          .doc(_userId)
          .update(dadosAtualizados);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar perfil: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Nome / Razão Social:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Seu nome",
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? "Campo obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    Text("Documento (${_colecaoUsuario == 'lojistas' ? 'CNPJ' : 'CPF'}):", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _documentoController,
                      inputFormatters: [_colecaoUsuario == 'lojistas' ? _cnpjFormatter : _cpfFormatter],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: _colecaoUsuario == 'lojistas' ? "00.000.000/0000-00" : "000.000.000-00",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Campo obrigatório";
                        if (_colecaoUsuario == 'lojistas' && value.length < 18) return "CNPJ inválido";
                        if (_colecaoUsuario != 'lojistas' && value.length < 14) return "CPF inválido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Telefone:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _telefoneController,
                      inputFormatters: [_telefoneFormatter],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "(00) 00000-0000",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Campo obrigatório";
                        if (value.length < 14) return "Telefone inválido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_isPrestador) ...[
                      const Text("Área de atuação:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _areaAtuacaoController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Ex: Encanador, Eletricista",
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? "Campo obrigatório" : null,
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _salvarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF424242),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Salvar Alterações"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
