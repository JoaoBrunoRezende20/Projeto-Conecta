import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/produto_repository.dart';
import '../../utils/usuario_util.dart';
import '../../widgets/modal_enquadrar_foto.dart';

/// Tela para criação e edição completa de produtos do lojista (nome, preço, descrição, foto e estoque).
class TelaCadastroProdutoLojista extends StatefulWidget {
  final String? produtoId;
  final String? lojistaId;
  final String? nomeAtual;
  final String? descricaoAtual;
  final double? precoAtual;
  final int? estoqueAtual;
  final String? imagemUrlAtual;

  const TelaCadastroProdutoLojista({
    super.key,
    this.produtoId,
    this.lojistaId,
    this.nomeAtual,
    this.descricaoAtual,
    this.precoAtual,
    this.estoqueAtual,
    this.imagemUrlAtual,
  });

  @override
  State<TelaCadastroProdutoLojista> createState() =>
      _TelaCadastroProdutoLojistaState();
}

class _TelaCadastroProdutoLojistaState
    extends State<TelaCadastroProdutoLojista> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  final TextEditingController _estoqueController = TextEditingController();

  final ProdutoRepository _produtoRepository = ProdutoRepository();
  final ImagePicker _picker = ImagePicker();

  String? _imagemUrl;
  Uint8List? _imagemBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.nomeAtual != null) _nomeController.text = widget.nomeAtual!;
    if (widget.descricaoAtual != null) {
      _descricaoController.text = widget.descricaoAtual!;
    }
    if (widget.precoAtual != null) {
      _precoController.text = widget.precoAtual!.toStringAsFixed(2);
    }
    if (widget.estoqueAtual != null) {
      _estoqueController.text = widget.estoqueAtual.toString();
    }
    if (widget.imagemUrlAtual != null && widget.imagemUrlAtual!.isNotEmpty) {
      _imagemUrl = widget.imagemUrlAtual;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    try {
      final XFile? imagemSelecionada = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imagemSelecionada == null) return;

      final bytes = await imagemSelecionada.readAsBytes();
      if (!mounted) return;

      // Abre o diálogo de enquadramento com proporção fixa 1:1
      final bytesEnquadrados = await ModalEnquadrarFoto.exibir(context, bytes);
      if (bytesEnquadrados == null) return;

      setState(() {
        _imagemBytes = bytesEnquadrados;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String? lojistaId =
          widget.lojistaId ?? FirebaseAuth.instance.currentUser?.uid;
      if (lojistaId == null || lojistaId.isEmpty) {
        throw Exception("Lojista não identificado.");
      }

      final double preco = double.tryParse(
            _precoController.text.replaceAll(',', '.').trim(),
          ) ??
          0.0;
      final int estoque =
          int.tryParse(_estoqueController.text.trim()) ?? 0;

      String? urlFinal = _imagemUrl;

      if (_imagemBytes != null) {
        // Tenta enviar para o Firebase Storage com fallback automático
        try {
          debugPrint('>>> [PRODUTO] Enviando foto do produto para o Firebase Storage...');
          final ref = FirebaseStorage.instance
              .ref()
              .child('produtos')
              .child(lojistaId)
              .child('img_${DateTime.now().millisecondsSinceEpoch}.jpg');

          final uploadTask = ref.putData(
            _imagemBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final snapshot = await uploadTask.timeout(
            const Duration(seconds: 8),
          );
          urlFinal = await snapshot.ref.getDownloadURL().timeout(
            const Duration(seconds: 6),
          );
          debugPrint('>>> [PRODUTO] Foto enviada com sucesso ao Storage: $urlFinal');
        } catch (storageError) {
          debugPrint('>>> [PRODUTO] Aviso no Storage ($storageError), aplicando fallback seguro para Base64.');
          final base64String = base64Encode(_imagemBytes!);
          urlFinal = 'data:image/jpeg;base64,$base64String';
        }
      }

      final Map<String, dynamic> dadosProduto = {
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'preco': preco,
        'estoque': estoque,
        'ativo': estoque > 0,
        'imagemUrl': urlFinal,
        'lojistaId': lojistaId,
      };

      if (widget.produtoId == null) {
        // Criar novo produto
        await _produtoRepository.adicionarProduto(dadosProduto);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produto adicionado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Atualizar produto existente
        await _produtoRepository.atualizarProduto(
          widget.produtoId!,
          dadosProduto,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produto atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdicao = widget.produtoId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEdicao ? 'Editar Produto' : 'Novo Produto',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Seletor de Imagem com Preview
                    GestureDetector(
                      onTap: _selecionarImagem,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _imagemBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  _imagemBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : _imagemUrl != null && _imagemUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: UsuarioUtil.buildImageWidget(
                                      _imagemUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 48,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isEdicao
                                            ? 'Alterar Foto do Produto'
                                            : 'Adicionar Foto do Produto',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _selecionarImagem,
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: Text(
                          _imagemBytes != null || (_imagemUrl != null && _imagemUrl!.isNotEmpty)
                              ? 'Trocar Foto'
                              : 'Escolher Foto da Galeria',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Produto *',
                        hintText: 'Ex: Pão de Queijo Artesanal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do produto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de Descrição
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descrição do Produto',
                        hintText: 'Descreva os detalhes, ingredientes ou características...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Linha Preço e Estoque
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precoController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Preço (R\$) *',
                              hintText: '0.00',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o preço';
                              }
                              final precoNum = double.tryParse(
                                value.replaceAll(',', '.').trim(),
                              );
                              if (precoNum == null || precoNum < 0) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _estoqueController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Estoque (Unid.) *',
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o estoque';
                              }
                              final estoqueNum = int.tryParse(value.trim());
                              if (estoqueNum == null || estoqueNum < 0) {
                                return 'Estoque inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _salvarProduto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdicao ? 'Salvar Alterações' : 'Cadastrar Produto',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
