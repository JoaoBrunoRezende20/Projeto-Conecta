import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class TelaCadastro extends StatefulWidget {
  final String tipoUsuario;
  const TelaCadastro({super.key, required this.tipoUsuario});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // --- VARIÁVEIS PARA OS DROPDOWNS E SELETORES ---
  String? _categoriaSelecionadaCnae;
  String? _estadoSelecionado;
  String? _categoriaPrestadorSelecionada;
  String? _bairroSelecionado;

  // --- LISTAS DE IMAGENS (BASE64) ---
  List<String> _imagensPortfolioBase64 = [];
  List<String> _imagensDocumentosBase64 = [];

  // --- VARIÁVEIS DE VALIDAÇÃO DE SENHA (NOVAS) ---
  bool _temMinimoCaracteres = false;
  bool _temMaiuscula = false;
  bool _temMinuscula = false;
  bool _temNumero = false;
  bool _temEspecial = false;

  // --- LISTAS E REGRAS ---
  final Map<String, String> _mapaRegistroProfissional = {
    'Advogado(a)': 'OAB', 'Arquiteto(a)': 'CAU', 'Contador(a)': 'CRC',
    'Corretor(a) de Imóveis': 'CRECI', 'Dentista': 'CRO', 'Eletricista': 'Certificação (NR10)',
    'Enfermeiro(a)': 'COREN', 'Engenheiro(a)': 'CREA', 'Médico(a)': 'CRM',
    'Motorista': 'CNH', 'Nutricionista': 'CRN', 'Personal Trainer': 'CREF',
    'Psicólogo(a)': 'CRP', 'Veterinário(a)': 'CRMV',
  };

  late final List<String> _categoriasPrestador;
  final List<String> _listaBairros = [
    'Açudes', 'Alto Cruzeiro', 'Campos', 'Candola/Sion', 'Centro', 'Distrito Industrial',
    'Gabiroba', 'Lagoa dos Monjolos', 'Lava Pés', 'Nações', 'Nossa Senhora das Graças',
    'Nossa Senhora de Fátima', 'Rola Moça', 'Sagrado Coração de Jesus', 'São Conrado',
    'Senhora Santana', 'Vila Luchesi', 'Vista Alegre', 'Outros',
  ]..sort();

  final List<String> _estadosLojista = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG',
    'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SE', 'SP', 'TO'
  ];

  final List<String> _categoriasLojista = [
    'Comércio varejista de alimentos em geral ou supermercados',
    'Comércio varejista de bebida',
    'Comércio varejista de artigos de vestuário e acessório',
    'Comércio varejista de calçados',
    'Comércio varejista de móveis, artigos de colchoaria e decoração',
    'Comércio varejista de eletrodomésticos e equipamentos de áudio e vídeo',
    'Comércio varejista de equipamentos de informática e comunicação',
    'Comércio varejista de produtos farmacêuticos',
    'Comércio varejista de materiais de construção',
    'Comércio varejista de artigos de papelaria e material para escritório',
    'Comércio varejista de cosméticos e perfumaria',
    'Comércio varejista de veículos automotores novos',
    'Comércio varejista de peças e acessórios para veículos',
    'Comércio varejista de artigos esportivos',
    'Comércio varejista de brinquedos e artigos recreativos',
    'Comércio varejista de livros, jornais, revistas e papelaria',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _categoriasPrestador = [
      ..._mapaRegistroProfissional.keys,
      'Babá / Cuidador', 'Barbeiro / Cabeleireiro(a)', 'Chaveiro', 'Confeiteiro(a) / Cozinheiro(a)',
      'Diarista / Limpeza', 'Encanador(a)', 'Fotógrafo(a)', 'Jardineiro(a)', 'Manicure / Pedicure',
      'Maquiador(a)', 'Marceneiro', 'Mecânico', 'Montador de Móveis', 'Pedreiro', 'Pintor',
      'Professor(a) Particular', 'Serralheiro', 'Técnico em Informática/Celular',
      'Técnico em Refrigeração/Ar-cond.', 'Técnico em fogões a gás', 'Vidraceiro', 'Outros',
    ]..sort();
  }

  final Map<String, String> _horariosSemanais = {};
  final List<String> _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

  // --- CONTROLLERS ---
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();

  // Lojista
  final _cnpjController = TextEditingController();
  final _emailComercialController = TextEditingController();
  final _razaoSocialController = TextEditingController();
  final _telefoneComercialController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cepController = TextEditingController();
  final _complementoController = TextEditingController();

  // Prestador
  final _outraAreaAtuacaoController = TextEditingController();
  final _descricaoServicosController = TextEditingController();
  final _faixaPrecosController = TextEditingController();
  final _qualificacoesController = TextEditingController();
  final _cnpjPrestadorController = TextEditingController();
  final _registroProfissionalController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _cnpjController.dispose();
    _emailComercialController.dispose();
    _razaoSocialController.dispose();
    _telefoneComercialController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cepController.dispose();
    _complementoController.dispose();
    _outraAreaAtuacaoController.dispose();
    _descricaoServicosController.dispose();
    _faixaPrecosController.dispose();
    _qualificacoesController.dispose();
    _cnpjPrestadorController.dispose();
    _registroProfissionalController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE VALIDAÇÃO DE SENHA (O CÉREBRO) ---
  void _validarSenha(String senha) {
    setState(() {
      _temMinimoCaracteres = senha.length >= 8;
      _temMaiuscula = senha.contains(RegExp(r'[A-Z]'));
      _temMinuscula = senha.contains(RegExp(r'[a-z]'));
      _temNumero = senha.contains(RegExp(r'[0-9]'));
      _temEspecial = senha.contains(RegExp(r'[!@#\$%&*]'));
    });
  }

  bool _isSenhaValida() {
    return _temMinimoCaracteres && _temMaiuscula && _temMinuscula && _temNumero && _temEspecial;
  }

  // --- FUNÇÕES DE IMAGEM ---
  Future<void> _selecionarImagem(bool isPortfolio) async {
    try {
      final List<XFile> imagensSelecionadas = await _picker.pickMultiImage(imageQuality: 50);
      for (var imagem in imagensSelecionadas) {
        final bytes = await imagem.readAsBytes();
        final String base64String = base64Encode(bytes);
        final String header = "data:image/jpeg;base64,$base64String";
        setState(() {
          if (isPortfolio) {
            _imagensPortfolioBase64.add(header);
          } else {
            _imagensDocumentosBase64.add(header);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _removerImagem(int index, bool isPortfolio) {
    setState(() {
      if (isPortfolio) {
        _imagensPortfolioBase64.removeAt(index);
      } else {
        _imagensDocumentosBase64.removeAt(index);
      }
    });
  }

  // --- FUNÇÕES AUXILIARES DE HORÁRIO ---
  Future<void> _selecionarHorario(String dia) async {
    final TimeOfDay? inicio = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Início do atendimento na $dia',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (inicio == null || !mounted) return;

    final TimeOfDay? fim = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Fim do atendimento na $dia',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (fim == null) return;

    setState(() {
      final inicioStr = '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
      final fimStr = '${fim.hour.toString().padLeft(2, '0')}:${fim.minute.toString().padLeft(2, '0')}';
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

  String? _getLabelRegistroProfissional() {
    if (_categoriaPrestadorSelecionada == null) return null;
    return _mapaRegistroProfissional[_categoriaPrestadorSelecionada];
  }

  // --- CADASTRO ---
  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, verifique os campos obrigatórios.')));
      return;
    }

    // <<< VALIDAÇÃO DE SENHA FORTE >>>
    if (!_isSenhaValida()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sua senha é muito fraca. Verifique os requisitos em vermelho.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.tipoUsuario == 'prestador') {
      if (_categoriaPrestadorSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione sua área de atuação.')));
        return;
      }
      if (_bairroSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o bairro de atendimento.')));
        return;
      }
      if (_categoriaPrestadorSelecionada == 'Outros' && _outraAreaAtuacaoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Especifique sua área de atuação.')));
        return;
      }
      if (_horariosSemanais.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos um dia de disponibilidade.')));
        return;
      }
      String? labelRegistro = _getLabelRegistroProfissional();
      if (labelRegistro != null && _imagensDocumentosBase64.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, anexe uma foto do seu $labelRegistro ou documento.')));
        return;
      }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no cadastro: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarDadosNoFirestore(String uid) {
    switch (widget.tipoUsuario) {
      case 'lojista':
        return FirebaseFirestore.instance.collection('lojistas').doc(uid).set({
          'cnpj': _cnpjController.text.trim(),
          'emailComercial': _emailComercialController.text.trim(),
          'razaoSocial': _razaoSocialController.text.trim(),
          'telefoneComercial': _telefoneComercialController.text.trim(),
          'cnae': _categoriaSelecionadaCnae,
          'endereco': {
            'rua': _ruaController.text.trim(),
            'numero': _numeroController.text.trim(),
            'complemento': _complementoController.text.trim(),
            'bairro': _bairroController.text.trim(),
            'estado': _estadoSelecionado,
            'cep': _cepController.text.trim(),
          },
          'dadosDoResponsavel': {
            'nome': _nomeController.text.trim(),
            'sobrenome': _sobrenomeController.text.trim(),
            'cpf': _cpfController.text.trim(),
            'email': _emailController.text.trim(),
            'telefone': _telefoneController.text.trim(),
          },
          'documentosUrl': _imagensDocumentosBase64,
          'dataCriacao': FieldValue.serverTimestamp(),
          'status': false,
          'statusCadastro': 'pendente',
          'motivosRejeicao': '',
          'tipo': 'lojista',
        });

      case 'prestador':
        String areaFinal = _categoriaPrestadorSelecionada!;
        if (areaFinal == 'Outros') {
          areaFinal = _outraAreaAtuacaoController.text.trim();
        }
        String disponibilidadeFinal = _formatarDisponibilidadeParaSalvar();
        double preco = double.tryParse(_faixaPrecosController.text.replaceAll(',', '.')) ?? 0.0;

        return FirebaseFirestore.instance.collection('prestadorServicos').doc(uid).set({
          'nome': _nomeController.text.trim(),
          'sobrenome': _sobrenomeController.text.trim(),
          'telefone': _telefoneController.text.trim(),
          'cpf': _cpfController.text.trim(),
          'email': _emailController.text.trim(),
          'areaAtuacao': areaFinal,
          'descricaoServicos': _descricaoServicosController.text.trim(),
          'areaAtendimento': _bairroSelecionado,
          'disponibilidadeAtendimento': disponibilidadeFinal,
          'faixaPrecos': preco,
          'qualificacoes': _qualificacoesController.text.trim(),
          'cnpj': _cnpjPrestadorController.text.trim(),
          'registroProfissional': _registroProfissionalController.text.trim(),
          'portfolio': _imagensPortfolioBase64,
          'documentosUrl': _imagensDocumentosBase64,
          'status': false,
          'statusCadastro': 'pendente',
          'motivosRejeicao': '',
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
          'status': true,
          'tipo': 'comum',
          'dataCriacao': FieldValue.serverTimestamp(),
        });
    }
  }

  // --- WIDGETS VISUAIS ---

  Widget _buildImagePreview(List<String> imagensBase64, bool isPortfolio) {
    if (imagensBase64.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagensBase64.length,
        itemBuilder: (context, index) {
          final String base64Data = imagensBase64[index].split(',').last;
          final Uint8List bytes = base64Decode(base64Data);
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 100,
                height: 100,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
              Positioned(
                top: 0, right: 8,
                child: InkWell(
                  onTap: () => _removerImagem(index, isPortfolio),
                  child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // <<< NOVO WIDGET: LINHA DO CHECKLIST >>>
  Widget _buildRequisitoRow(String texto, bool atendido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(atendido ? Icons.check_circle : Icons.circle_outlined, color: atendido ? Colors.green : Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: atendido ? Colors.green[900] : Colors.grey[700], fontSize: 12))),
        ],
      ),
    );
  }

  List<Widget> _buildSpecificFields() {
    // (Mantenha o conteúdo anterior da função _buildSpecificFields aqui, igual ao que você já tinha)
    // Vou omitir para não ficar gigante, mas você deve manter a lógica do Lojista e Prestador
    // Se quiser o código completo dessa parte também, me avisa.
    // ...
    // ...
    // Mas ATENÇÃO: Se você copiar e colar o arquivo todo, use a versão anterior
    // do _buildSpecificFields que te passei na resposta passada, ela já estava completa.
    // Aqui vou colocar apenas o "retorno" para exemplificar.
    if (widget.tipoUsuario == 'lojista') {
      // ... (retorne a lista de campos do lojista que fizemos antes)
      return [
        const SizedBox(height: 24),
        const Text('Dados da Empresa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(controller: _razaoSocialController, decoration: const InputDecoration(labelText: 'Razão Social'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        // ... adicione todos os outros campos do lojista aqui ...
        const SizedBox(height: 16),
        TextFormField(controller: _cnpjController, decoration: const InputDecoration(labelText: 'CNPJ'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _emailComercialController, decoration: const InputDecoration(labelText: 'Email Comercial'), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _telefoneComercialController, decoration: const InputDecoration(labelText: 'Telefone Comercial'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _categoriaSelecionadaCnae, decoration: const InputDecoration(labelText: 'Categoria da Loja (CNAE)'), hint: const Text('Selecione uma categoria'), isExpanded: true, items: _categoriasLojista.map((String categoria) => DropdownMenuItem(value: categoria, child: Text(categoria, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => _categoriaSelecionadaCnae = v), validator: (v) => v == null ? 'Selecione uma categoria.' : null),
        const SizedBox(height: 24),
        const Text('Endereço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(controller: _ruaController, decoration: const InputDecoration(labelText: 'Rua / Avenida'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _numeroController, decoration: const InputDecoration(labelText: 'Número'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _complementoController, decoration: const InputDecoration(labelText: 'Complemento (Opcional)')),
        const SizedBox(height: 16),
        TextFormField(controller: _bairroController, decoration: const InputDecoration(labelText: 'Bairro'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _estadoSelecionado, decoration: const InputDecoration(labelText: 'Estado (UF)'), hint: const Text('Selecione'), isExpanded: true, menuMaxHeight: 300, items: _estadosLojista.map((String estado) => DropdownMenuItem(value: estado, child: Text(estado))).toList(), onChanged: (v) => setState(() => _estadoSelecionado = v), validator: (v) => v == null ? 'Selecione um estado.' : null),
        const SizedBox(height: 16),
        TextFormField(controller: _cepController, decoration: const InputDecoration(labelText: 'CEP'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 24),
        const Text('Documentação', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Anexe documentos da empresa (Alvará, Cartão CNPJ)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: () => _selecionarImagem(false), icon: const Icon(Icons.upload_file), label: const Text('Adicionar Documento'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black)),
        const SizedBox(height: 8),
        _buildImagePreview(_imagensDocumentosBase64, false),
      ];
    } else if (widget.tipoUsuario == 'prestador') {
      String? labelRegistro = _getLabelRegistroProfissional();
      bool isRegistroObrigatorio = labelRegistro != null;
      return [
        const SizedBox(height: 24),
        const Text('Dados do Serviço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _categoriaPrestadorSelecionada, decoration: const InputDecoration(labelText: 'Área de Atuação'), hint: const Text('Selecione sua profissão'), isExpanded: true, items: _categoriasPrestador.map((String categoria) => DropdownMenuItem(value: categoria, child: Text(categoria, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() { _categoriaPrestadorSelecionada = v; if (!isRegistroObrigatorio) _registroProfissionalController.clear(); }), validator: (v) => v == null ? 'Selecione sua área.' : null),
        if (_categoriaPrestadorSelecionada == 'Outros') Padding(padding: const EdgeInsets.only(top: 16.0), child: TextFormField(controller: _outraAreaAtuacaoController, decoration: const InputDecoration(labelText: 'Especifique sua área (ex: Jardineiro)'), validator: (v) => v!.isEmpty ? 'Por favor, especifique.' : null)),
        const SizedBox(height: 16),
        TextFormField(controller: _descricaoServicosController, decoration: const InputDecoration(labelText: 'Descrição dos Serviços'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _bairroSelecionado, decoration: const InputDecoration(labelText: 'Área de Atendimento (Bairro)'), hint: const Text('Selecione o bairro principal'), isExpanded: true, menuMaxHeight: 300, items: _listaBairros.map((String bairro) => DropdownMenuItem(value: bairro, child: Text(bairro))).toList(), onChanged: (v) => setState(() => _bairroSelecionado = v), validator: (v) => v == null ? 'Selecione o bairro.' : null),
        const SizedBox(height: 24),
        const Text('Disponibilidade de Atendimento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Toque nos dias da semana para adicionar horários:', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8.0, runSpacing: 8.0, alignment: WrapAlignment.center, children: _diasSemana.map((dia) { bool selecionado = _horariosSemanais.containsKey(dia); return ChoiceChip(label: Text(dia), selected: selecionado, selectedColor: Colors.deepPurple.shade100, onSelected: (bool selected) { if (selected) { _selecionarHorario(dia); } else { _removerHorario(dia); } }); }).toList()),
        if (_horariosSemanais.isNotEmpty) ...[const SizedBox(height: 16), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _horariosSemanais.entries.map((entry) { return Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Row(children: [Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)), Text(entry.value), const Spacer(), InkWell(onTap: () => _removerHorario(entry.key), child: const Icon(Icons.close, size: 16, color: Colors.red))])); }).toList()))],
        const SizedBox(height: 16),
        TextFormField(controller: _faixaPrecosController, decoration: const InputDecoration(labelText: 'Faixa de Preço Média (R\$)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
        const SizedBox(height: 24),
        const Text('Informações Adicionais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(controller: _registroProfissionalController, decoration: InputDecoration(labelText: isRegistroObrigatorio ? 'Número do $labelRegistro' : 'Registro Profissional (Opcional)', helperText: isRegistroObrigatorio ? 'Obrigatório. Anexe o documento abaixo.' : null), validator: (v) { if (isRegistroObrigatorio && (v == null || v.isEmpty)) { return 'Por favor, informe seu $labelRegistro.'; } return null; }),
        const SizedBox(height: 16),
        const Text('Documentos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const Text('Anexe documentos, registros, certificados (Obrigatório para profissões regulamentadas)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: () => _selecionarImagem(false), icon: const Icon(Icons.upload_file), label: const Text('Adicionar Documento'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black)),
        _buildImagePreview(_imagensDocumentosBase64, false),
        const SizedBox(height: 24),
        const Text('Portfólio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const Text('Mostre fotos do seu trabalho', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        ElevatedButton.icon(onPressed: () => _selecionarImagem(true), icon: const Icon(Icons.image), label: const Text('Adicionar Foto ao Portfólio'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black)),
        _buildImagePreview(_imagensPortfolioBase64, true),
        const SizedBox(height: 16),
        TextFormField(controller: _qualificacoesController, decoration: const InputDecoration(labelText: 'Outras Qualificações / Cursos')),
        const SizedBox(height: 16),
        TextFormField(controller: _cnpjPrestadorController, decoration: const InputDecoration(labelText: 'CNPJ (Se houver)'), keyboardType: TextInputType.number),
      ];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro - ${widget.tipoUsuario}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dados Pessoais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _sobrenomeController, decoration: const InputDecoration(labelText: 'Sobrenome'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _cpfController, decoration: const InputDecoration(labelText: 'CPF'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone / Celular'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 16),
                const Divider(),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email de Login'), keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.isEmpty) return 'Obrigatório'; if (!v.contains('@')) return 'Email inválido'; return null; }),

                // <<< CAMPO DE SENHA COM LISTENER >>>
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  onChanged: _validarSenha, // <<< CHAMA A VALIDAÇÃO AO DIGITAR
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Obrigatório';
                    if (!_isSenhaValida()) return 'Senha muito fraca';
                    return null;
                  },
                ),

                // <<< CHECKLIST VISUAL DA SENHA >>>
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildRequisitoRow('Mínimo de 8 caracteres', _temMinimoCaracteres),
                    _buildRequisitoRow('Pelo menos uma letra maiúscula (A-Z)', _temMaiuscula),
                    _buildRequisitoRow('Pelo menos uma letra minúscula (a-z)', _temMinuscula),
                    _buildRequisitoRow('Pelo menos um número (0-9)', _temNumero),
                    _buildRequisitoRow('Pelo menos um caractere especial (ex: !@#\$%&*)', _temEspecial),
                  ],
                ),

                ..._buildSpecificFields(),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _cadastrar,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Finalizar Cadastro'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}