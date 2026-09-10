import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/usuario_repository.dart';
import '../../utils/usuario_util.dart';
import '../../widgets/modal_enquadrar_foto.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditarPerfilPage extends StatefulWidget {
  const EditarPerfilPage({super.key});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final AuthRepository _authRepository = AuthRepository();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _areaAtuacaoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _descricaoController = TextEditingController();

  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();

  final Map<String, String> _horariosSemanais = {};
  final List<String> _diasSemana = [
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];

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

  String? _fotoPerfilUrl;
  Uint8List? _fotoPerfilBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _areaAtuacaoController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _descricaoController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();

    super.dispose();
  }

  Future<void> _selecionarNovaFoto() async {
    try {
      final XFile? imagem = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();
      if (!mounted) return;

      final bool isLojista = _colecaoUsuario == 'lojistas';
      final bytesEnquadrados = await ModalEnquadrarFoto.exibir(
        context,
        bytes,
        titulo: isLojista ? 'Enquadrar Logotipo' : 'Enquadrar Foto de Perfil',
        descricao: isLojista
            ? 'Enquadre o logotipo da sua loja na moldura quadrada fixa 1:1.'
            : 'Enquadre a foto do seu rosto na moldura quadrada fixa 1:1.',
      );
      if (bytesEnquadrados == null) return;

      setState(() {
        _fotoPerfilBytes = bytesEnquadrados;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar foto: $e')),
        );
      }
    }
  }

  Future<void> _carregarDadosUsuario() async {
    final user = _authRepository.usuarioAtual;
    if (user == null) return;
    _userId = user.uid;

    try {
      final colecao = await _usuarioRepository.descobrirPerfilUsuario(_userId!);

      if (colecao != null) {
        _colecaoUsuario = colecao;
        _isPrestador = colecao == 'prestadorServicos';
        final bool isLojista = colecao == 'lojistas';

        final doc = await _usuarioRepository.getUsuario(_userId!, colecao);
        final data = doc.data() as Map<String, dynamic>;

        if (isLojista || _isPrestador) {
          _fotoPerfilUrl =
              (data['fotoPerfilUrl'] ?? data['logoUrl'] ?? data['imagemUrl'])
                  ?.toString();
        } else {
          _fotoPerfilUrl = null;
        }

        _emailController.text =
            data['email'] ?? data['emailComercial'] ?? user.email ?? '';

        if (_colecaoUsuario == 'lojistas') {
          _nomeController.text = data['razaoSocial'] ?? '';
          _documentoController.text = data['cnpj'] ?? '';
          _telefoneController.text = data['telefoneComercial'] ?? '';
        } else {
          _nomeController.text =
              data['nome'] ?? data['nomeCompleto'] ?? data['razaoSocial'] ?? '';
          _documentoController.text = data['cpf'] ?? '';
          _telefoneController.text = data['telefone'] ?? '';
        }

        // Carrega o endereço
        final endereco = data['endereco'];
        if (endereco != null && endereco is Map) {
          _ruaController.text = endereco['rua']?.toString() ?? '';
          _numeroController.text = endereco['numero']?.toString() ?? '';
          _complementoController.text = endereco['complemento']?.toString() ?? '';
          _bairroController.text = endereco['bairro']?.toString() ?? '';
        } else {
          _ruaController.text = data['rua'] ?? '';
          _numeroController.text = data['numero'] ?? '';
          _complementoController.text = data['complemento'] ?? '';
          _bairroController.text = data['bairro'] ?? '';
        }

        if (_isPrestador) {
          _areaAtuacaoController.text = data['areaAtuacao'] ?? '';
          _descricaoController.text =
              data['descricaoServicos'] ?? data['descricao'] ?? '';
          _parseDisponibilidade(data['disponibilidadeAtendimento']);
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar perfil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parseDisponibilidade(String? disponibilidade) {
    if (disponibilidade == null ||
        disponibilidade == "Não informado" ||
        disponibilidade.isEmpty) {
      return;
    }

    try {
      final partes = disponibilidade.split(", ");
      for (var parte in partes) {
        final subPartes = parte.split(": ");
        if (subPartes.length == 2) {
          _horariosSemanais[subPartes[0]] = subPartes[1];
        }
      }
    } catch (e) {
      debugPrint("Erro ao parsear disponibilidade: $e");
    }
  }

  Future<void> _selecionarHorario(String dia) async {
    final TimeOfDay? inicio = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Início do atendimento na $dia',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (inicio == null || !mounted) return;

    final TimeOfDay? fim = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Fim do atendimento na $dia',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (fim == null || !mounted) return;

    setState(() {
      final inicioStr =
          '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
      final fimStr =
          '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
      _horariosSemanais[dia] = '$inicioStr às $fimStr';
    });
  }

  void _removerHorario(String dia) {
    setState(() {
      _horariosSemanais.remove(dia);
    });
  }

  String _formatarDisponibilidadeParaSalvar() {
    if (_horariosSemanais.isEmpty) return "Não informado";
    final buffer = StringBuffer();
    for (var dia in _diasSemana) {
      if (_horariosSemanais.containsKey(dia)) {
        if (buffer.isNotEmpty) buffer.write(", ");
        buffer.write("$dia: ${_horariosSemanais[dia]}");
      }
    }
    return buffer.toString();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> dadosAtualizados = {};

      final enderecoMap = {
        'rua': _ruaController.text.trim(),
        'numero': _numeroController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'complemento': _complementoController.text.trim(),
      };

      // Salva os dados dependendo da coleção
      if (_colecaoUsuario == 'lojistas') {
        dadosAtualizados['razaoSocial'] = _nomeController.text.trim();
        dadosAtualizados['cnpj'] = _documentoController.text.trim();
        dadosAtualizados['telefoneComercial'] = _telefoneController.text.trim();
        dadosAtualizados['emailComercial'] = _emailController.text.trim();
        dadosAtualizados['endereco'] = enderecoMap;
      } else if (_colecaoUsuario == 'usuarioComum') {
        dadosAtualizados['nomeCompleto'] = _nomeController.text.trim();
        dadosAtualizados['cpf'] = _documentoController.text.trim();
        dadosAtualizados['telefone'] = _telefoneController.text.trim();
        dadosAtualizados['email'] = _emailController.text.trim();
        dadosAtualizados['endereco'] = enderecoMap;
        dadosAtualizados['fotoPerfilUrl'] = FieldValue.delete();
        dadosAtualizados['logoUrl'] = FieldValue.delete();
        dadosAtualizados['imagemUrl'] = FieldValue.delete();
      } else {
        dadosAtualizados['nome'] = _nomeController.text.trim();
        dadosAtualizados['cpf'] = _documentoController.text.trim();
        dadosAtualizados['telefone'] = _telefoneController.text.trim();
        dadosAtualizados['email'] = _emailController.text.trim();
        dadosAtualizados['endereco'] = enderecoMap;
      }

      if (_isPrestador) {
        dadosAtualizados['areaAtuacao'] = _areaAtuacaoController.text.trim();
        dadosAtualizados['descricaoServicos'] = _descricaoController.text.trim();
        dadosAtualizados['disponibilidadeAtendimento'] =
            _formatarDisponibilidadeParaSalvar();
      }

      // Se uma nova foto foi selecionada, faz o upload para o Storage ou Base64 (somente para lojista e prestador)
      final bool isLojistaOuPrestador = _colecaoUsuario == 'lojistas' || _isPrestador;
      if (isLojistaOuPrestador && _fotoPerfilBytes != null && _userId != null) {
        final pasta = _colecaoUsuario == 'lojistas' ? 'logos' : 'fotosPerfil';
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child('usuarios')
              .child(_userId!)
              .child(pasta)
              .child('perfil_${DateTime.now().millisecondsSinceEpoch}.jpg');

          final uploadTask = ref.putData(
            _fotoPerfilBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final snapshot = await uploadTask.timeout(const Duration(seconds: 5));
          final url = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 4));
          dadosAtualizados['fotoPerfilUrl'] = url;
          dadosAtualizados['logoUrl'] = url;
          dadosAtualizados['imagemUrl'] = url;
          _fotoPerfilUrl = url;
        } catch (storageErr) {
          debugPrint('>>> [PERFIL] Fallback Base64 para foto: $storageErr');
          final base64Str = base64Encode(_fotoPerfilBytes!);
          dadosAtualizados['fotoPerfilUrl'] = base64Str;
          dadosAtualizados['logoUrl'] = base64Str;
          dadosAtualizados['imagemUrl'] = base64Str;
          _fotoPerfilUrl = base64Str;
        }
      }

      await _usuarioRepository.salvarDadosUsuario(
        _userId!,
        _colecaoUsuario,
        dadosAtualizados,
      );

      // Sincroniza Auth se necessário
      final user = _authRepository.usuarioAtual;
      if (user != null) {
        if (!isLojistaOuPrestador && user.photoURL != null) {
          try {
            await user.updatePhotoURL(null);
          } catch (_) {}
        }
        final novoEmail = _emailController.text.trim();
        if (novoEmail.isNotEmpty && novoEmail != user.email) {
          try {
            await user.verifyBeforeUpdateEmail(novoEmail);
          } catch (e) {
            debugPrint("Aviso ao atualizar e-mail no Auth: $e");
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar perfil: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLojista = _colecaoUsuario == 'lojistas';
    final bool isLojistaOuPrestador = isLojista || _isPrestador;
    final bool temImagem = _fotoPerfilBytes != null ||
        (_fotoPerfilUrl != null && _fotoPerfilUrl!.isNotEmpty);

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
                    // --- SEÇÃO DE FOTO DE PERFIL / LOGOTIPO (SOMENTE LOJISTA E PRESTADOR) ---
                    if (isLojistaOuPrestador) ...[
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: isLojista
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                    borderRadius: isLojista
                                        ? BorderRadius.circular(16)
                                        : null,
                                    border: Border.all(
                                      color: Colors.deepPurple,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: isLojista
                                        ? BorderRadius.circular(14)
                                        : BorderRadius.circular(55),
                                    child: _fotoPerfilBytes != null
                                        ? Image.memory(
                                            _fotoPerfilBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : (_fotoPerfilUrl != null &&
                                                _fotoPerfilUrl!.isNotEmpty
                                            ? UsuarioUtil.buildImageWidget(
                                                _fotoPerfilUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : Center(
                                                child: Icon(
                                                  isLojista
                                                      ? Icons
                                                          .store_mall_directory_outlined
                                                      : Icons.person_outline,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                              )),
                                  ),
                                ),
                                // Botão circular de câmera/edição
                                InkWell(
                                  onTap: _selecionarNovaFoto,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _selecionarNovaFoto,
                              child: Text(
                                temImagem
                                    ? "Trocar Foto de Perfil"
                                    : "Selecionar Foto de Perfil",
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      "Nome / Razão Social:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Seu nome",
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? "Campo obrigatório"
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "E-mail (Gmail):",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "seuemail@gmail.com",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Campo obrigatório";
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return "E-mail inválido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Documento (${_colecaoUsuario == 'lojistas' ? 'CNPJ' : 'CPF'}):",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _documentoController,
                      inputFormatters: [
                        _colecaoUsuario == 'lojistas'
                            ? _cnpjFormatter
                            : _cpfFormatter,
                      ],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: _colecaoUsuario == 'lojistas'
                            ? "00.000.000/0000-00"
                            : "000.000.000-00",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Campo obrigatório";
                        }
                        if (_colecaoUsuario == 'lojistas' && value.length < 18) {
                          return "CNPJ inválido";
                        }
                        if (_colecaoUsuario != 'lojistas' && value.length < 14) {
                          return "CPF inválido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_colecaoUsuario != 'lojistas') ...[
                      const Text(
                        "Telefone:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                          if (value == null || value.trim().isEmpty) {
                            return "Campo obrigatório";
                          }
                          if (value.length < 14) {
                            return "Telefone inválido";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(height: 32),
                    const Text(
                      "Endereço",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Rua / Avenida:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ruaController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Nome da rua ou avenida",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Número:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _numeroController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Número",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Bairro:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bairroController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Digite seu bairro",
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Complemento (Opcional):",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _complementoController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Apto, Bloco, etc.",
                      ),
                    ),
                    const Divider(height: 32),
                    if (_isPrestador) ...[
                      const Text(
                        "Área de atuação:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _areaAtuacaoController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Ex: Encanador, Eletricista",
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Campo obrigatório"
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Descrição / Sobre você:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              "Descreva seus serviços, sua experiência, etc.",
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Campo obrigatório"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Disponibilidade de Atendimento:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque nos dias da semana para adicionar horários:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: _diasSemana.map((dia) {
                          bool selecionado = _horariosSemanais.containsKey(dia);
                          return ChoiceChip(
                            label: Text(dia),
                            selected: selecionado,
                            selectedColor: Colors.deepPurple.shade100,
                            onSelected: (bool selected) {
                              if (selected) {
                                _selecionarHorario(dia);
                              } else {
                                _removerHorario(dia);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      if (_horariosSemanais.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _horariosSemanais.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    Text(
                                      '${entry.key}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(entry.value),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () => _removerHorario(entry.key),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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
