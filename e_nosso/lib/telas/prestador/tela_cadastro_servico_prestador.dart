import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/usuario_util.dart';

class TelaCadastroServicoPrestador extends StatefulWidget {
  final String? servicoId;
  final String? nomeAtual;
  final double? precoAtual;
  final String? imagemBase64Atual;

  const TelaCadastroServicoPrestador({
    super.key,
    this.servicoId,
    this.nomeAtual,
    this.precoAtual,
    this.imagemBase64Atual,
  });

  @override
  State<TelaCadastroServicoPrestador> createState() =>
      _TelaCadastroServicoPrestadorState();
}

class _TelaCadastroServicoPrestadorState
    extends State<TelaCadastroServicoPrestador> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _imagemBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.nomeAtual != null) _nomeController.text = widget.nomeAtual!;
    if (widget.precoAtual != null) {
      _precoController.text = widget.precoAtual!.toStringAsFixed(2);
    }
    if (widget.imagemBase64Atual != null) {
      _imagemBase64 = widget.imagemBase64Atual;
    }
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? imagemSelecionada = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (imagemSelecionada == null) return;

      final bytes = await imagemSelecionada.readAsBytes();
      setState(() {
        _imagemBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
      }
    }
  }

  Future<void> _salvarServico() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String? prestadorId = FirebaseAuth.instance.currentUser?.uid;
      if (prestadorId == null) throw Exception("Usuário não logado");

      final double preco =
          double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0;

      final Map<String, dynamic> dadosServico = {
        'nome': _nomeController.text.trim(),
        'preco': preco,
        'imagemBase64': _imagemBase64,
        'prestadorId': prestadorId,
      };

      if (widget.servicoId == null) {
        // Criar novo
        await FirebaseFirestore.instance
            .collection('servicos')
            .add(dadosServico);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço adicionado com sucesso!')),
          );
        }
      } else {
        // Atualizar existente
        await FirebaseFirestore.instance
            .collection('servicos')
            .doc(widget.servicoId)
            .update(dadosServico);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço atualizado com sucesso!')),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.servicoId == null ? 'Novo Serviço' : 'Editar Serviço',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Seletor de Imagem
                    GestureDetector(
                      onTap: _selecionarImagem,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _imagemBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: UsuarioUtil.buildImageWidget(
                                  _imagemBase64!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Adicionar Foto do Serviço'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo de Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Serviço',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do serviço';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de Preço
                    TextFormField(
                      controller: _precoController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Preço (R\$)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o preço';
                        }
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _salvarServico,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF424242),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        widget.servicoId == null ? 'Adicionar' : 'Salvar',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
