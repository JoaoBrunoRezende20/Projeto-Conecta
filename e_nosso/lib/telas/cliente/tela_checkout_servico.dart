import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'tela_historico_pedidos.dart';
import 'tela_confirmacao_servico.dart';

class TelaCheckoutServico extends StatefulWidget {
  final List<Map<String, dynamic>> servicosSelecionados;
  final String nomePrestador;
  final String prestadorId;

  const TelaCheckoutServico({
    super.key,
    required this.servicosSelecionados,
    required this.nomePrestador,
    required this.prestadorId,
  });

  @override
  State<TelaCheckoutServico> createState() => _TelaCheckoutServicoState();
}

class _TelaCheckoutServicoState extends State<TelaCheckoutServico> {
  String? diaSelecionado;
  String? horarioSelecionado;
  List<String> diasDisponiveis = [];
  Map<String, List<String>> horariosPorDia = {};
  bool carregandoDisponibilidade = true;
  DateTime? dataSelecionadaCalendario;
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final FocusNode _enderecoFocus = FocusNode();
  final FocusNode _telefoneFocus = FocusNode();
  String? pagamentoSelecionado;

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _observacaoController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _enderecoFocus.dispose();
    _telefoneFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _buscarDisponibilidade();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          if (data?['endereco'] != null)
            _enderecoController.text = data!['endereco'];
          if (data?['telefone'] != null) {
            _telefoneController.text = _telefoneFormatter.maskText(
              data!['telefone'],
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Erro ao buscar dados do usuário: $e");
    }
  }

