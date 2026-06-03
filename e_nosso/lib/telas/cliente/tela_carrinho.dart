import 'package:flutter/material.dart';
import 'tela_finalizacao_compra.dart';

class TelaRevisaoCarrinho extends StatefulWidget {
  final Map<String, Map<String, dynamic>> itens;
  final String lojaName;

  const TelaRevisaoCarrinho({
    super.key,
    required this.itens,
    required this.lojaName,
  });

  @override
  State<TelaRevisaoCarrinho> createState() => _TelaRevisaoCarrinhoState();
}

class _TelaRevisaoCarrinhoState extends State<TelaRevisaoCarrinho> {
  double get _total {
    double total = 0.0;
    widget.itens.forEach((key, value) {
      final preco = value['preco'] ?? 0.0;
      final qtd = value['quantidade'] ?? 0;
      total += (preco * qtd);
    });
    return total;
  }

  int get _totalItens {
    int total = 0;
    widget.itens.forEach((key, value) {
      total += (value['quantidade'] as int? ?? 0);
    });
    return total;
  }

  void _atualizarQuantidade(String id, int delta) {
    setState(() {
      if (widget.itens.containsKey(id)) {
        int atual = widget.itens[id]!['quantidade'] ?? 0;
        int novaQtd = atual + delta;
        if (novaQtd > 0) {
          widget.itens[id]!['quantidade'] = novaQtd;
        } else {
          widget.itens.remove(id); // Remove do carrinho se zerar
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Sacola",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {}, // Ação do menu se necessário
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
      body: widget.itens.isEmpty
          ? const Center(child: Text("Sua sacola está vazia"))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CABEÇALHO DA LOJA ---
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.lojaName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Adicionar mais itens",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // --- ITENS ADICIONADOS ---
                  const Text(
                    "Itens adicionados",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  // LISTA DE ITENS
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.itens.length,
                    itemBuilder: (context, index) {
                      final key = widget.itens.keys.elementAt(index);
                      final item = widget.itens[key]!;
                      return _cardItemCarrinho(item, key);
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: widget.itens.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _cardItemCarrinho(Map<String, dynamic> item, String id) {
    final double precoTotal = (item['preco'] ?? 0.0) * (item['quantidade'] ?? 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGEM PLACEHOLDER
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 15),
          // INFOS DO PRODUTO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nome'] ?? "Produto",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  "${item['quantidade']} unidades",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "R\$ ${precoTotal.toStringAsFixed(2).replaceAll('.', ',')}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // SELETOR DE QUANTIDADE
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove, size: 14, color: Colors.black54),
                  onPressed: () => _atualizarQuantidade(id, -1),
                ),
                Text(
                  "${item['quantidade']}",
                  style: const TextStyle(fontSize: 13),
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add, size: 14, color: Colors.black54),
                  onPressed: () => _atualizarQuantidade(id, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total com a entrega",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    text: "R\$${_total.toStringAsFixed(2).replaceAll('.', ',')} ",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "/ $_totalItens itens",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaDadosEntrega(valorTotal: _total + 5),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4A4A), // Cinza escuro como na imagem
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                "Continuar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
