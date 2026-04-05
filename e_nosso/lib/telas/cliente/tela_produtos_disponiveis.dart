import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// IMPORTANTE: Importando o seu arquivo externo de carrinho
import 'tela_carrinho.dart';

// --- TELA DE PRODUTOS DISPONÍVEIS ---
class TelaProdutosDisponiveis extends StatefulWidget {
  final String lojaId;
  final String storeName;
  final double rating;

  const TelaProdutosDisponiveis({
    super.key,
    required this.lojaId,
    required this.storeName,
    required this.rating,
  });

  @override
  State<TelaProdutosDisponiveis> createState() =>
      _TelaProdutosDisponiveisState();
}

class _TelaProdutosDisponiveisState extends State<TelaProdutosDisponiveis> {
  // Armazena ID do produto e os dados (quantidade, preço, nome)
  final Map<String, Map<String, dynamic>> _carrinho = {};

  double get _totalCarrinho {
    double total = 0.0;
    _carrinho.forEach((id, dados) {
      total += (dados['preco'] ?? 0) * dados['quantidade'];
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.storeName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _buildListaProdutos(),
      bottomNavigationBar: _carrinho.isNotEmpty ? _buildBarraCarrinho() : null,
    );
  }

  Widget _buildListaProdutos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('produtos')
          .where('lojistaId', isEqualTo: widget.lojaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Nenhum produto encontrado."));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: 100,
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final produto = doc.data() as Map<String, dynamic>;
            final produtoId = doc.id;
            return _produtoCard(produto, produtoId);
          },
        );
      },
    );
  }

  Widget _produtoCard(Map<String, dynamic> produto, String id) {
    final int estoqueDisponivel = produto["estoque"] ?? 0;
    final int quantidadeNoCarrinho = _carrinho[id]?['quantidade'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto["nome"] ?? "Produto",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  estoqueDisponivel > 0
                      ? "$estoqueDisponivel unidades disponíveis"
                      : "Esgotado",
                  style: TextStyle(
                    fontSize: 12,
                    color: estoqueDisponivel < 5
                        ? Colors.orange[900]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "R\$ ${(produto["preco"] ?? 0).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (quantidadeNoCarrinho > 0)
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.black,
                  ),
                  onPressed: () => setState(() {
                    if (quantidadeNoCarrinho > 1) {
                      _carrinho[id]!['quantidade']--;
                    } else {
                      _carrinho.remove(id);
                    }
                  }),
                ),
                Text(
                  "$quantidadeNoCarrinho",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: quantidadeNoCarrinho < estoqueDisponivel
                      ? () => setState(() => _carrinho[id]!['quantidade']++)
                      : null,
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: estoqueDisponivel > 0
                  ? () => setState(() {
                      _carrinho[id] = {
                        'nome': produto['nome'],
                        'preco': produto['preco'],
                        'quantidade': 1,
                      };
                    })
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: estoqueDisponivel > 0
                    ? Colors.red
                    : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Adicionar"),
            ),
        ],
      ),
    );
  }

  Widget _buildBarraCarrinho() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total estimado",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "R\$ ${_totalCarrinho.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Navegando para a TelaRevisaoCarrinho que está no outro arquivo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaRevisaoCarrinho(
                      itens: _carrinho,
                      lojaName: widget.storeName,
                    ),
                  ),
                );
              },
              child: const Text(
                "Ver Carrinho",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*
// --- TELA DE REVISÃO DO CARRINHO ---
class TelaRevisaoCarrinho extends StatelessWidget {
  final Map<String, Map<String, dynamic>> itens;
  final String lojaName;

  const TelaRevisaoCarrinho(
      {super.key, required this.itens, required this.lojaName});

  @override
  Widget build(BuildContext context) {
    double total = 0;
    itens.forEach(
            (key, value) => total += (value['preco'] * value['quantidade']));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Carrinho: $lojaName"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...itens.entries.map((e) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(e.value['nome'],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "${e.value['quantidade']}x R\$ ${e.value['preco'].toStringAsFixed(2)}"),
              trailing: Text(
                  "R\$ ${(e.value['quantidade'] * e.value['preco']).toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.black, // Alterado de vermelho para preto
                      fontWeight: FontWeight.bold)),
            ),
          )),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total do Pedido",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("R\$ ${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)), // Alterado de vermelho para preto
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Voltar para a Loja"),
          )
        ],
      ),
    );
  }
}
*/