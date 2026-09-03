import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaSuporteChamado extends StatefulWidget {
  final bool isVisitante;
  const TelaSuporteChamado({super.key, required this.isVisitante});

  @override
  State<TelaSuporteChamado> createState() => _TelaSuporteChamadoState();
}

class _TelaSuporteChamadoState extends State<TelaSuporteChamado> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _emailContatoController = TextEditingController();
  
  String _categoriaSelecionada = 'Erro no app';
  final List<String> _categorias = [
    'Erro no app',
    'Pedido com problema',
    'Falha de cadastro',
    'Dúvida financeira',
    'Outro'
  ];
  
  bool _isLoading = false;

  @override
  void dispose() {
    _descricaoController.dispose();
    _emailContatoController.dispose();
    super.dispose();
  }

  Future<void> _enviarChamado() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      final dadosChamado = {
        'categoria': _categoriaSelecionada,
        'descricao': _descricaoController.text.trim(),
        'uid': user?.uid ?? 'visitante',
        'emailContato': widget.isVisitante ? _emailContatoController.text.trim() : (user?.email ?? ''),
        'status': 'aberto',
        'dataCriacao': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('chamados').add(dadosChamado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chamado enviado com sucesso! Nossa equipe entrará em contato."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao enviar chamado: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Abrir um Chamado", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Como podemos te ajudar?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Preencha o formulário abaixo com os detalhes do seu problema.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              if (widget.isVisitante) ...[
                TextFormField(
                  controller: _emailContatoController,
                  decoration: InputDecoration(
                    labelText: "E-mail para contato",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Informe um e-mail";
                    if (!val.contains('@')) return "Informe um e-mail válido";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: InputDecoration(
                  labelText: "Categoria",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _categoriaSelecionada = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText: "Descrição detalhada do problema",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Descreva seu problema";
                  if (val.trim().length < 10) return "A descrição deve ter ao menos 10 caracteres";
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarChamado,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Enviar Chamado", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
