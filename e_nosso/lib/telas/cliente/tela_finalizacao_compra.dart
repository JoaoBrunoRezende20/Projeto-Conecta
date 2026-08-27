import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../services/carrinho_service.dart';
import '../../repositories/pedido_repository.dart';
import '../../repositories/produto_repository.dart';

class TelaDadosEntrega extends StatefulWidget {
  final double valorTotal;
  const TelaDadosEntrega({super.key, required this.valorTotal});

  @override
  State<TelaDadosEntrega> createState() => _TelaDadosEntregaState();
}

class _TelaDadosEntregaState extends State<TelaDadosEntrega> {
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final ProdutoRepository _produtoRepository = ProdutoRepository();
  String _tipoEntrega = 'Entrega';
  String _metodoPagamento = 'Cartão';

  // Dados do usuário
  String _enderecoCompleto = "Rua xxxxxxxx, 99, Bairro";

  String _observacao = "";

  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _observacaoController = TextEditingController();

  double get _subtotal =>
      widget.valorTotal -
      5.0; // Desconta a taxa padrão para exibir separadamente
  double get _taxaEntrega => _tipoEntrega == 'Irei buscar' ? 0.0 : 5.0;
  double get _totalGeral => _subtotal + _taxaEntrega;

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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- RESUMO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subtotal",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "R\$${_subtotal.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Valor da entrega",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _taxaEntrega == 0
                      ? "Grátis"
                      : "R\$ ${_taxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "R\$ ${_totalGeral.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- CUPOM ---
            Row(
              children: [
                const Icon(Icons.discount_outlined, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Adicionar cupom de desconto",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 130,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Digite aqui o cupom",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- ENTREGA ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "ENTREGA",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildRadioOption(
              title: "Irei buscar",
              value: "Irei buscar",
              groupValue: _tipoEntrega,
              icon: Icons.directions_walk,
              onChanged: (val) => setState(() => _tipoEntrega = val.toString()),
            ),
            _buildRadioOption(
              title: "Entrega no endereço",
              value: "Entrega",
              groupValue: _tipoEntrega,
              icon: Icons.home_outlined,
              onChanged: (val) => setState(() => _tipoEntrega = val.toString()),
            ),
            if (_tipoEntrega == 'Entrega') ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 45, right: 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _enderecoController,
                      decoration: const InputDecoration(
                        labelText: "Rua / Avenida",
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _numeroController,
                            decoration: const InputDecoration(
                              labelText: "Número",
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _bairroController,
                            decoration: const InputDecoration(
                              labelText: "Bairro",
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // --- NUMERO PARA CONTATO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "NUMERO PARA CONTATO",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.phone_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_telefoneFormatter],
                    decoration: const InputDecoration(
                      hintText: "(xx) 9xxxx-xxxx",
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- OPÇÕES DE PAGAMENTO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "OPÇÕES DE PAGAMENTO",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildRadioOption(
              title: "Cartão",
              value: "Cartão",
              groupValue: _metodoPagamento,
              icon: Icons.credit_card,
              onChanged: (val) =>
                  setState(() => _metodoPagamento = val.toString()),
            ),
            _buildRadioOption(
              title: "PIX",
              value: "PIX",
              groupValue: _metodoPagamento,
              icon: Icons.pix,
              onChanged: (val) =>
                  setState(() => _metodoPagamento = val.toString()),
            ),
            _buildRadioOption(
              title: "Dinheiro",
              value: "Dinheiro",
              groupValue: _metodoPagamento,
              icon: Icons.attach_money,
              onChanged: (val) =>
                  setState(() => _metodoPagamento = val.toString()),
            ),
            const SizedBox(height: 30),

            // --- BOTOES FINAIS ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _editarObservacao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _observacao.isEmpty
                      ? "Adicionar observação"
                      : "Editar observação",
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finalizarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4A4A),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Finalizar Pedido",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String groupValue,
    required IconData icon,
    required Function(String?) onChanged,
    VoidCallback? onTextTap,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: groupValue,
            // ignore: deprecated_member_use
            onChanged: onChanged,
            activeColor: Colors.grey[800],
          ),
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: GestureDetector(
              onTap: onTextTap ?? () => onChanged(value),
              child: Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editarObservacao() {
    _observacaoController.text = _observacao;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Observação do Pedido"),
        content: TextField(
          controller: _observacaoController,
          decoration: const InputDecoration(
            hintText: "Ex: Tirar cebola, troco para 50...",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _observacao = _observacaoController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarPedido() async {
    if (_telefoneController.text.trim().length < 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor, insira um número de telefone válido com DDD.",
          ),
        ),
      );
      return;
    }

    if (_tipoEntrega == 'Entrega') {
      if (_enderecoController.text.trim().isEmpty ||
          _numeroController.text.trim().isEmpty ||
          _bairroController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Por favor, preencha todos os campos do endereço de entrega.",
            ),
          ),
        );
        return;
      }
      _enderecoCompleto =
          "${_enderecoController.text.trim()}, ${_numeroController.text.trim()}, ${_bairroController.text.trim()}";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final clienteId =
          FirebaseAuth.instance.currentUser?.uid ?? 'cliente_desconhecido';
      final itensCopia = <String, dynamic>{};
      final carrinhoService = CarrinhoService();
      carrinhoService.itens.forEach((key, value) {
        itensCopia[key] = Map<String, dynamic>.from(value);
      });

      // --- CENÁRIO A: Validação prévia de estoque ---
      // Bloqueia o pedido antes de qualquer gravação se o estoque for insuficiente.
      await _produtoRepository.validarEstoqueItens(itensCopia);

      final pedidoData = <String, dynamic>{
        'clienteId': clienteId,
        'lojistaId': carrinhoService.lojaId ?? 'desconhecido',
        'itens': itensCopia,
        'valorTotal': _totalGeral,
        'status': 'pendente',
        'dataCriacao': FieldValue.serverTimestamp(),
        'dadosCliente': <String, dynamic>{
          'nome': "Cliente",
          'telefone': _telefoneController.text.trim(),
        },
        'dadosEntrega': <String, dynamic>{
          'tipoEntrega': _tipoEntrega,
          'endereco': _tipoEntrega == 'Entrega' ? _enderecoCompleto : '',
        },
        'pagamento': <String, dynamic>{'metodo': _metodoPagamento},
        'observacao': _observacao,
      };

      // Salva no banco de dados
      await _pedidoRepository.criarPedido(pedidoData);

      // --- CENÁRIO B: Dedução atômica (validação + update dentro da Transaction) ---
      // Protege contra race condition: se dois clientes tentarem ao mesmo tempo,
      // o segundo terá a transação abortada com exceção ao detectar estoque 0.
      for (final entry in itensCopia.entries) {
        final produtoId = entry.key;
        final quantidade = (entry.value['quantidade'] as num).toInt();
        await _produtoRepository.reduzirEstoqueProduto(produtoId, quantidade);
      }

      await carrinhoService.limparCarrinho();

      if (mounted) Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Sucesso!"),
            content: const Text(
              "Seu pedido foi enviado com sucesso para o lojista.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "Não foi possível finalizar o pedido",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Entendido",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