  Future<void> _buscarDisponibilidade() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('prestadorServicos')
          .doc(widget.prestadorId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final disponib = data?['disponibilidadeAtendimento'] as String?;
        if (disponib != null && disponib != "Não informado") {
          _parseDisponibilidade(disponib);
        } else {
          _usarDisponibilidadePadrao();
        }
      } else {
        _usarDisponibilidadePadrao();
      }
    } catch (e) {
      debugPrint("Erro ao buscar disponibilidade: $e");
      _usarDisponibilidadePadrao();
    } finally {
      if (mounted) setState(() => carregandoDisponibilidade = false);
    }
  }

  void _parseDisponibilidade(String texto) {
    final partes = texto.split(', ');
    for (var parte in partes) {
      final subPartes = parte.split(': ');
      if (subPartes.length == 2) {
        final dia = subPartes[0];
        final rangePartes = subPartes[1].split(' às ');
        if (rangePartes.length == 2) {
          diasDisponiveis.add(dia);
          horariosPorDia[dia] = _gerarSlots(rangePartes[0], rangePartes[1]);
        }
      }
    }
  }

  void _usarDisponibilidadePadrao() {
    final dias = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];
    for (var dia in dias) {
      diasDisponiveis.add(dia);
      horariosPorDia[dia] = _gerarSlots("08:00", "18:00");
    }
  }

  List<String> _gerarSlots(String inicio, String fim) {
    List<String> slots = [];
    try {
      int hInicio = int.parse(inicio.split(':')[0]);
      int hFim = int.parse(fim.split(':')[0]);
      for (int i = hInicio; i < hFim; i++) {
        slots.add("${i.toString().padLeft(2, '0')}:00");
        slots.add("${i.toString().padLeft(2, '0')}:30");
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return slots;
  }

  String _getDiaDaSemana(DateTime date) {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[date.weekday % 7];
  }

  Future<void> _selecionarData(BuildContext context) async {
    if (carregandoDisponibilidade) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Carregando disponibilidade... Aguarde.")),
      );
      return;
    }

    if (diasDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este prestador não possui dias de atendimento configurados.")),
      );
      return;
    }

    // Normaliza para considerar apenas a data, sem horas
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year, now.month, now.day);
    DateTime initialDate = firstDate;

    // Busca o primeiro dia disponível a partir de hoje (procura em até 365 dias)
    bool encontrouDia = false;
    for (int i = 0; i < 365; i++) {
      DateTime candidate = initialDate.add(Duration(days: i));
      if (diasDisponiveis.contains(_getDiaDaSemana(candidate))) {
        initialDate = candidate;
        encontrouDia = true;
        break;
      }
    }

    if (!encontrouDia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("O prestador não possui disponibilidade configurada."),
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime date) {
        String dayName = _getDiaDaSemana(date);
        return diasDisponiveis.contains(dayName);
      },
    );

    if (picked != null) {
      setState(() {
        dataSelecionadaCalendario = picked;
        diaSelecionado = _getDiaDaSemana(picked);
        horarioSelecionado = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = widget.servicosSelecionados.fold(
      0.0,
      (acc, item) => acc + (item['preco'] ?? 0.0),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.black),
        title: Text(
          widget.nomePrestador,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_circle_left_outlined,
              color: Colors.black,
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 20),
              child: Text(
                "AGENDAMENTO DOS SERVIÇOS",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text(
                    "Serviços escolhidos",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: widget.servicosSelecionados.length,
                      itemBuilder: (context, index) {
                        final item = widget.servicosSelecionados[index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            children: [
                              Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[600],
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Center(
                                  child: Text(
                                    "*Imagens do serviço",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item['nome'],
                                style: const TextStyle(fontSize: 9),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "R\$${item['preco'].toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              "*Descrição geral dos serviços prestados",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),

            const SizedBox(height: 20),
            // Campo de Observação
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _observacaoController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Adicionar observação...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  contentPadding: const EdgeInsets.all(15),
                ),
              ),
            ),

            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Colors.black87,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.home_outlined,
                        color: Colors.black87,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _enderecoController,
                            focusNode: _enderecoFocus,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              hintText: "Rua xxxxxxx, 99, Bairro",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.grey,
                          size: 22,
                        ),
                        onPressed: () => _enderecoFocus.requestFocus(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      "NUMERO PARA CONTATO",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Colors.black87,
                        size: 24,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _telefoneController,
                            focusNode: _telefoneFocus,
                            inputFormatters: [_telefoneFormatter],
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            decoration: const InputDecoration(
                              hintText: "(xx) 9xxxx-xxxx",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.grey,
                          size: 22,
                        ),
                        onPressed: () => _telefoneFocus.requestFocus(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      "OPÇÕES DE PAGAMENTO",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildPaymentOption("Cartão", Icons.credit_card, "Cartão"),
                  _buildPaymentOption("PIX", Icons.pix, "PIX"),
                  _buildPaymentOption(
                    "Dinheiro",
                    Icons.attach_money,
                    "Dinheiro",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text("Total", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 10),
                Text(
                  "R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _selecionarData(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          dataSelecionadaCalendario == null
                              ? "Calendário"
                              : DateFormat(
                                  'dd/MM',
                                ).format(dataSelecionadaCalendario!),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.calendar_month, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                _buildDropdown(
                  "Horários",
                  horarioSelecionado,
                  diaSelecionado != null
                      ? (horariosPorDia[diaSelecionado!] ?? [])
                      : [],
                  (val) {
                    setState(() => horarioSelecionado = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _salvarAgendamento(context, total),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Agendar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String value) {
    bool isSelected = pagamentoSelecionado == value;
    return GestureDetector(
      onTap: () => setState(() => pagamentoSelecionado = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.black87 : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 15),
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 9, color: Colors.black),
          ),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 10)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _salvarAgendamento(BuildContext context, double total) async {
    if (diaSelecionado == null || horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione dia e horário no calendário.")),
      );
      return;
    }
    if (_enderecoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, informe seu endereço.")),
      );
      return;
    }
    if (_telefoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, informe seu telefone para contato."),
        ),
      );
      return;
    }
    if (pagamentoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione uma forma de pagamento.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('pedidos').add({
      'clienteId': user.uid,
      'prestador': widget.nomePrestador,
      'prestadorId': widget.prestadorId,
      'servicos': widget.servicosSelecionados,
      'valor': total,
      'dia': diaSelecionado,
      'data': dataSelecionadaCalendario != null
          ? DateFormat('dd/MM/yyyy').format(dataSelecionadaCalendario!)
          : diaSelecionado,
      'horario': horarioSelecionado,
      'status': 'Pendente',
      'observacao': _observacaoController.text,
      'endereco': _enderecoController.text,
      'telefone': _telefoneController.text,
      'pagamento': pagamentoSelecionado,
      'tipo': 'servico',
      'dataCriacao': FieldValue.serverTimestamp(),
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TelaConfirmacaoServico()),
    );
  }
}
