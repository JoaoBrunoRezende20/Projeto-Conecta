import 'package:flutter/material.dart';
// Certifique-se de que o nome do arquivo abaixo é exatamente o nome do arquivo que contém a TelaDadosEntrega
import 'telaFinalizacaoCompra.dart';

class TelaRevisaoCarrinho extends StatelessWidget {
  final Map<String, Map<String, dynamic>> itens;
  final String lojaName;

  const TelaRevisaoCarrinho({
    super.key,
    required this.itens,
    required this.lojaName,
  });

  double get _total {
    double total = 0.0;
    itens.forEach((key, value) {
      // Adicionada verificação de segurança para evitar erro de null
      final preco = value['preco'] ?? 0.0;
      final qtd = value['quantidade'] ?? 0;
      total += (preco * qtd);
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(lojaName,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: itens.isEmpty
                ? const Center(child: Text("Seu carrinho está vazio"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens.values.elementAt(index);
                return _cardItemCarrinho(item);
              },
            ),
          ),
          _buildResumoValores(),
        ],
      ),
      bottomNavigationBar: _buildAcoesFinais(context),
    );
  }

  Widget _cardItemCarrinho(Map<String, dynamic> item) {
    final precoTotal = (item['preco'] ?? 0.0) * (item['quantidade'] ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Text("${item['quantidade']}x",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item['nome'] ?? "Produto",
                style: const TextStyle(fontSize: 16)),
          ),
          Text("R\$ ${precoTotal.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResumoValores() {
    double taxaEntrega = 5.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
      ),
      child: Column(
        children: [
          _linhaResumo("Subtotal", "R\$ ${_total.toStringAsFixed(2)}"),
          _linhaResumo("Taxa de Entrega", "R\$ ${taxaEntrega.toStringAsFixed(2)}"),
          const Divider(height: 24),
          _linhaResumo("Total", "R\$ ${(_total + taxaEntrega).toStringAsFixed(2)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _linhaResumo(String label, String valor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14
              )),
          Text(valor,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14,
                  color: isTotal ? Colors.black : Colors.black
              )),
        ],
      ),
    );
  }

  Widget _buildAcoesFinais(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("VOLTAR", style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: itens.isEmpty ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaDadosEntrega(valorTotal: _total + 5),
                    ),
                  );
                },
                child: const Text("PRÓXIMO PASSO",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}