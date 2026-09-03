import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../utils/usuario_util.dart';

class TelaCadastroServicoPrestador extends StatefulWidget {
  final String? servicoId;
  final String? nomeAtual;
  final double? precoAtual;
  final String? imagemUrlAtual;

  const TelaCadastroServicoPrestador({
    super.key,
    this.servicoId,
    this.nomeAtual,
    this.precoAtual,
    this.imagemUrlAtual,
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
  String? _imagemUrl;
  Uint8List? _imagemBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.nomeAtual != null) _nomeController.text = widget.nomeAtual!;
    if (widget.precoAtual != null) {
      _precoController.text = widget.precoAtual!.toStringAsFixed(2);
    }
    if (widget.imagemUrlAtual != null) {
      _imagemUrl = widget.imagemUrlAtual;
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
        _imagemBytes = bytes;
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

      String? urlFinal = _imagemUrl;

      if (_imagemBytes != null) {
        debugPrint('>>> [SERVICO] Enviando foto do serviço para o Storage...');
        final ref = FirebaseStorage.instance
            .ref()
            .child('servicos')
            .child(prestadorId)
            .child('img_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = ref.putData(
          _imagemBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('Tempo limite esgotado ao enviar foto do serviço.'),
        );
        urlFinal = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Tempo limite ao obter URL da foto do serviço.'),
        );
        debugPrint('>>> [SERVICO] Foto enviada com sucesso: $urlFinal');
      }

      final Map<String, dynamic> dadosServico = {
        'nome': _nomeController.text.trim(),
        'preco': preco,
        'imagemUrl': urlFinal,
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
                        child: _imagemBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imagemBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _imagemUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: UsuarioUtil.buildImageWidget(
                                      _imagemUrl!,
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
                        labelText: 'Preço (R$) - Opcional',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value.replaceAll(',', '.')) == null) {
                            return 'Valor inválido';
                          }
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
