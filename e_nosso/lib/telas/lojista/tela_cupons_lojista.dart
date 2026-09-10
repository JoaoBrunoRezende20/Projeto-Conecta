import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/cupom_repository.dart';
import '../../utils/cupom_util.dart';

class TelaCuponsLojista extends StatefulWidget {
  final String lojistaId;

  const TelaCuponsLojista({super.key, required this.lojistaId});

  @override
  State<TelaCuponsLojista> createState() => _TelaCuponsLojistaState();
}

class _TelaCuponsLojistaState extends State<TelaCuponsLojista> {
  final CupomRepository _cupomRepository = CupomRepository();

  void _abrirModalCadastroCupom([DocumentSnapshot? cupomDoc]) {
    final Map<String, dynamic>? dados =
        cupomDoc != null ? (cupomDoc.data() as Map<String, dynamic>?) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ModalCadastroCupom(
        lojistaId: widget.lojistaId,
        cupomId: cupomDoc?.id,
        dadosIniciais: dados,
        onSalvo: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                cupomDoc != null
                    ? "Cupom atualizado com sucesso!"
                    : "Cupom criado com sucesso!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _excluirCupom(String id, String codigo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Cupom"),
        content: Text("Tem certeza que deseja excluir o cupom \"$codigo\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _cupomRepository.deletarCupom(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cupom excluído com sucesso."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao excluir cupom: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Cupons de Desconto",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalCadastroCupom(),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Novo Cupom",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cupomRepository.getCuponsPorLojista(widget.lojistaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar cupons: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.discount_outlined,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Nenhum cupom criado ainda",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Crie códigos promocionais em porcentagem (%) ou em valor fixo (R\$) para atrair mais clientes para sua loja!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _abrirModalCadastroCupom(),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Criar Primeiro Cupom",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, indexSep) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCardCupom(doc.id, data, doc);
            },
          );
        },
      ),
    );
  }

  Widget _buildCardCupom(String id, Map<String, dynamic> data, DocumentSnapshot doc) {
    final String codigo = data['codigo'] ?? '';
    final String tipoDesconto = data['tipoDesconto'] ?? 'valor';
    final double valorDesconto =
        ((data['valorDesconto'] ?? data['desconto'] ?? 0.0) as num).toDouble();
    final double valorMinimo = ((data['valorMinimo'] ?? 0.0) as num).toDouble();
    final bool ativo = data['ativo'] ?? true;

    DateTime? validade;
    if (data['dataValidade'] != null) {
      if (data['dataValidade'] is Timestamp) {
        validade = (data['dataValidade'] as Timestamp).toDate();
      } else if (data['dataValidade'] is DateTime) {
        validade = data['dataValidade'] as DateTime;
      }
    }

    final bool isPorcentagem = tipoDesconto == 'porcentagem' || tipoDesconto == '%';
    final bool expirado = CupomUtil.isExpirado(data['dataValidade']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ativo && !expirado ? Colors.deepPurple.shade100 : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Faixa Superior
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: ativo && !expirado
                  ? (isPorcentagem ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE))
                  : Colors.grey.shade100,
              child: Row(
                children: [
                  // Badge do Tipo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ativo && !expirado
                          ? (isPorcentagem ? Colors.deepPurple : Colors.blue.shade700)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPorcentagem ? Icons.percent : Icons.attach_money,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CupomUtil.formatarTextoDesconto(tipoDesconto, valorDesconto),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Switch Ativo / Inativo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expirado
                            ? "Expirado"
                            : (ativo ? "Ativo" : "Inativo"),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: expirado
                              ? Colors.red
                              : (ativo ? Colors.green : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: ativo && !expirado,
                        activeColor: Colors.deepPurple,
                        onChanged: (val) async {
                          if (expirado && val) {
                            final dataStr = CupomUtil.formatarDataPtBr(data['dataValidade']);
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Row(
                                  children: [
                                    Icon(Icons.event_busy, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      "Cupom Expirado",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  "Este cupom expirou em $dataStr e não pode ser ativado.\n\nPara ativá-lo, clique no botão de editar (lápis) e defina uma nova data de validade futura.",
                                ),
                                actions: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text("Entendido", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          try {
                            await _cupomRepository.alternarStatusCupom(id, val);
                          } catch (e) {
                            if (context.mounted) {
                              final msg = e.toString().replaceAll('Exception: ', '');
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        "Não foi possível alterar",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  content: Text(msg),
                                  actions: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text("Entendido", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Corpo com informações
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                size: 16, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text(
                              codigo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.2,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                        tooltip: "Copiar Código",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codigo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Código \"$codigo\" copiado!"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                        tooltip: "Editar",
                        onPressed: () => _abrirModalCadastroCupom(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: "Excluir",
                        onPressed: () => _excluirCupom(id, codigo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Detalhes extras
                  Row(
                    children: [
                      if (valorMinimo > 0) ...[
                        const Icon(Icons.shopping_cart_outlined,
                            size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          "Mínimo: R\$ ${valorMinimo.toStringAsFixed(2).replaceAll('.', ',')}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (data['dataValidade'] != null) ...[
                        Icon(
                          Icons.event,
                          size: 14,
                          color: expirado ? Colors.red : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Validade: ${CupomUtil.formatarDataPtBr(data['dataValidade'])}${expirado ? ' (Expirado)' : ''}",
                          style: TextStyle(
                            fontSize: 12,
                            color: expirado ? Colors.red : Colors.black54,
                            fontWeight: expirado ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.all_inclusive, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        const Text(
                          "Sem data de expiração",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalCadastroCupom extends StatefulWidget {
  final String lojistaId;
  final String? cupomId;
  final Map<String, dynamic>? dadosIniciais;
  final VoidCallback onSalvo;

  const _ModalCadastroCupom({
    required this.lojistaId,
    this.cupomId,
    this.dadosIniciais,
    required this.onSalvo,
  });

  @override
  State<_ModalCadastroCupom> createState() => _ModalCadastroCupomState();
}

class _ModalCadastroCupomState extends State<_ModalCadastroCupom> {
  final _formKey = GlobalKey<FormState>();
  final CupomRepository _cupomRepository = CupomRepository();

  late TextEditingController _codigoController;
  late TextEditingController _valorDescontoController;
  late TextEditingController _valorMinimoController;

  String _tipoDesconto = 'porcentagem'; // 'porcentagem' ou 'valor'
  DateTime? _dataValidade;
  bool _ativo = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final d = widget.dadosIniciais;

    _codigoController = TextEditingController(text: d?['codigo'] ?? '');
    _tipoDesconto = d?['tipoDesconto'] ?? 'porcentagem';

    final double vDesconto = ((d?['valorDesconto'] ?? d?['desconto'] ?? 0.0) as num).toDouble();
    _valorDescontoController = TextEditingController(
      text: vDesconto > 0
          ? (_tipoDesconto == 'porcentagem'
              ? (vDesconto % 1 == 0 ? vDesconto.toInt().toString() : vDesconto.toString())
              : vDesconto.toStringAsFixed(2).replaceAll('.', ','))
          : '',
    );

    final double vMinimo = ((d?['valorMinimo'] ?? 0.0) as num).toDouble();
    _valorMinimoController = TextEditingController(
      text: vMinimo > 0 ? vMinimo.toStringAsFixed(2).replaceAll('.', ',') : '',
    );

    if (d?['dataValidade'] != null) {
      if (d!['dataValidade'] is Timestamp) {
        _dataValidade = (d['dataValidade'] as Timestamp).toDate();
      } else if (d['dataValidade'] is DateTime) {
        _dataValidade = d['dataValidade'] as DateTime;
      }
    }

    _ativo = d?['ativo'] ?? true;
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _valorDescontoController.dispose();
    _valorMinimoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataValidade() async {
    final DateTime agora = DateTime.now();
    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: _dataValidade ?? agora,
      firstDate: DateTime(2020),
      lastDate: agora.add(const Duration(days: 365 * 3)),
      helpText: "Selecione a data de expiração",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (escolhida != null) {
      setState(() {
        _dataValidade = DateTime(
          escolhida.year,
          escolhida.month,
          escolhida.day,
          23,
          59,
          59,
          999,
        );
      });
    }
  }

  String? _mensagemErroForm;

  Future<void> _salvar() async {
    setState(() => _mensagemErroForm = null);
    if (!_formKey.currentState!.validate()) return;

    final codigo = _codigoController.text.trim().toUpperCase();
    final double valorDesconto = double.tryParse(
          _valorDescontoController.text.replaceAll(',', '.').trim(),
        ) ??
        0.0;
    final double valorMinimo = double.tryParse(
          _valorMinimoController.text.replaceAll(',', '.').trim(),
        ) ??
        0.0;

    // Validação de data expirada com cupom ativo
    if (_ativo && _dataValidade != null && CupomUtil.isExpirado(_dataValidade)) {
      final msg = "A data de validade selecionada já expirou. Escolha uma data futura ou salve o cupom como inativo.";
      setState(() => _mensagemErroForm = msg);
      _mostrarDialogoErro(msg);
      return;
    }

    setState(() => _salvando = true);

    try {
      final cupomData = <String, dynamic>{
        'codigo': codigo,
        'tipoDesconto': _tipoDesconto,
        'valorDesconto': valorDesconto,
        'desconto': valorDesconto, // Compatibilidade
        'valorMinimo': valorMinimo,
        'ativo': _ativo,
        'lojistaId': widget.lojistaId,
        'dataValidade': _dataValidade != null ? Timestamp.fromDate(_dataValidade!) : null,
      };

      if (widget.cupomId != null) {
        await _cupomRepository.atualizarCupom(widget.cupomId!, cupomData);
      } else {
        await _cupomRepository.criarCupom(cupomData);
      }

      widget.onSalvo();
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() => _mensagemErroForm = msg);
        _mostrarDialogoErro(msg);
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarDialogoErro(String mensagem) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text("Atenção", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          mensagem,
          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Entendido", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior do modal
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.cupomId != null ? "Editar Cupom" : "Novo Cupom Promocional",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // BANNER DE ERRO DESTACADO NA TELA SE HOUVER ERRO
              if (_mensagemErroForm != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300, width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensagemErroForm!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // CÓDIGO DO CUPOM
              const Text(
                "Código Promocional",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _codigoController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                ],
                decoration: InputDecoration(
                  hintText: "Ex: PROMO10, VERAO2026",
                  prefixIcon: const Icon(Icons.discount, color: Colors.deepPurple),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Informe o código do cupom.";
                  }
                  if (val.trim().length < 3) {
                    return "O código deve ter pelo menos 3 caracteres.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // SELEÇÃO DO TIPO DE DESCONTO: 2 OPÇÕES
              const Text(
                "Tipo de Desconto",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // OPÇÃO 1: PORCENTAGEM
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _tipoDesconto = 'porcentagem';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _tipoDesconto == 'porcentagem'
                              ? Colors.deepPurple.shade50
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tipoDesconto == 'porcentagem'
                                ? Colors.deepPurple
                                : Colors.grey.shade300,
                            width: _tipoDesconto == 'porcentagem' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.percent,
                              color: _tipoDesconto == 'porcentagem'
                                  ? Colors.deepPurple
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Porcentagem (%)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _tipoDesconto == 'porcentagem'
                                    ? Colors.deepPurple
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // OPÇÃO 2: VALOR FIXO
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _tipoDesconto = 'valor';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _tipoDesconto == 'valor'
                              ? Colors.blue.shade50
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tipoDesconto == 'valor'
                                ? Colors.blue.shade700
                                : Colors.grey.shade300,
                            width: _tipoDesconto == 'valor' ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: _tipoDesconto == 'valor'
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Valor Fixo (R\$)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _tipoDesconto == 'valor'
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // VALOR DO DESCONTO
              Text(
                _tipoDesconto == 'porcentagem'
                    ? "Porcentagem de Desconto"
                    : "Valor do Desconto em Reais",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _valorDescontoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: _tipoDesconto == 'porcentagem' ? "Ex: 10 (para 10%)" : "Ex: 15,00",
                  prefixText: _tipoDesconto == 'valor' ? "R\$ " : null,
                  suffixText: _tipoDesconto == 'porcentagem' ? "%" : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Informe o valor do desconto.";
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '.').trim());
                  if (parsed == null || parsed <= 0) {
                    return "Informe um número válido maior que zero.";
                  }
                  if (_tipoDesconto == 'porcentagem' && parsed > 100) {
                    return "A porcentagem não pode ultrapassar 100%.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // VALOR MÍNIMO (OPCIONAL)
              const Text(
                "Valor Mínimo do Pedido (Opcional)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _valorMinimoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "Ex: 50,00 (deixe vazio se não houver)",
                  prefixText: "R\$ ",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // DATA DE VALIDADE (OPCIONAL)
              const Text(
                "Data de Validade (Opcional)",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selecionarDataValidade,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_ativo && _dataValidade != null && CupomUtil.isExpirado(_dataValidade))
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: (_ativo && _dataValidade != null && CupomUtil.isExpirado(_dataValidade))
                            ? Colors.red
                            : Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dataValidade != null
                                  ? CupomUtil.formatarDataPtBr(_dataValidade)
                                  : "Sem data de expiração (válido indefinidamente)",
                              style: TextStyle(
                                color: (_ativo && _dataValidade != null && CupomUtil.isExpirado(_dataValidade))
                                    ? Colors.red
                                    : (_dataValidade != null ? Colors.black87 : Colors.grey.shade600),
                                fontSize: 14,
                                fontWeight: _dataValidade != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (_dataValidade != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                CupomUtil.isExpirado(_dataValidade)
                                    ? "⚠️ Esta data já passou (Cupom expirado)"
                                    : "Válido até 23:59:59 deste dia",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupomUtil.isExpirado(_dataValidade) ? Colors.red : Colors.grey[600],
                                  fontWeight: CupomUtil.isExpirado(_dataValidade) ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_dataValidade != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                          tooltip: "Remover Data",
                          onPressed: () {
                            setState(() {
                              _dataValidade = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SWITCH ATIVO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cupom Ativo",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        "Clientes poderão usar este código na finalização do pedido",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Switch(
                    value: _ativo,
                    activeColor: Colors.deepPurple,
                    onChanged: (val) => setState(() => _ativo = val),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // BOTÃO SALVAR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          widget.cupomId != null ? "Atualizar Cupom" : "Criar Cupom",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
